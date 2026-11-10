# ClubMartinGaser

Aplicación móvil para la gestión y reserva de espacios deportivos. El proyecto permite registrar usuarios, consultar sedes y canchas, revisar disponibilidad, realizar reservas de una o dos horas, cancelar turnos, consultar el historial y recibir recordatorios automáticos mediante Firebase Cloud Messaging.

## Tecnologías utilizadas

### Aplicación móvil

- Flutter y Dart
- Firebase Authentication
- Firebase Cloud Messaging
- Material Design 3
- Paquete `http` para comunicación con la API
- Google Fonts

### Backend

- Python
- FastAPI
- SQLAlchemy
- Pydantic
- Alembic
- Firebase Admin SDK
- Uvicorn

### Base de datos

- PostgreSQL

## Funcionalidades principales

- Registro de usuarios con correo electrónico y contraseña.
- Inicio y cierre de sesión con Firebase Authentication.
- Recuperación de contraseña.
- Sincronización automática entre Firebase y PostgreSQL.
- Consulta y edición del perfil autenticado.
- Tema claro y tema oscuro.
- Consulta de sedes deportivas activas.
- Consulta y filtrado de espacios deportivos.
- Consulta de disponibilidad por fecha.
- Reservas de una o dos horas consecutivas.
- Prevención de reservas superpuestas.
- Listado de próximas reservas.
- Cancelación de reservas futuras.
- Historial de reservas canceladas o finalizadas.
- Liberación automática del horario después de cancelar.
- Registro de dispositivos para notificaciones push.
- Recordatorios automáticos 24 horas y 1 hora antes de una reserva.
- Prevención de notificaciones duplicadas.
- Documentación interactiva mediante Swagger.

## Arquitectura general

```text
Flutter
  -> Firebase Authentication
  -> ID token
  -> FastAPI
  -> Firebase Admin SDK
  -> PostgreSQL
```

Las operaciones privadas envían el token del usuario mediante:

```http
Authorization: Bearer ID_TOKEN_DE_FIREBASE
```

FastAPI verifica el token con Firebase Admin SDK, obtiene el `firebase_uid` y recupera o crea el perfil correspondiente en PostgreSQL. El cliente no envía manualmente el identificador interno del usuario.

## Estructura del repositorio

```text
ClubMartinGaser/
|-- backend/
|   |-- alembic/
|   |-- app/
|   |   |-- api/
|   |   |-- core/
|   |   |-- dependencies/
|   |   |-- jobs/
|   |   |-- models/
|   |   |-- notifications/
|   |   |-- repositories/
|   |   |-- schemas/
|   |   `-- services/
|   |-- tests/
|   |-- .env.example
|   |-- alembic.ini
|   `-- requirements.txt
|-- mobile/
|   |-- android/
|   |-- lib/
|   |   |-- src/
|   |   |   |-- core/
|   |   |   `-- features/
|   |   `-- main.dart
|   |-- test/
|   `-- pubspec.yaml
|-- capturas-entrega/
`-- README.md
```

## Requisitos

- Python 3.11 o superior.
- Flutter SDK estable.
- Android Studio y Android SDK.
- PostgreSQL 17 o una versión compatible.
- Proyecto de Firebase con Authentication y Cloud Messaging habilitados.
- Emulador Android con Google APIs o Google Play Services.
- Git.

## Configuración del backend

### 1. Crear y activar el entorno virtual

Desde la carpeta `backend`:

#### Windows PowerShell

```powershell
python -m venv .venv
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\.venv\Scripts\Activate.ps1
```

### 2. Instalar dependencias

