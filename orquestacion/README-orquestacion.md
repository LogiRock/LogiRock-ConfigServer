# LogiRock: levantar el proyecto completo con Docker

Con esta guía levantás los 10 contenedores del proyecto (3 MySQL, config-server, eureka-server, security, courier, shipment y api-gateway) con un solo comando. Las imágenes se descargan de Docker Hub, así que no hace falta compilar nada.

## 1. Requisitos

- **Docker Desktop** instalado y abierto (la ballena en verde). En Windows, con WSL 2.
- **Git**.
- Al menos **5 GB libres** en disco.
- Estos puertos libres en tu PC: `3000`,`8065`,`8066`, `8080`, `8081`, `8082`, `8088`, `3308`, `3309` y `3310`. Si tenés un MySQL local en esos puertos, apagalo.

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
JWT_ISSUER=security-service
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

La primera vez tarda unos minutos, porque descarga las imágenes y los MySQL inicializan sus bases. Los contenedores arrancan en orden y cada uno espera a que el anterior esté sano: bases y config-server → eureka-server → servicios → api-gateway.

## 5. Verificar

```bash
docker compose ps
```

Los 9 tienen que estar `Up (healthy)`. La primera vez puede tardar 2 o 3 minutos.

| Servicio | URL |
|---|---|
| **API Gateway (entrada única)** | http://localhost:8066/application/... |
| Rutas del Gateway | http://localhost:8066/actuator/gateway/routes |
| Eureka (dashboard) | http://localhost:8065 |
| shipment-service | http://localhost:8080/swagger-ui.html |
| courier-service | http://localhost:8082/swagger-ui.html |
| security-service | http://localhost:8081 |
| config-server | http://localhost:8088/shipment-service/dev |
| **Frontend (la app)** | **http://localhost:3000** |


Rutas del Gateway:

| Ruta | Servicio |
|---|---|
| `/application/auth/**` | security-service |
| `/application/shipments/**` | shipment-service |
| `/application/couriers/**` | courier-service |


Ejemplo: `POST http://localhost:8066/application/auth/api/auth/login`

Para ver el log de un servicio: `docker logs -f shipment-service` (salís con Ctrl+C).

## Usuarios de prueba

- **ADMIN:** lo crea security-service al arrancar, con `ADMIN_USERNAME` y `ADMIN_PASSWORD` de tu `.env`.
- **CLIENTE:** desde la pantalla de login, con "Crear cuenta de cliente".
- **REPARTIDOR:** lo da de alta un ADMIN desde Repartidores, con usuario y contraseña.

## Desarrollo del front

Con el compose levantado, `npm run dev` en `logitrack-frontend` (puerto 5173). El gateway ya permite ese origen por CORS.
Si el gateway da 404 en todo, arrancó sin su configuración. Con el fail-fast no debería pasar más, pero se arregla con `docker compose up -d --no-deps --force-recreate api-gateway`.

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
- **El Gateway responde 503 justo después de levantar**: el Gateway actualiza la lista de Eureka cada 30 segundos. Esperá medio minuto y reintentá.
- **`port is already allocated`**: algo en tu PC ya usa ese puerto (por ejemplo, un MySQL local). Apagalo y reintentá.
- **`Could not resolve placeholder '...'`**: falta esa variable en tu `.env`.
- **Docker se cuelga o da `500 Internal Server Error`**: casi siempre es falta de espacio en disco. Liberá espacio, corré `docker builder prune -f` y reiniciá Docker Desktop.

Si algo no anda, mandá la salida de `docker compose ps` y de `docker logs <servicio>` al grupo.