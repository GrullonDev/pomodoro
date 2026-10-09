# AGENTS.md

Instrucciones para agentes que trabajan en este repositorio. Consultar README y configuración para el detalle; este archivo no autoriza publicación ni cambios fuera de la tarea.

## Propósito del proyecto

Aplicación de concentración con ciclos de trabajo/descanso, tareas, historial, sonidos, logros y autenticación. Hay integración nativa de notificaciones, no molestar y reloj; no prometer bloqueo universal de otras aplicaciones ni una app de reloj independiente sin verificarlo.

## Stack y plataformas

flutter_bloc, GetIt, SharedPreferences, Firebase Auth/Firestore, audioplayers, local_auth, notificaciones y canales nativos Kotlin/Swift.

Requisito Dart declarado: `">=3.4.4 <4.0.0"` en `pubspec.yaml`; los rangos de dependencias no prueban la versión resuelta. SDK mediante FVM: `stable` según `.fvmrc` (canal móvil, no versión fija).

Proyectos de plataforma presentes: android, ios, linux, macos, web, windows. Esto no garantiza que todos los plugins funcionen en cada plataforma.

## Estructura del repositorio

`lib/core/timer/` contiene TimerBloc/eventos/estados; `lib/core/domain/` contratos/casos de uso; `lib/core/data/` persistencia. `lib/features/` organiza tareas, estadísticas, audio, gamificación e integraciones. DI en `lib/core/di/`; app en `lib/utils/app.dart`. `android/` e `ios/` contienen puentes nativos; `lib/l10n/` contiene ARB.

## Preparación y comandos

Requisitos: FVM y SDK de `.fvmrc`; ejecutar `fvm install` sin modificar el pin. Android necesita su toolchain/JDK de Gradle; iOS requiere macOS/Xcode y la gestión de dependencias del proyecto. Integraciones Firebase requieren configuración de desarrollo existente.

| Acción | Comando desde la raíz |
| --- | --- |
| Dependencias | `fvm flutter pub get` |
| Ejecutar | `fvm flutter run -d <dispositivo>` |
| Formato | `fvm dart format lib test` |
| Análisis | `fvm flutter analyze` |
| Pruebas | `fvm flutter test` |
| Build Android de comprobación | `fvm flutter build apk --debug` |

`fvm flutter gen-l10n` cuando cambien ARB.

Los comandos fueron contrastados con dependencias, documentación/configuración y suites presentes; no ejecutados al redactar este archivo. Build de distribución requiere firma/configuración adicional; no sustituye despliegue.

## Arquitectura y convenciones

Extender TimerBloc y TimerStorage en lugar de crear otro cronómetro; revisar también `lib/utils/timer.dart` antes de tocar el flujo. Mantener reglas de sesiones en dominio y persistencia en repositorios. GamificationService/MomentumService reciben progreso real. Reutilizar servicios de audio, notificaciones, Dnd y WearableService; no duplicar canales ni fuentes de estado.

Conservar nombres y convenciones del módulo: Dart snake_case para archivos, UpperCamelCase para tipos y lowerCamelCase para miembros. No renombrar APIs/campos persistidos incidentalmente; respetar lints de analysis_options.yaml.

## Experiencia de usuario

El cronómetro debe conservar fase, pausa y tiempo restante al volver de segundo plano. Evitar recompensas duplicadas o interacción que interrumpa el enfoque. Mostrar permisos denegados y ausencia de reloj con recuperación clara. Modificar ARB ES/EN y regenerar localización; verificar pantallas pequeñas, texto grande y acciones accesibles.

En el flujo afectado, contemplar carga, vacío, éxito y error; dar feedback claro, conservar entradas/datos ante fallos y permitir recuperación. Reutilizar componentes visuales; revisar semántica, foco, contraste y escalado de texto.

## Seguridad y datos

No incluir secretos, credenciales ni datos personales en código, documentación o logs. Usar configuración de entorno existente, validar entradas y manejar fallos de servicios. Respetar autenticación, autorización y permisos. No ejecutar operaciones destructivas sobre datos sin autorización explícita.

Calendario, biometría y DND requieren consentimiento/permisos; no presentarlos como garantías de bloqueo. Aislar sesiones por usuario y no registrar tareas privadas, tokens ni eventos del calendario. La app del teléfono debe seguir funcionando sin reloj emparejado.

## Pruebas y validación

Ejecutar las pruebas existentes de dominio, repositorio y `test/timer_50_cycles_test.dart` al cambiar sesiones. Verificar inicio, pausa/reanudar, fin de fase, cancelación, restauración y contabilización única. Cambios nativos requieren dispositivo: notificación, DND, retorno del background y reloj conectado/desconectado.

Ejecutar análisis y pruebas relevantes según el cambio; compilar solo plataformas afectadas. Un cambio exclusivamente documental requiere revisar rutas, comandos, alcance y diff, sin pruebas artificiales que repliquen el texto. No afirmar que una prueba pasó si no se ejecutó.

## Flujo de trabajo del agente

Leer instrucciones aplicables antes de modificar archivos, incluidas las de subdirectorios: su alcance local se respeta. Las instrucciones explícitas del usuario prevalecen.

1. Revisar estado del trabajo y comprender el flujo afectado antes de implementar.
2. Hacer cambios acotados al objetivo; respetar cambios existentes del usuario y evitar refactorizaciones ajenas.
3. Reutilizar componentes y dependencias disponibles; justificar dependencias nuevas.
4. Actualizar documentación si cambia comportamiento o configuración.
5. Ejecutar verificaciones pertinentes y comunicar resultados y pendientes con su motivo.
6. No hacer commits, push o despliegues salvo solicitud o autorización previa del usuario. Esta regla prevalece sobre recomendaciones de commit automático en guías antiguas.

No imponer una política nueva de ramas/commits; seguir documentación y CI existentes.

No activar workflows de publicación ni scripts de release como comprobación rutinaria.

## Criterios de finalización

La tarea cumple el comportamiento solicitado, contempla errores/estados relevantes, mantiene convenciones y pasa las verificaciones aplicables que puedan ejecutarse. Comunicar archivos modificados, resultados reales y cualquier validación pendiente con su motivo.

## Limitaciones y aspectos por confirmar

`.fvmrc` apunta al canal `stable`, mientras el README cita una versión fija. Existen scaffolds de escritorio/web, pero `dart:io` y las integraciones nativas requieren comprobar compatibilidad. WatchConnectivity/notificaciones extendidas no prueban un cliente completo para watchOS/Wear OS.
