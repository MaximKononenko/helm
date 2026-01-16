# ============================================
# Spring Boot Microservice Dockerfile
# Project: {{PROJECT_NAME}}
# ============================================
# Single-stage production image
# Build happens in ADO workspace, this expects pre-built artifacts

FROM catalina.azurecr.io/eclipse-temurin:{{JAVA_VERSION}}-jre-alpine AS production

# Create non-root user for security
RUN addgroup -g 1001 -S spring \
    && adduser -S spring -u 1001 -G spring

WORKDIR /app

# Copy pre-built JAR from artifactsPath (built by Maven in ADO)
# Expects: target/*.jar from Maven build
COPY target/*.jar ./app.jar

# Change ownership to non-root user
RUN chown -R spring:spring /app

# Switch to non-root user
USER spring

# Expose port
EXPOSE {{PORT}}

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=60s --retries=3 \
    CMD wget -q --spider http://localhost:{{PORT}}/actuator/health || exit 1

# JVM options for containers
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:InitialRAMPercentage=50.0 -Djava.security.egd=file:/dev/./urandom"

# Start application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS org.springframework.boot.loader.launch.JarLauncher"]
