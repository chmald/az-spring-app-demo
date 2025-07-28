FROM openjdk:17-jdk-slim

# Set the working directory
WORKDIR /app

# Copy the Maven wrapper and pom files
COPY .mvn/ .mvn
COPY mvnw pom.xml ./

# Copy all service pom files
COPY config-server/pom.xml ./config-server/
COPY eureka-server/pom.xml ./eureka-server/
COPY gateway-service/pom.xml ./gateway-service/
COPY user-service/pom.xml ./user-service/
COPY product-service/pom.xml ./product-service/
COPY order-service/pom.xml ./order-service/

# Download dependencies
RUN ./mvnw dependency:go-offline -B

# Copy the source code
COPY config-server/src ./config-server/src
COPY eureka-server/src ./eureka-server/src
COPY gateway-service/src ./gateway-service/src
COPY user-service/src ./user-service/src
COPY product-service/src ./product-service/src
COPY order-service/src ./order-service/src

# Build the application
RUN ./mvnw clean package -DskipTests

# Multi-stage build - runtime stage
FROM openjdk:17-jre-slim as runtime

WORKDIR /app

# Copy the jar files from build stage
COPY --from=0 /app/*/target/*.jar ./

# Create a script to run different services based on SERVICE_NAME environment variable
RUN echo '#!/bin/bash\n\
case $SERVICE_NAME in\n\
  config-server)\n\
    exec java -jar config-server-*.jar\n\
    ;;\n\
  eureka-server)\n\
    exec java -jar eureka-server-*.jar\n\
    ;;\n\
  gateway-service)\n\
    exec java -jar gateway-service-*.jar\n\
    ;;\n\
  user-service)\n\
    exec java -jar user-service-*.jar\n\
    ;;\n\
  product-service)\n\
    exec java -jar product-service-*.jar\n\
    ;;\n\
  order-service)\n\
    exec java -jar order-service-*.jar\n\
    ;;\n\
  *)\n\
    echo "Unknown service: $SERVICE_NAME"\n\
    exit 1\n\
    ;;\n\
esac' > /app/start.sh && chmod +x /app/start.sh

# Create a non-root user
RUN groupadd -r spring && useradd -r -g spring spring
RUN chown -R spring:spring /app
USER spring

EXPOSE 8080

ENTRYPOINT ["/app/start.sh"]