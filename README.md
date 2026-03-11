# 🏆 TFG1 - Team Management with Clean Architecture

Una aplicación Flutter profesional que implementa **Clean Architecture**, **BLoC Pattern** y **Supabase** para gestión de equipos en tiempo real.

> **Proyecto académico (TFG)** | Flutter 3.11+ | Arquitectura Limpia | BLoC State Management

---

## 📊 Vista General

Esta aplicación demuestra patrones de desarrollo avanzados en Flutter:

| Aspecto | Descripción |
|--------|-------------|
| **Arquitectura** | Clean Architecture con separación clara de capas |
| **Estado** | BLoC + Hydrated BLoC para persistencia automática |
| **Base de Datos** | Supabase (PostgreSQL en tiempo real) |
| **Lenguaje** | Dart 3.11+ |
| **Plataformas** | iOS, Android, Web, Linux, macOS, Windows |

---

## 🏗️ Estructura del Proyecto

```
lib/
├── core/                          # Núcleo compartido
│   └── errors/                   # Definición de excepciones
│
├── data/                          # 📡 Capa de datos
│   ├── mappers/                   # DTO → Entidad
│   ├── models/                    # Modelos de datos (DTOs)
│   └── repositories/              # Implementación de repositorios
│       └── team_repository.dart   # Gestión de equipos
│
├── domain/                        # 💼 Lógica de negocio (sin Flutter)
│   ├── entities/                  # Objetos de dominio
│   │   └── team.dart
│   ├── i_repositories/            # Interfaces de repositorios
│   └── usecase/                   # Casos de uso
│
└── presentation/                  # 🎨 UI y gestión de estado
    └── [BLoC, Widgets, Screens]

```

---

## 🛠️ Stack Tecnológico

```yaml
Core:
  - flutter: 3.11+
  - dart: 3.11+

State Management:
  - flutter_bloc: 8.1.6
  - bloc: 8.1.4
  - hydrated_bloc: 9.1.5

Backend & Data:
  - supabase_flutter: 2.0.0
  - http: 1.1.0
  - path_provider: 2.1.5

Utilities:
  - dartz: 0.10.1 (Either/Result)
  - equatable: 2.0.5
  - intl: 0.18.0 (i18n)
  - shared_preferences: 2.5.4
  - flutter_dotenv: 6.0.0

Development:
  - build_runner: 2.11.1
  - flutter_lints: 6.0.0
```

---

## ⚙️ Instalación

### Requisitos Previos
- ✅ Flutter SDK >= 3.11.0
- ✅ Dart >= 3.11.0  
- ✅ Git
- ✅ Cuenta en [Supabase](https://supabase.com) (gratuita)

### Pasos de Instalación

1. **Clonar repositorio**
   ```bash
   git clone <repository-url>
   cd tfg1
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar Supabase**
   - Crear archivo `.env` en la raíz:
   ```env
   SUPABASE_URL=https://tu-proyecto.supabase.co
   SUPABASE_ANON_KEY=tu_clave_anonima_aqui
   ```

4. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

---

## 📱 Plataformas Soportadas

| Plataforma | Estado | Notas |
|-----------|--------|-------|
| iOS | ✅ | iOS 11+ |
| Android | ✅ | API 21+ |
| Web | ✅ | Chrome, Firefox, Safari |
| Linux | ✅ | GTK 3.0+ |
| macOS | ✅ | 10.14+ |
| Windows | ✅ | Windows 10+ |

---

## 🚀 Inicio Rápido

### Ejecutar en modo desarrollo
```bash
# Android
flutter run -d android

# iOS
flutter run -d ios

# Web
flutter run -d chrome
```

### Generar código
```bash
# Build único
flutter pub run build_runner build

# Watch mode (regenera al guardar)
flutter pub run build_runner watch
```

---

## 📚 Conceptos Clave

### Clean Architecture Levels

```
Presentation Layer
      ↓
Business Logic Layer (BLoC)
      ↓
Repository Pattern
      ↓
Data Layer (Supabase)
```

### BLoC Pattern Flow
```
Event → BLoC → State
```

### Manejo de Errores
Se utiliza `Dartz` Either/Result para manejo funcional de errores:
```dart
Future<Either<Failure, List<Team>>> getTeams();
```

---

## 🔐 Variables de Entorno

| Variable | Propósito | Origen |
|----------|-----------|--------|
| `SUPABASE_URL` | URL base de tu proyecto Supabase | Dashboard Supabase |
| `SUPABASE_ANON_KEY` | Clave anónima para cliente | Dashboard Supabase |

> ⚠️ **Seguridad**: Nunca confirmes `.env` en Git. Usa `.gitignore`.

---

## 📖 Recursos Educativos

- 📘 [Arquitectura Limpia en Flutter](https://resocoder.com/flutter-clean-architecture)
- 📗 [BLoC Library Docs](https://bloclibrary.dev)
- 📕 [Supabase Flutter Guide](https://supabase.com/docs/reference/dart/introduction)
- 📙 [Flutter Best Practices](https://docs.flutter.dev/testing/best-practices)

---

## 🐛 Debugging

### Ver logs en tiempo real
```bash
flutter logs
```

### Modo debug detallado
```bash
flutter run -v
```

### Limpiar caché
```bash
flutter clean
flutter pub get
```

---

## 📄 Licencia

🔒 Proyecto privado - No disponible para publicación pública

---

## 📞 Soporte

Para preguntas o issues sobre el proyecto, consulta la documentación oficial o abre un issue en el repositorio.

---

**Última actualización**: Marzo 2026 | **Estado del Proyecto**: En desarrollo
