# ============================================
# Spring Boot Microservice Dockerfile
# Project: {{PROJECT_NAME}}
# ============================================
# Production image - expects pre-built artifacts from Maven build in ADO pipeline

ARG BASE_IMAGE_NAME=java:17-jdk
ARG REGISTRY=catalina.azurecr.io
FROM $REGISTRY/$BASE_IMAGE_NAME

ARG JAVA_ARTIFACT_EXTENSION
ENV JAVA_ARTIFACT_NAME={{SERVICE_NAME}} \
    JAVA_ARTIFACT_EXTENSION=${JAVA_ARTIFACT_EXTENSION:-jar}

# Datadog agent installation (required for APM)
RUN curl -L -o dd-java-agent.jar https://dtdg.co/latest-java-tracer

# Copy pre-built JAR from Maven build (expects target/*.jar)
USER root
COPY --chown=catalina:catalina target/*.jar ${CONTAINER_WORKDIR}/app.jar
USER catalina

# Expose port
EXPOSE {{PORT}}

# JVM options for containers
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:InitialRAMPercentage=50.0 -Djava.security.egd=file:/dev/./urandom"

# Start application (catalina base image provides CONTAINER_WORKDIR)
CMD ["sh", "-c", "java $JAVA_OPTS -jar ${CONTAINER_WORKDIR}/app.jar"]
