# Multi-stage Dockerfile for Spring Boot microservices
# Stage 1: Build stage
FROM eclipse-temurin:17-jdk AS builder

# Install Maven
RUN apt-get update && apt-get install -y maven && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy Maven configuration files
COPY pom.xml ./

# Copy all service pom files for dependency resolution
COPY config-server/pom.xml ./config-server/
COPY eureka-server/pom.xml ./eureka-server/
COPY gateway-service/pom.xml ./gateway-service/
COPY user-service/pom.xml ./user-service/
COPY product-service/pom.xml ./product-service/
COPY order-service/pom.xml ./order-service/

# Download dependencies (cached layer)
RUN mvn dependency:go-offline -B

# Copy source code
COPY config-server/src ./config-server/src
COPY eureka-server/src ./eureka-server/src
COPY gateway-service/src ./gateway-service/src
COPY user-service/src ./user-service/src
COPY product-service/src ./product-service/src
COPY order-service/src ./order-service/src

# Build all services
RUN mvn clean package -DskipTests

# Stage 2: Runtime stage
FROM eclipse-temurin:17-jre-noble

# Create non-root user for security
RUN groupadd -r spring && useradd -r -g spring spring

WORKDIR /app

# Copy JAR files from build stage
COPY --from=builder /app/*/target/*.jar ./

# Create startup script that selects the correct JAR based on SERVICE_NAME
RUN echo '#!/bin/bash\n\
case $SERVICE_NAME in\n\
  eureka-server)\n\
    exec java $JAVA_OPTS -jar eureka-server-*.jar\n\
    ;;\n\
  config-server)\n\
    exec java $JAVA_OPTS -jar config-server-*.jar\n\
    ;;\n\
  gateway-service)\n\
    exec java $JAVA_OPTS -jar gateway-service-*.jar\n\
    ;;\n\
  user-service)\n\
    exec java $JAVA_OPTS -jar user-service-*.jar\n\
    ;;\n\
  product-service)\n\
    exec java $JAVA_OPTS -jar product-service-*.jar\n\
    ;;\n\
  order-service)\n\
    exec java $JAVA_OPTS -jar order-service-*.jar\n\
    ;;\n\
  *)\n\
    echo "Error: SERVICE_NAME environment variable must be set to one of: eureka-server, config-server, gateway-service, user-service, product-service, order-service"\n\
    exit 1\n\
    ;;\n\
esac' > /app/start.sh && chmod +x /app/start.sh

# Set ownership and switch to non-root user
RUN chown -R spring:spring /app
USER spring

# Default environment variables
ENV JAVA_OPTS=""
ENV SERVICE_NAME=""

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:${SERVER_PORT:-8080}/actuator/health || exit 1

EXPOSE 8080

ENTRYPOINT ["/app/start.sh"]