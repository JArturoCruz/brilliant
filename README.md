# Brilliant

Brilliant is a Flutter game that requires an authenticated account before
opening game content. Account credentials and session tokens are handled by
the independent Brilliant Auth Server.

## Conectar y jugar

Inicia el servidor en el equipo que alojará las cuentas y las partidas:

```powershell
cd C:\serverbrilliant\serverBrilliant
npm.cmd run build
npm.cmd start
```

En otro terminal ejecuta el cliente:

```powershell
cd C:\brilliant\brilliant
flutter run -d chrome
```

En la pantalla inicial escribe la IP o URL del servidor y pulsa **Conectar**.
Después crea una cuenta o inicia sesión para acceder al juego y al
multijugador. Se verifica el servidor antes de habilitar la cuenta. La
dirección se recuerda y cambiar de servidor cierra la sesión local.
El registro solo solicita un nombre de usuario único y una contraseña
numérica de al menos seis dígitos. Las cuentas anteriores conservan su
contraseña y pueden iniciar sesión con su nombre de usuario.

- En el equipo servidor, usa `localhost:3000`.
- En otro equipo o teléfono de la misma red, usa la IPv4 del servidor y el
  puerto, por ejemplo `192.168.1.10:3000`. Consulta la IPv4 con `ipconfig` en
  el equipo servidor.
- En el emulador Android Studio, usa `10.0.2.2:3000` para alcanzar el equipo
  anfitrión; `localhost` dentro del emulador no es el equipo anfitrión.
- Desde otra red, usa la dirección pública o dominio accesible del servidor;
  una IP privada como `192.168.x.x` no es enrutable por Internet. Deben
  configurarse la red, el firewall y, cuando corresponda, el router o VPN.
  Para Internet utiliza HTTPS con certificado válido, preferiblemente mediante
  un dominio y un proxy inverso. No expongas el servidor HTTP de desarrollo.

Al introducir solo un nombre o IP, se usa el puerto 3000 y HTTP en modo de
desarrollo; en producción se usa HTTPS. Para otro puerto o HTTPS en desarrollo,
escribe la URL completa, por ejemplo `https://juego.ejemplo.com`.
El certificado debe ser válido para el nombre o IP utilizado y confiable en
cada dispositivo. El servidor escucha en todas las interfaces, pero el código
no puede configurar automáticamente el firewall, NAT, DNS ni los certificados.
Consulta la configuración y las restricciones del navegador en el README del
servidor.

To build a debug APK for a physical Android phone on the same private Wi-Fi:

```powershell
flutter build apk --debug --split-per-abi
```

For most phones, install `build\app\outputs\flutter-apk\app-arm64-v8a-debug.apk`.
Use `app-armeabi-v7a-debug.apk` only for older 32-bit phones. On the start
screen, choose a detected server or enter its IP and port and press
**Conectar**. The address is remembered; if the server IP changes, search again
or enter the new address. Switching addresses clears the local session, so sign
in again. Select only servers you trust: discovery and the health check do not
authenticate the server.

Automatic discovery uses UDP broadcast on port 38971 and works only on the
same local network when broadcasts are allowed. Allow inbound UDP 38971 on the
server's private firewall profile in addition to TCP 3000. Guest networks,
VPNs and client isolation may prevent discovery. Web browsers cannot perform
UDP discovery; enter the address manually. On iOS, allow access to the local
network when prompted. Discovery advertises HTTP addresses; release builds
require an HTTPS address entered manually.

The server must be running and listening on the network. Configure its `.env`
as described in the server README, then restart it. Connect the phone to the
same Wi-Fi. On Windows, set that network's profile to
**Private**, then run this in PowerShell as Administrator to allow only local
subnet devices to connect:

```powershell
New-NetFirewallRule -DisplayName "Brilliant Auth Server LAN (Private)" -Direction Inbound -Protocol TCP -LocalPort 3000 -RemoteAddress LocalSubnet -Action Allow -Profile Private
New-NetFirewallRule -DisplayName "Brilliant Discovery LAN (Private)" -Direction Inbound -Protocol UDP -LocalPort 38971 -RemoteAddress LocalSubnet -Action Allow -Profile Private
```

Do not expose the development HTTP server on a Public network or the Internet.

For a release APK, use the server's deployed HTTPS URL (either enter it at
startup or specify a default at build time):

```powershell
flutter build apk --release --dart-define=BRILLIANT_API_URL=https://your-auth-domain.example
```

Release builds reject HTTP, including the HTTP addresses announced by local
discovery. Use a valid HTTPS hostname and certificate in production. This project currently uses the Android debug
signing key for release builds, which is suitable only for local sideload
testing, not for publishing or secure long-term updates.

For web, add the exact origin of the page, including its port, to
`CLIENT_ORIGINS` on the server. An HTTPS page cannot call an HTTP server
(mixed-content restriction). Web secure storage also requires a secure context:
HTTPS or localhost, not a plain HTTP page served from a LAN IP. Browser local
network permission and security restrictions can also affect access.

## Multiplayer

Sign in and choose **Multijugador** from the start screen. Create a room or
enter an invitation code; the host starts when 2–6 players are connected. The
host selects the board map. Room state, dice, legal moves, scores, and the win
condition are validated by the authenticated server. Players can leave at any
time. If the host leaves before or during initial setup, the room closes and
everyone returns to the lobby. Once play begins, a leaving or disconnected
player is removed while the game continues; their score and already-claimed
region rewards are preserved.

The client polls every two seconds and automatically retries after a network
interruption. Multiplayer rooms currently live in server memory: restarting
the server closes active rooms, and multiplayer requires a single server
instance.

Each player configures and plays on a separate board using the original game
interface and map rules. Everyone plays each round with the same pair of dice
at the same time; the next pair is rolled only after all players complete or
skip that round. The server validates every move and shares the current boards
with the authenticated members of the room; players can inspect opponents'
boards during the game and everyone's final board in the results. Players who
complete the same region during one round share
that round's reward; the next reward remains for the next round in which
someone completes it. Claimed rewards remain unavailable if a player concedes.
The same-region tie avoids a rival-completion sound; completing different
regions can produce both the player's celebration and the rival sound.
When no player can use either die, the game waits briefly and rolls the next
round if some future roll can still be played.

## Authentication and privacy

- Playing and viewing game instructions require an active session.
- Session tokens are stored with `flutter_secure_storage`; sign-out also clears
  the local token when the server cannot be reached.
- Usernames are trimmed and compared case-insensitively with Unicode
  normalization. The server enforces uniqueness in SQLite.
- Six-digit numeric passwords provide limited protection against guessing.
  Use a longer numeric password for better security. No email-based password
  recovery is available.
- Sign-in is limited to 8 attempts per 15 minutes and registration to 5 attempts
  per hour, per client address resolved by Better Auth. If deployed behind a
  reverse proxy, configure trusted proxy addresses before relying on IP-based
  limits. The in-memory limit store resets on restart and is for one server
  instance.
- Requests carry a random reference ID. If an error includes a reference code,
  share that code with support to find its server log entry.
- Diagnostic logs include only the request ID, known auth endpoint, method,
  status, and duration. They do not include passwords, tokens, email addresses,
  usernames, request bodies, or client IP addresses. The client emits detailed
  request diagnostics only in debug builds.
- The app does not collect gameplay analytics or use the diagnostics as user
  activity tracking.
- Production builds must use HTTPS. Keep `BETTER_AUTH_SECRET` outside source
  control and rotate it if it may have been exposed.
