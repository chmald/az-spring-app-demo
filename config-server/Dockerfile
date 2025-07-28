FROM openjdk:17-jre-slim

# Create a non-root user
RUN groupadd -r spring && useradd -r -g spring spring

WORKDIR /app

# Copy the built jar file
COPY target/config-server-*.jar app.jar

RUN chown -R spring:spring /app
USER spring

EXPOSE 8888

ENV JAVA_OPTS=""
ENV SERVICE_NAME="config-server"

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
