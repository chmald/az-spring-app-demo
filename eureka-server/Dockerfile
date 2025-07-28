FROM eclipse-temurin:17-jre-noble

# Create a non-root user
RUN groupadd -r spring && useradd -r -g spring spring

WORKDIR /app

# Copy the built jar file
COPY target/eureka-server-*.jar app.jar

RUN chown -R spring:spring /app
USER spring

EXPOSE 8761

ENV JAVA_OPTS=""
ENV SERVICE_NAME="eureka-server"

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
