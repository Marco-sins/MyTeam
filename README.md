# Football Manager

Aplicación móvil desarrollada con Flutter para la gestión integral de equipos deportivos. El proyecto está planteado como un Trabajo Fin de Grado y busca demostrar una solución técnicamente rigurosa, mantenible y preparada para escalar: autenticación, administración de equipos, plantilla, partidos, convocatorias, asistencia, invitaciones y sincronización con backend.

La intención académica no es únicamente entregar una aplicación funcional, sino justificar una arquitectura profesional con separación real de responsabilidades, acceso a datos controlado y una base técnica suficientemente sólida como para defenderla ante un tribunal exigente.

## Resumen ejecutivo

La aplicación cubre el ciclo de trabajo habitual de un equipo deportivo:

- autenticación de usuarios
- creación y administración de equipos
- alta, edición y consulta de jugadores
- convocatoria de partidos y generación de contenidos asociados
- control de asistencia
- gestión de invitaciones y permisos
- visualización y registro de eventos en partidos en tiempo real
- internacionalización completa de la interfaz

El backend se apoya en Supabase, mientras que la interfaz se construye con Flutter siguiendo una organización interna basada en Clean Architecture. La capa de presentación consume casos de uso y repositorios abstractos; la persistencia queda encapsulada en la capa de datos.

## Objetivos del proyecto

El diseño se ha planteado con estos criterios:

- separar la lógica de negocio de Flutter y del proveedor de backend
- facilitar el testeo y la evolución del sistema
- evitar acoplamientos directos entre UI y datos remotos
- permitir que el código sea comprensible para revisión académica y ampliación futura
- ofrecer una experiencia de uso clara, consistente y adaptable a varios idiomas

## Arquitectura

Se ha seguido una aproximación de Clean Architecture organizada por capas.

### Capas principales

| Capa | Responsabilidad |
|------|-----------------|
| `domain/` | Entidades, contratos de repositorio y casos de uso |
| `data/` | Datasources, modelos, mapeadores e implementaciones concretas |
| `presentation/` | Pantallas, widgets y gestión de estado con Cubit / BLoC |
| `core/` | DI, temas, errores, utilidades y configuración transversal |
| `app/` | Raíz visual y configuración global de la aplicación |

### Principios aplicados

- la UI no habla directamente con Supabase
- los repositorios definen contratos en dominio y se implementan en datos
- la inyección de dependencias se centraliza con `get_it`
- el estado de pantalla se gestiona con `flutter_bloc`
- los errores se modelan con abstracciones explícitas para evitar excepciones dispersas por la UI

### Flujo de una operación

1. El usuario interactúa con una pantalla o widget.
2. La vista delega la acción en un Cubit o BLoC.
3. El estado de presentación llama a un caso de uso.
4. El caso de uso trabaja con un contrato de repositorio.
5. La implementación concreta usa un datasource para acceder a Supabase.
6. El resultado vuelve encapsulado y la UI actualiza el estado.

## Stack técnico

| Área | Tecnología |
|------|------------|
| Framework | Flutter |
| Lenguaje | Dart `^3.11.0` |
| Estado | `flutter_bloc`, `bloc`, `equatable`, `hydrated_bloc` |
| Inyección de dependencias | `get_it` |
| Backend | `supabase_flutter` |
| Configuración local | `flutter_dotenv` |
| Resultados funcionales | `dartz` |
| Internacionalización | `flutter_localizations`, `intl`, ARB |
| Persistencia local | `shared_preferences` |
| Utilidades | `http`, `file_picker`, `url_launcher`, `share_plus`, `flutter_map`, `google_maps_flutter`, `geolocator`, `flutter_svg` |

## Estructura del repositorio

```text
lib/
├── main.dart
├── app/
├── core/
├── data/
├── domain/
├── l10n/
└── presentation/

test/
└── repositories/
```

Descripción resumida de los directorios más relevantes:

- `lib/main.dart`: arranque de la aplicación y configuración inicial
- `lib/app/`: composición de la app y navegación global
- `lib/core/`: dependencias, temas, utilidades y manejo transversal de errores
- `lib/domain/`: núcleo de negocio independiente de Flutter
- `lib/data/`: integración con Supabase y transformación de datos
- `lib/presentation/`: interfaz de usuario por módulos funcionales
- `lib/l10n/`: traducciones y textos de la aplicación
- `test/`: pruebas automatizadas de repositorios y capas concretas

