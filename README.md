# alertacan
Para poder correr la apk para q hagan testeos con su celular, necesitan descargar las dependencias q vienen en el android studio, las dependencias son:
  -  Android Emulator — 36.4.9
  - Android Emulator hypervisor driver (installer) — 2.2.0
  - Android SDK Platform-Tools — 36.0.2
  - Android SDK Command-line Tools (latest) — Installed
  - Android SDK Build-Tools — Installed (Update Available: 37.0.0 rc2)
  - NDK (Side by side) — Installed (Update Available: 29.0.14206865)
  - CMake — Installed (Update Available: 4.1.2)

Para poder instalar y ejecutar la app desde Flutter en un dispositivo físico, es necesario activar el modo desarrollador y la depuración USB.

  - Ir a Configuración.
  - Entrar en Acerca del teléfono.
  - Buscar Número de compilación.
  - Presionarlo 7 veces hasta que aparezca el mensaje de que el modo desarrollador está activado.
  - Regresar a Configuración.
  - Entrar en Opciones de desarrollador.
  - Activar Depuración USB.
  - Conectar el dispositivo
  - Conectar el celular a la computadora con cable USB.
  - Aceptar el mensaje que aparece en el celular para permitir la depuración.
  - Verificar que el dispositivo sea detectado:
    flutter devices
  - Si aparece en la lista, pueden ejecutar:
    flutter run

Comandos de flutter
  - Optener dependencias (este sirve cuando sea la primera vez q lo clonen, ejecutenlo para q se modificquien las dependencias)
    flutter pub get
  - Verificar que todo esté bien configurado
    flutter doctor
  - Ejecutar la app
    flutter run
  - Limpiar proyecto si algo falla
    flutter clean
    flutter pub get
  - Para generar la apk oficial
    flutter build apk --release
