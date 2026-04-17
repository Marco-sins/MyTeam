# Football Manager — Gestión deportiva con Flutter

Aplicación **Flutter** para la administración de equipos, partidos, plantilla y asistencias, orientada a un **Trabajo Fin de Grado (TFG)**. El código sigue **Clean Architecture** con límites de capas explícitos, **casos de uso** en dominio, persistencia y API a través de **Supabase** (PostgreSQL), y estado de interfaz con **Cubit / BLoC**.

---

## Tabla de contenidos

1. [Objetivos y alcance](#objetivos-y-alcance)
2. [Arquitectura](#arquitectura)
3. [Estructura del repositorio](#estructura-del-repositorio)
4. [Stack técnico](#stack-técnico)
5. [Requisitos y puesta en marcha](#requisitos-y-puesta-en-marcha)
6. [Configuración de Supabase](#configuración-de-supabase)
7. [Internacionalización](#internacionalización)
8. [Comandos útiles](#comandos-útiles)
9. [Calidad y convenciones](#calidad-y-convenciones)
10. [Licencia y uso](#licencia-y-uso)

---

## Objetivos y alcance

El proyecto demuestra cómo organizar una base de código **mantenible y testeable** en Flutter:

- **Dominio independiente**: entidades y reglas de negocio sin dependencias de Flutter ni de Supabase.
- **Datos aislados**: fuentes remotas, modelos (DTO) y mapeo hacia entidades; implementación de contratos definidos en dominio.
- **Presentación delgada**: pantallas y Cubits/BLoCs que consumen **casos de uso** (y no detalles de infraestructura cuando la arquitectura está aplicada de forma estricta).
- **Inversión de dependencias**: el composition root (`main` + contenedor de inyección) ensambla implementaciones concretas.

A nivel funcional, la aplicación cubre flujos típicos de gestión de club o equipo: autenticación, equipos, jugadores, partidos (incluido tiempo real de eventos en escenarios de gestión), convocatorias, control de asistencia, invitaciones y perfiles, entre otros módulos presentes en `lib/presentation/`.

---

## Arquitectura

### Capas y dependencias permitidas

| Capa | Responsabilidad | Puede depender de |
|------|-----------------|-------------------|
| **Domain** | Entidades, contratos de repositorio (`I*Repository`), casos de uso (`UseCase`) | Solo Dart estándar y librerías neutrales (p. ej. `dartz` para `Either`) |
| **Data** | `Datasource`, `models`, `mappers`, implementaciones de repositorios | Domain, cliente Supabase, modelos JSON |
| **Presentation** | `pages`, `widgets`, `cubit` / `bloc` | Domain (casos de uso, entidades), Flutter, `flutter_bloc` |
| **Core** | Tema, errores transversales, utilidades, DI (`GetIt`), localización (`LocaleCubit`) | Según módulo; DI conoce Data y Domain para registrar implementaciones |
| **App** | `MaterialApp`, árbol de `Provider` / `RepositoryProvider`, orquestación global | Core, Presentation, Domain (resolución vía `sl<T>()`) |

**Regla central**: la **presentación no debe importar** la carpeta `data/` (ni `Supabase.instance` en pantallas o Cubits cuando el diseño está completo). Los casos de uso exponen operaciones de aplicación; los repositorios abstraen el origen de datos.

### Flujo de una operación típica

1. La UI dispara un método en un **Cubit** o envía un evento a un **BLoC**.
2. El Cubit llama a un **caso de uso** registrado en **GetIt** (`lib/core/di/injection_container.dart`).
3. El caso de uso usa la **interfaz** del repositorio definida en `domain/repositories/`.
4. La **implementación** en `data/repositories/` delega en un **datasource** que habla con Supabase.
5. Los errores se modelan como **`Failure`** (u otra abstracción acordada) y a menudo se devuelven como **`Either<Failure, T>`** (`dartz`).

### Inyección de dependencias

- **`GetIt`** (`sl`) concentra el registro de repositorios y casos de uso.
- Tras `Supabase.initialize`, se invoca **`configureDependencies()`** (idempotente si ya está registrado).
- **`FootballApp`** expone los casos de uso necesarios en el árbol mediante **`RepositoryProvider`**, de modo que la UI pueda hacer `context.read<MiUseCase>()`.

---

## Estructura del repositorio

Vista simplificada de `lib/`:

```
lib/
├── main.dart                    # dotenv → Supabase → configureDependencies() → runApp
├── app/
│   └── football_app.dart        # MaterialApp, LocaleCubit, providers globales
├── core/
│   ├── di/
│   │   └── injection_container.dart
│   ├── errors/                  # Excepciones (data) y Failure (dominio / manejo de error)
│   ├── locale/
│   ├── theme/
│   └── utils/
├── domain/
│   ├── entities/
│   ├── repositories/          # Contratos I*Repository
│   └── usecase/               # Casos de uso por contexto (auth, match, team, …)
├── data/
│   ├── datasource/             # Acceso a Supabase / HTTP
│   ├── models/                 # DTO / modelos de serialización
│   ├── mappers/                # Model ↔ Entity
│   └── repositories/           # Implementaciones de los contratos de dominio
├── presentation/
│   ├── auth/
│   ├── home/
│   ├── team/
│   ├── match/
│   ├── attendance/
│   ├── convocation/
│   ├── invitations/
│   └── …
└── l10n/                       # ARB + generación (flutter gen-l10n)
```

Los **assets** y la plantilla de entorno se declaran en `pubspec.yaml` (incluido `.env` como asset para `flutter_dotenv`).

---

## Stack técnico

Definición principal en `pubspec.yaml` (resumen):

| Área | Paquetes / notas |
|------|------------------|
| **SDK** | Flutter con Dart `^3.11.0` |
| **Estado** | `flutter_bloc`, `bloc`, `equatable` (`hydrated_bloc` está declarado; puedes usarlo para persistencia de estado si lo integras) |
| **DI** | `get_it` |
| **Backend** | `supabase_flutter`, `http` |
| **Configuración** | `flutter_dotenv` |
| **Resultados** | `dartz` (`Either`) |
| **i18n** | `flutter_localizations`, `intl`, ARB + `flutter: generate: true` |
| **Persistencia local** | `shared_preferences` (p. ej. idioma) |
| **Utilidades UI / sistema** | `file_picker`, `url_launcher`, `share_plus`, mapas (`flutter_map`, `google_maps_flutter`), `geolocator`, etc. |

Para versiones exactas, consulta siempre el fichero `pubspec.yaml`.

---

## Requisitos y puesta en marcha

### Prerrequisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) compatible con el `environment.sdk` del proyecto.
- Cuenta y proyecto en [Supabase](https://supabase.com) con el esquema de tablas acorde a los `datasource` del repositorio (no se documenta aquí el SQL completo; forma parte del despliegue del TFG).

### Pasos

```bash
git clone <url-del-repositorio>
cd .tfg
flutter pub get
```

Crea un fichero **`.env`** en la raíz del proyecto (ver siguiente sección) y ejecuta:

```bash
flutter run
```

Si la configuración de Supabase no es válida, la aplicación muestra una pantalla mínima de error de configuración (`SupabaseConfigErrorApp`) en lugar de inicializar el cliente.

---

## Configuración de Supabase

Variables esperadas en **`.env`** (no subir a control de versiones; debe ignorarse en `.gitignore`):

| Variable | Descripción |
|----------|-------------|
| `SUPABASE_URL` | URL del proyecto (p. ej. `https://xxxx.supabase.co`) |
| `SUPABASE_ANON_KEY` | Clave anónima pública del proyecto |

El arranque en `main.dart` comprueba que los valores no estén vacíos ni contengan marcadores de plantilla antes de llamar a `Supabase.initialize`.

**Seguridad**: la clave `anon` está pensada para el cliente; la lógica sensible debe apoyarse en **Row Level Security (RLS)** y políticas en Supabase, no en secretos embebidos en la app.

---

## Internacionalización

- Ficheros **ARB** bajo `lib/l10n/` (plantilla y traducciones).
- Configuración en **`l10n.yaml`** (incluye `template-arb-file`).
- Tras modificar los ARB:

```bash
flutter gen-l10n
```

El selector de idioma y `LocaleCubit` persisten la elección del usuario (p. ej. con `SharedPreferences`).

---

## Comandos útiles

```bash
# Análisis estático
flutter analyze

# Tests
flutter test

# Limpieza y dependencias
flutter clean && flutter pub get

# Generación de código (si añades paquetes que la requieran)
dart run build_runner build --delete-conflicting-outputs
```

Ejecución por dispositivo:

```bash
flutter devices
flutter run -d <device_id>
```

---

## Calidad y convenciones

- **Análisis**: reglas en `analysis_options.yaml` / `flutter_lints`.
- **Nombres**: contratos de repositorio con prefijo `I` en `domain/repositories/` (convención actual del repo).
- **Errores**: preferir `Either<Failure, T>` en frontera dominio↔aplicación cuando ya está establecido en el módulo.
- **Evolución**: al añadir una feature, el orden recomendado es **contrato en dominio → datasource + repositorio → caso de uso → registro en GetIt → UI**.

---

## Licencia y uso

Proyecto **privado** / académico: no está publicado como paquete reutilizable en pub.dev (`publish_to: 'none'` en `pubspec.yaml`). Conserva la licencia y las condiciones de uso que acuerde el autor del TFG con su centro educativo.

---

*Documentación alineada con el estado del repositorio (abril de 2026). Para el nombre del paquete Dart y metadatos de publicación, ver `pubspec.yaml`.*
