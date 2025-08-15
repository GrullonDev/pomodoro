# Pomodoro ⏱️

Aplicación Flutter enfocada en ayudar a personas y equipos a trabajar en ciclos de alta concentración con descansos estratégicos usando la técnica **Pomodoro**.

> "El foco profundo sostenido, medido y retroalimentado, convierte el tiempo en progreso tangible."  

---

## 📌 Tabla de Contenidos

1. [Visión & Propósito](#visión--propósito)
2. [Público Objetivo](#público-objetivo)
3. [Características](#características)
4. [Roadmap / Próximas Mejores](#roadmap--próximas-mejoras)
5. [Stack Tecnológico](#stack-tecnológico)
6. [Requisitos](#requisitos)
7. [Instalación Rápida](#instalación-rápida)
8. [Ejecución y Desarrollo](#ejecución-y-desarrollo)
9. [Estructura del Proyecto](#estructura-del-proyecto)
10. [Arquitectura & Decisiones Técnicas](#arquitectura--decisiones-técnicas)
11. [Flujo de Uso de la App](#flujo-de-uso-de-la-app)
12. [Personalización y Opciones](#personalización-y-opciones)
13. [Pruebas](#pruebas)
14. [Convenciones de Código](#convenciones-de-código)
15. [Cómo Contribuir](#cómo-contribuir)
16. [Gestión de Issues](#gestión-de-issues)
17. [Licencia](#licencia)
18. [Recursos Útiles](#recursos-útiles)
19. [Autor](#autor)

---

## Visión & Propósito
Crear una app de productividad enfocada, agradable y extensible que no sólo mida tiempo, sino que **refuerce hábitos sostenibles de enfoque** con: métricas, retroalimentación, notificaciones útiles y experiencias de sonido (tick + alertas discretas) sin distracciones.

## Público Objetivo
- Estudiantes que necesitan bloques de estudio estructurados.
- Desarrolladores y creadores que buscan reducir multitarea y contexto perdido.
- Freelancers que quieren métricas claras de tiempo productivo.
- Personas con TDAH que se benefician de ciclos guiados y señales auditivas ligeras.

## Características
| Estado | Funcionalidad | Descripción |
|--------|---------------|-------------|
| ✅ | Temporizador Pomodoro | Fases trabajo / descanso, con progreso visual animado. |
| ✅ | Sonido "tick" continuo | Reproducción opcional durante la fase de trabajo (loop suave). |
| ✅ | Alerta últimos 5s | Vibración + flash + sonido corto (configurable). |
| ✅ | Notificación persistente | Muestra fase y tiempo restante incluso en background. |
| ✅ | Historial local | Registro de sesiones completadas y progreso diario. |
| ✅ | Configuración básica | Duraciones, objetivo diario, intervalo de descansos largos. |
| ✅ | Onboarding inicial | Explica el método al primer ingreso. |
| 🔄 | Localización | EN / ES (strings migrándose a ARB; base operativa). |
| 🧪 | Testing | Pruebas iniciales de widgets (expandir). |
| 🗄️ | Firebase (deshabilitado en UI) | Base preparada para reintroducir autenticación y sync. |
| ✅ | Gestión de Tareas | Lista de tareas con sesiones asociadas y avance automático. |
| ✅ | Theming dinámico | Tema oscuro + cambio futuro de color primario (persistente). |
| ✅ | Arquitectura escalable | Capas Domain / Data / Presentation + Use Cases. |
| 🧩 | Extensible | Repos + Use Cases + Service Locator para futuras integraciones. |

## Roadmap / Próximas Mejoras
- [ ] Pantalla de estadísticas semanales avanzadas (gráficas).
- [ ] Modo enfoque con bloqueo opcional de distracciones (Android).
- [ ] Tema claro + ajustes de accesibilidad (alto contraste / tamaño fuente).
- [ ] Migración completa de strings a ARB + guía de traducción comunitaria.
- [ ] Ajuste de volumen independiente (tick vs alertas).
- [ ] Múltiples perfiles de configuración (estudio, deep work, repaso).
- [ ] Sincronización opcional en la nube (re-habilitar auth). 
- [ ] Exportar historial (CSV / Share).
- [ ] Widget / Complication (Android / iOS futuro).
- [ ] Animaciones de celebración al completar meta diaria.
- [ ] Coordinador / Use Case para flujo secuencial de tareas (actual TaskFlowStarter).
- [ ] Tests adicionales: TimerBloc, SettingsRepository, SessionRepository.
- [ ] Refactor final de settings menores restantes hacia SettingsRepository.

¿Quieres ayudar? Revisa [Cómo Contribuir](#cómo-contribuir).

## Stack Tecnológico
- **Flutter** (3.32.4) + **Dart 3.x**
- **State Management:** `flutter_bloc`
- **Persistencia local:** `shared_preferences`
- **Audio:** `audioplayers`
- **Notificaciones:** `flutter_local_notifications`
- **Internacionalización:** `flutter_localizations` + ARB (proceso de migración en curso)
- **Firebase (core/auth/firestore):** Preparado pero autenticación temporalmente desactivada
- **Diseño:** Material 3, tema oscuro personalizado
- **Arquitectura:** Clean Architecture ligera (Domain / Data / Presentation) con Use Cases
- **DI:** Service Locator simple (propio) — migrable a `get_it` si escala

## Requisitos
- Flutter 3.32.4 (recomendado usar [FVM](https://fvm.app/))
- Dart 3.x
- Android Studio / Xcode para compilación nativa
- Dispositivo o emulador Android / iOS

## Instalación Rápida
```bash
git clone https://github.com/GrullonDev/pomodoro.git
cd pomodoro
dart pub global activate fvm # si no tienes FVM
fvm install 3.32.4
fvm use 3.32.4
fvm flutter pub get
```

Ejecutar:
```bash
fvm flutter run
```

## Ejecución y Desarrollo
Usa `fvm flutter run -d <dispositivo>` para forzar versión consistente.

Reconstruir íconos (si cambias assets launcher):
```bash
fvm flutter pub run flutter_launcher_icons
```

Generar localizaciones (cuando se migre totalmente a ARB):
```bash
fvm flutter gen-l10n
```

## Estructura del Proyecto
```
lib/
   core/
      data/              # Repositorios (SessionRepository, etc.)
      timer/             # Bloc, estados, lógica de temporizador
         data/              # Implementaciones concretas (SessionRepository, TaskRepository, SettingsRepository)
         domain/
            entities/       # Entidades puras (TaskItem, PomodoroSession)
            repositories/   # Interfaces (ISessionRepository, ITaskRepository, ISettingsRepository)
            usecases/       # Casos de uso (AddTask, IncrementTaskSession, etc.)
      auth/              # Onboarding (auth temporalmente inactiva)
      summary/           # Pantalla resumen sesiones
         theme/             # Controladores de tema / locale
   l10n/                # Localización y extensiones temporales
   utils/               # App root, theming, home, notificaciones
assets/
         tasks/             # UI de gestión de tareas
   sounds/              # last5.mp3, cronometro.mp3
```
> Carpetas desktop/web fueron excluidas del versionado porque el foco es móvil.

## Arquitectura & Decisiones Técnicas
| Capa | Rol |
|------|-----|
| UI Widgets | Presentación reactiva (stateless mientras sea posible). |
| Bloc | Orquestación de estados de temporizador y transiciones de fase. |
| Repository | Persistencia + abstracción de fuente de datos (local / nube futura). |
| Services | Notificaciones, audio (audioplayers), etc. |
| Capa | Rol |
|------|-----|
| Presentation (UI + Bloc) | Widgets y TimerBloc coordinando fases y progreso. |
| Domain (Entities + Use Cases + Interfaces) | Reglas de negocio puras y orquestación de acciones. |
| Data (Repos concretos) | Implementaciones con SharedPreferences (persistencia local). |
| Services | Notificaciones, audio, DND, etc. |
| DI (Service Locator) | Provee instancias de repos para desacoplar creaciones. |

Principios:
- Separación de responsabilidades.
- Persistencia simple (SharedPreferences) para velocidad + baja fricción.
- Interfaz primero: dependencias contra abstracciones (DIP básico).
- Use Cases como frontera de negocio reutilizable.
- Soporte futuro para sincronización sin bloquear UX si Firebase falla (try/catch ya aplicado).
- Refactor incremental: mantener funcionalidad mientras se introducen capas.

### Refactor Reciente (Clean Architecture)
Implementado:
- Extracción de entidades (`TaskItem`, `PomodoroSession`).
- Interfaces de repos: `ISessionRepository`, `ITaskRepository`, `ISettingsRepository`.
- Casos de uso iniciales: `AddTaskUseCase`, `IncrementTaskSessionUseCase`, `NextPendingTaskUseCase` (en progreso), utilidades de sesión.
- `SettingsRepository` separado de `SessionRepository` (tema/preset/colores).
- Service Locator para evitar instanciación directa en UI.
- Pruebas unitarias iniciales sobre casos de uso de tareas.

Pendiente / Próximo:
- Coordinator / Use Case para flujo completo de tareas (reemplazar `TaskFlowStarter`).
- Tests para TimerBloc y repos restantes.
- Migrar configuración residual (alertas, vibración) a SettingsRepository.

## Flujo de Uso de la App
1. Usuario abre la app → Onboarding (solo la primera vez).
2. Define (o acepta) tiempos por defecto y empieza un ciclo.
3. Durante la fase de trabajo: tick opcional + progreso visual + notificación.
4. Últimos 5s: alerta sonora corta + vibración + flash (si habilitado).
5. Cambia a descanso, repite hasta completar sesiones configuradas.
6. Se registra la sesión y se actualiza progreso diario.
7. (Opcional) Flujo secuencial de tareas: al terminar una, se propone continuar con la siguiente pendiente.

## Personalización y Opciones
Configuraciones actuales (divididas en `SessionRepository` y `SettingsRepository`):
- Objetivo diario (minutos).
- Intervalo para descanso largo.
- Duración de descanso largo.
- Notificación persistente on/off.
- Alertas últimos 5 segundos (flash / sonido / vibración).
- Sonido de tick (fase trabajo) on/off.
- Selección de preset de trabajo (perfiles base).
- Tema oscuro persistente.

Próximas: volumen, perfiles, modo enfoque.

## Pruebas
Ejecutar tests:
```bash
fvm flutter test
```
Actualmente:
- Pruebas de use cases de tareas (`domain_usecases_test.dart`).
En progreso / plan:
- Tests para `TimerBloc` (ciclos de fase, restauración estado).
- Tests para `SettingsRepository` y `SessionRepository` (persistencia y migraciones).

## Convenciones de Código
- Formato: `dart format .`
- Linter: reglas en `analysis_options.yaml` (basado en `flutter_lints`).
- Nombrado: inglés para código, español/inglés para textos de UI (migrando a ARB).
- Commits (recomendado): `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, `test:`.

## Cómo Contribuir
1. Crea un issue o comenta en uno existente si vas a tomarlo.
2. Crea rama: `git checkout -b feat/<breve-descripcion>`.
3. Asegura formato + lint + tests pasan.
4. Abre PR hacia `develop` describiendo cambios, capturas si aplica.
5. Mantén PRs pequeños y enfocados.

### Pull Request hacia `main`
`main` solo recibe merges desde `develop` tras completar:
- Refactor o feature estable y testeado.
- Lint sin warnings críticos.
- README / docs actualizados.
- Revisión mínima (self-review checklist en la descripción del PR).

Checklist sugerido para PR:
- [ ] Cambios compilando (Android / iOS).
- [ ] `flutter analyze` sin issues nuevos.
- [ ] Tests agregados / existentes pasando.
- [ ] Actualizado README / CHANGELOG si aplica.
- [ ] Sin credenciales ni datos sensibles.

### Sugerencias de buen primer aporte
- Migrar más strings a ARB.
- Añadir pruebas para `TimerBloc`.
- Agregar pantalla de ajustes para toggles (tick / últimos 5s).
- Mejorar accesibilidad (semántica, contraste, tamaños).

## Gestión de Issues
- `enhancement` nuevas ideas.
- `bug` comportamiento incorrecto reproducible.
- `good first issue` tareas sencillas o acotadas.
- Añade pasos de reproducción o mocks si aplica.

## Licencia
Pendiente de definir (sugerido: MIT o Apache 2.0).  
Hasta que se establezca, se asume uso abierto sólo para colaboración; no distribución comercial sin autorización.

## Recursos Útiles
- [Flutter Docs](https://docs.flutter.dev/)
- [Bloc Package](https://bloclibrary.dev/#/)
- [audioplayers](https://pub.dev/packages/audioplayers)
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- [FVM](https://fvm.app/docs/getting_started/usage)

## Autor
Desarrollado por **Jorge Grullón**.  
¿Ideas o sugerencias? Abre un issue o crea un PR.

---
Si este proyecto te resulta útil, considera darle una ⭐ en GitHub para aumentar su visibilidad y atraer más colaboradores.

---
