# LogiRock: levantar el proyecto completo con Docker

Con esta guía levantás los 7 contenedores del proyecto (3 MySQL, config-server, security, courier y shipment) con un solo comando. Las imágenes se descargan de Docker Hub, así que no hace falta compilar nada.

## 1. Requisitos

- **Docker Desktop** instalado y abierto (la ballena en verde). En Windows, con WSL 2.
- **Git**.
- Al menos **5 GB libres** en disco.
- Estos puertos libres en tu PC: `8080`, `8081`, `8082`, `8088`, `3308`, `3309` y `3310`. Si tenés un MySQL local en esos puertos, apagalo.

## 2. Descargar el repo

```bash
git clone https://github.com/LogiRock/LogiRock-ConfigServer.git
cd LogiRock-ConfigServer/orquestacion
```

## 3. Crear tu `.env`

El `.env` tiene contraseñas, por eso **no está en el repo**. Copiá la plantilla:

```bash
# Windows (PowerShell)
copy .env.example .env

# Linux / Mac
cp .env.example .env
```

Abrilo y completá los valores. Como cada uno levanta sus propias bases en su PC, **podés inventar los que quieras** (usuario, contraseñas y admin). Lo único: nunca subas tu `.env` a GitHub.

```env
DB_USERNAME=
DB_PASSWORD=
MYSQL_ROOT_PASSWORD=
JWT_SECRET_BASE64=
JWT_ISSUER=logirock-security
ADMIN_USERNAME=
ADMIN_PASSWORD=
```

Si preferís generar tu propia clave JWT (para pruebas locales sirve cualquiera):

```bash
docker run --rm alpine sh -c "head -c 32 /dev/urandom | base64"
```

Pegá el resultado en `JWT_SECRET_BASE64`, sin comillas ni espacios.

## 4. Levantar todo

```bash
docker compose pull
docker compose up -d
```

La primera vez tarda unos minutos, porque descarga las imágenes y los MySQL inicializan sus bases. Compose espera a que las bases y el config-server estén sanos antes de arrancar los servicios.

## 5. Verificar

```bash
docker compose ps
```

Los 7 tienen que estar `Up`, y los MySQL y el config-server además con `(healthy)`.

| Servicio | URL |
|---|---|
| shipment-service | http://localhost:8080/swagger-ui.html |
| security-service | http://localhost:8081 |
| courier-service | http://localhost:8082/swagger-ui.html |
| config-server | http://localhost:8088/security-service/default |

Para ver el log de un servicio: `docker logs -f shipment-service` (salís con Ctrl+C).

## 6. Uso diario

| Quiero... | Comando |
|---|---|
| Apagar todo (los datos se conservan) | `docker compose stop` |
| Volver a prender | `docker compose up -d` |
| Bajar las últimas versiones | `git pull` → `docker compose pull` → `docker compose up -d` |
| Empezar de cero (**borra los datos de las bases**) | `docker compose down -v` → `docker compose up -d` |

## 7. Problemas comunes

- **`dependency failed to start: container config-server is unhealthy`**: suele pasar en PCs lentas. Esperá un minuto y corré de nuevo `docker compose up -d`; solo arranca lo que falta.
- **`Access denied for user`** en un servicio: cambiaste el `.env` después de que las bases ya se habían creado. Corré `docker compose down -v` y después `docker compose up -d`.
- **`port is already allocated`**: algo en tu PC ya usa ese puerto (por ejemplo, un MySQL local). Apagalo y reintentá.
- **`Could not resolve placeholder '...'`**: falta esa variable en tu `.env`.
- **Docker se cuelga o da `500 Internal Server Error`**: casi siempre es falta de espacio en disco. Liberá espacio, corré `docker builder prune -f` y reiniciá Docker Desktop.

Si algo no anda, mandá la salida de `docker compose ps` y de `docker logs <servicio>` al grupo.