```powershell
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

### 3. Crear el archivo `.env`

Copiar `.env.example` como `.env` y completar los valores locales.

Ejemplo:

```env
APP_NAME=ClubMartinGaser
API_PREFIX=/api
DATABASE_URL=postgresql://USUARIO:CONTRASENA@127.0.0.1:5432/club_martin_gaser
FIREBASE_PROJECT_ID=ID_DEL_PROYECTO
FIREBASE_CREDENTIALS_PATH=firebase-service-account.json
```

No se debe subir `.env` ni la cuenta de servicio a GitHub.

### 4. Configurar Firebase Admin

Descargar la cuenta de servicio desde:

```text
Firebase Console
-> Configuración del proyecto
-> Cuentas de servicio
-> Firebase Admin SDK
-> Generar nueva clave privada
```

Guardar el archivo localmente como:

```text
backend/firebase-service-account.json
```

Este archivo está excluido mediante `.gitignore`.

### 5. Aplicar migraciones

```powershell
python -m alembic upgrade head
```

Comprobar la revisión:

```powershell
python -m alembic current
python -m alembic heads
```

### 6. Ejecutar FastAPI

```powershell
python -m uvicorn app.main:app --reload --host 0.0.0.0
```

Direcciones locales:

```text
API:     http://127.0.0.1:8000
Swagger: http://127.0.0.1:8000/docs
```

El parámetro `--host 0.0.0.0` permite que el emulador Android acceda al backend local.

## Configuración de Flutter

### 1. Entrar en la carpeta móvil

```powershell
cd mobile
```

### 2. Instalar dependencias

```powershell
flutter pub get
```

### 3. Configurar Firebase

La aplicación utiliza FlutterFire. El archivo generado debe existir en:

```text
mobile/lib/firebase_options.dart
```

La configuración Android local debe existir en:

```text
mobile/android/app/google-services.json
```

`google-services.json` está excluido de Git y debe obtenerse desde Firebase Console.

Si se necesita regenerar la configuración:

```powershell
firebase login
flutterfire configure
```

### 4. Dirección local de la API

Desde el emulador Android, la computadora anfitriona se alcanza mediante:

```text
http://10.0.2.2:8000
```

La configuración se encuentra en:

```text
mobile/lib/src/core/config/api_config.dart
```

### 5. Ejecutar la aplicación

```powershell
flutter devices
flutter run -d emulator-5554
```

Usar el identificador real informado por `flutter devices` si fuera diferente.

## Flujo principal

```text
Registro o inicio de sesión
-> Home
-> Sedes
-> Espacios deportivos
-> Fecha y duración
-> Disponibilidad
-> Confirmación de reserva
-> Mis reservas
-> Cancelación
-> Historial
-> Perfil
```

## Reglas de reservas

- La sede y el espacio deben estar activos.
- La fecha y el horario deben ser futuros.
- El intervalo debe estar dentro del horario de apertura de la sede.
- El final debe ser posterior al inicio.
- No se permiten superposiciones con reservas confirmadas.
- Flutter permite seleccionar una o dos horas.
- Para dos horas se exigen dos intervalos consecutivos disponibles.
- Una reserva cancelada permanece en PostgreSQL para conservar el historial.
- Al cancelar, el horario vuelve a aparecer como disponible.

La condición de superposición utilizada es:

```text
nuevo_inicio < reserva_existente_fin
Y
nuevo_fin > reserva_existente_inicio
```

## Endpoints principales

### Usuarios

```text
GET /api/users/me
PUT /api/users/me
```

### Sedes

```text
GET    /api/venues
POST   /api/venues
GET    /api/venues/{venue_id}
PATCH  /api/venues/{venue_id}
DELETE /api/venues/{venue_id}
```

### Espacios deportivos

```text
GET    /api/spaces
POST   /api/spaces
GET    /api/spaces/{space_id}
PATCH  /api/spaces/{space_id}
DELETE /api/spaces/{space_id}
GET    /api/spaces/{space_id}/availability
```

### Reservas autenticadas

```text
POST   /api/reservations
GET    /api/reservations/me
GET    /api/reservations/me/history
GET    /api/reservations/{reservation_id}
DELETE /api/reservations/{reservation_id}
```

### Notificaciones

```text
POST /api/device-tokens
```

Los endpoints privados utilizan el usuario obtenido desde el token Firebase. No requieren el parámetro manual `user_id`.

## Notificaciones y recordatorios

Flutter solicita permiso para notificaciones, registra la instalación de Firebase y envía el identificador del dispositivo al endpoint autenticado:

```text
POST /api/device-tokens
```

El job de recordatorios se ejecuta con:

```powershell
python -m app.jobs.send_reservation_reminders
```

La lógica:

1. Busca reservas `CONFIRMED` dentro de las próximas 24 horas.
2. Busca dispositivos activos del usuario.
3. Envía un recordatorio de 24 horas o de 1 hora mediante Firebase Admin SDK.
4. Guarda `reminder_24h_sent_at` o `reminder_1h_sent_at`.
5. Evita reenviar el mismo recordatorio en ejecuciones posteriores.

### Programación horaria

Expresión cron para producción:

```text
0 * * * *
```

En Windows se utiliza la tarea:

```text
ClubMartinGaser-Recordatorios
```

que ejecuta:

```text
backend/run_notification_job.cmd
```

La computadora debe permanecer encendida y con conexión a Internet para la tarea local. En producción, el mismo comando debe configurarse en un servicio de cron.

## Pruebas

### Backend

```powershell
cd backend
.\.venv\Scripts\Activate.ps1
python -m compileall app
python -m pytest
python -m alembic current
```

### Flutter

```powershell
cd mobile
dart format .\lib
flutter analyze
flutter test
```

### Compilar APK

```powershell
flutter clean
flutter pub get
flutter build apk --debug
```

Salida esperada:

```text
mobile/build/app/outputs/flutter-apk/app-debug.apk
```

## Evidencias de la entrega

Las capturas están organizadas en:

```text
capturas-entrega/
```

Incluyen:

- Login y registro.
- Home claro y oscuro.
- Sedes y espacios deportivos.
- Disponibilidad de una y dos horas.
- Reserva confirmada.
- Próximas reservas e historial.
- Perfil editable.
- Notificación recibida.
- Swagger.
- Firebase Authentication.
- PostgreSQL.
- Tarea programada.
- Historial de GitHub.

## Seguridad

Los siguientes archivos no se incluyen en Git ni en los ZIP públicos:

```text
backend/.env
backend/firebase-service-account.json
backend/notification_job.log
mobile/android/app/google-services.json
```

Tampoco deben compartirse:

- Contraseñas de PostgreSQL.
- Tokens Firebase Authentication.
- Tokens o identificadores completos de dispositivos.
- Claves privadas de Firebase Admin.

## Estado del proyecto

El proyecto incluye un flujo funcional completo de autenticación, perfil, consulta de sedes y espacios, disponibilidad, reservas de una o dos horas, cancelación, historial y recordatorios automáticos mediante Firebase Cloud Messaging.

## Autor

Martin Gabriel Gaser
