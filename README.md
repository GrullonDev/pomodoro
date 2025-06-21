# Pomodoro

Aplicación Flutter para gestionar sesiones de trabajo y descanso utilizando la técnica Pomodoro.

## Tabla de Contenidos

- [Introducción](#introducción)
- [Características](#características)
- [Requisitos](#requisitos)
- [Instalación](#instalación)
- [Uso](#uso)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Contribuciones](#contribuciones)
- [Recursos útiles](#recursos-útiles)
- [Autor](#autor)

## Introducción

Este proyecto es un punto de partida para una aplicación Flutter que ayuda a los usuarios a gestionar su tiempo de trabajo y descanso utilizando la técnica Pomodoro. Es ideal para quienes desean mejorar su productividad y organización personal.

## Características

- Temporizador configurable para sesiones de trabajo y descanso
- Historial de sesiones completadas
- Personalización de tiempos de trabajo, descanso corto y descanso largo
- Interfaz intuitiva y fácil de usar

## Requisitos

- **Flutter:** 3.32.4 (gestionado con [FVM](https://fvm.app/))
- **Dart:** 3.x
- **Plataformas soportadas:** Android, iOS, Web

## Instalación

1. **Clona el repositorio:**

   ```bash
   git clone https://github.com/GrullonDev/pomodoro.git
   cd pomodoro
   ```

2. **Instala [FVM](https://fvm.app/docs/getting_started/installation) si no lo tienes:**

   ```bash
   dart pub global activate fvm
   ```

3. **Instala la versión de Flutter usada en el proyecto:**

   ```bash
   fvm install 3.32.4
   fvm use  3.32.4
   ```

4. **Instala las dependencias:**
   ```bash
   fvm flutter pub get
   ```

## Uso

Para ejecutar la aplicación en modo desarrollo:

```bash
fvm flutter run
```

Puedes seleccionar el dispositivo de destino (emulador o dispositivo físico) desde tu IDE o usando la terminal.

## Estructura del Proyecto

- `lib/` — Código fuente principal de la aplicación
- `assets/` — Recursos estáticos (imágenes, iconos, etc.)
- `test/` — Pruebas unitarias y de widgets

## Contribuciones

¡Las contribuciones son bienvenidas! Si deseas agregar nuevas funcionalidades o mejorar las existentes:

1. Haz un fork del repositorio.
2. Crea una rama para tu funcionalidad (`git checkout -b feature/nueva-funcionalidad`).
3. Realiza tus cambios y haz commit.
4. Envía un pull request describiendo tus cambios.

Por favor, sigue las buenas prácticas de desarrollo y asegúrate de que tu código pase las pruebas existentes.

## Recursos útiles

- [Lab: Escribe tu primera aplicación Flutter](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Ejemplos útiles de Flutter](https://docs.flutter.dev/cookbook)
- [Documentación oficial de Flutter](https://docs.flutter.dev/)
- [Guía de FVM](https://fvm.app/docs/getting_started/usage)

## Autor

Desarrollado por Jorge Grullón.

---

¿Tienes dudas o sugerencias? ¡No dudes en abrir un issue o contactarme!