## Requisitos

- Flutter SDK compatible con la versión indicada en `pubspec.yaml`
- Cuenta activa en Supabase
- Variables de entorno configuradas en un archivo `.env`

## Puesta en marcha

```bash
git clone <url-del-repositorio>
cd MyTeam
flutter pub get
```

Crear un archivo `.env` en la raíz con las credenciales del proyecto y, después:

```bash
flutter run
```

## Configuración de Supabase

El archivo `.env` debe incluir, como mínimo:

| Variable | Descripción |
|----------|-------------|
| `SUPABASE_URL` | URL pública del proyecto Supabase |
| `SUPABASE_ANON_KEY` | Clave anónima pública |

Buenas prácticas aplicadas:

- la clave anónima se usa únicamente en cliente
- la seguridad real debe recaer en políticas RLS de Supabase
- `main.dart` valida la configuración antes de inicializar el cliente

## Internacionalización

La interfaz está preparada para varios idiomas mediante archivos ARB en `lib/l10n/`.

Tras modificar textos o añadir nuevas claves:

```bash
flutter gen-l10n
```

Idiomas incluidos en la aplicación:

- español
- inglés
- francés
- italiano

## Pruebas

La estrategia de pruebas se ha orientado a verificar el comportamiento de la aplicación en puntos donde más valor aporta en una revisión académica: capa de datos y capa de presentación. El repositorio incluye pruebas reales en `test/repositories/team_repository_test.dart` y `test/presentation/auth/auth_cubit_test.dart`.

### Cobertura actual

- creación correcta de equipos a través del repositorio
- gestión de un caso negativo determinista en acceso a equipos sin sesión activa
- transiciones de estado del `AuthCubit` en login, registro y logout
- validación de resultados con `Either`, evitando excepciones como mecanismo normal de control

### Qué demuestra esta batería

- que la lógica de negocio puede validarse sin depender de la UI
- que la capa de presentación responde de forma predecible ante distintos resultados
- que la arquitectura permite aislar dependencias externas mediante dobles de prueba
- que el proyecto no se apoya solo en la demo visual, sino también en verificación automática

### Ejecución

```bash
flutter test
```

Si se quiere ejecutar un archivo concreto:

```bash
flutter test test/repositories/team_repository_test.dart
flutter test test/presentation/auth/auth_cubit_test.dart
```

Para análisis estático y revisión general:

```bash
flutter analyze
```

### Lectura académica del apartado

En una defensa de TFG, este bloque permite argumentar tres ideas clave:

- la solución tiene una base técnica verificable
- la separación entre capas no es decorativa, sino medible
- los casos de uso y los cubits pueden probarse de forma aislada

### Evolución recomendada

Para elevar aún más la calidad del apartado de pruebas, sería recomendable ampliar el conjunto con:

- tests unitarios de casos de uso
- tests de mapeadores entre modelos y entidades
- tests de widgets críticos de autenticación y navegación
- tests de integración sobre flujos completos de alta o consulta

## Comandos útiles

```bash
flutter analyze
flutter test
flutter clean
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
```

## Convenciones de desarrollo

- la nomenclatura de repositorios mantiene el prefijo `I` en los contratos de dominio
- la lógica de negocio se introduce primero en dominio y después en datos y presentación
- la UI se mantiene lo más delgada posible
- los mensajes de error y estados deben ser comprensibles para el usuario final
- la evolución de una funcionalidad debe respetar la dirección dominio → datos → presentación

## Licencia y contexto académico

Este proyecto tiene un uso académico y privado. No está publicado como paquete reutilizable en pub.dev, tal y como indica `publish_to: 'none'` en `pubspec.yaml`.

## Evidencia de calidad

Además de la estructura modular, el proyecto incluye:

- localización multidioma
- validaciones en formularios de autenticación
- integración con backend externo
- pruebas automáticas en capa de repositorios
- separación entre presentación, negocio y persistencia

## Posibles mejoras futuras

- ampliar la cobertura de pruebas unitarias e integración
- añadir métricas de rendimiento y trazabilidad de errores
- reforzar documentación técnica por módulo
- incluir una guía de despliegue completa para Supabase
- incorporar capturas de pantalla o demo visual para la defensa del TFG

---

Documento alineado con el estado actual del repositorio. Para los detalles exactos de dependencias y configuración, revisar `pubspec.yaml` y `l10n.yaml`.
