# ============================================
# Kotlin Microservice Dockerfile
# Project: {{PROJECT_NAME}}
# ============================================
# Single-stage production image
# Build happens in ADO workspace, this expects pre-built artifacts

FROM catalina.azurecr.io/eclipse-temurin:{{JAVA_VERSION}}-jre-alpine AS production

# Create non-root user for security
RUN addgroup -g 1001 -S kotlin \
    && adduser -S kotlin -u 1001 -G kotlin

WORKDIR /app

# Copy pre-built shadow JAR from artifactsPath (built by Gradle in ADO)
# Expects: build/libs/*-all.jar from Gradle shadowJar task
COPY build/libs/*-all.jar ./app.jar

# Change ownership to non-root user
RUN chown -R kotlin:kotlin /app

# Switch to non-root user
USER kotlin

# Expose port
EXPOSE {{PORT}}

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=30s --retries=3 \
    CMD wget -q --spider http://localhost:{{PORT}}/health || exit 1

# JVM options for containers
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -XX:InitialRAMPercentage=50.0 -Djava.security.egd=file:/dev/./urandom"

# Start application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
