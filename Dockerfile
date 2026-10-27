# Etapa 1: Compilación (Build)
FROM maven:3.9-eclipse-temurin-25 AS build
WORKDIR /app
# Copiamos el pom y descargamos dependencias primero (optimiza el caché de Docker)
COPY pom.xml .
RUN mvn dependency:go-offline
# Copiamos el código fuente y compilamos ignorando los tests para ir más rápido
COPY src ./src
RUN mvn clean package -DskipTests

# Etapa 2: Ejecución (Runtime) optimizada
FROM eclipse-temurin:25-jre-alpine
WORKDIR /app
# Exponemos el puerto (cambialo según el servicio: 8080, 8081, 8082 u 8088)
EXPOSE 8088
# Traemos SOLO el archivo .jar generado en la Etapa 1
COPY --from=build /app/target/*.jar app.jar

ENTRYPOINT ["java", "-jar", "app.jar"]