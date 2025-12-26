# ============================================
# Kotlin Microservice Dockerfile
# Project: {{PROJECT_NAME}}
# ============================================
# Multi-stage build for optimized production image

# === BUILD STAGE ===
FROM eclipse-temurin:{{JAVA_VERSION}}-jdk-alpine AS builder

WORKDIR /app

# Copy Gradle wrapper and build files
COPY gradlew .
COPY gradle gradle
COPY build.gradle.kts .
COPY settings.gradle.kts .
COPY gradle.properties .

# Download dependencies (cached layer)
RUN ./gradlew dependencies --no-daemon

# Copy source code
COPY src ./src
COPY detekt.yml .

# Build the shadow JAR
RUN ./gradlew shadowJar --no-daemon

# === PRODUCTION STAGE ===
FROM eclipse-temurin:{{JAVA_VERSION}}-jre-alpine AS production

# Create non-root user for security
RUN addgroup -g 1001 -S kotlin \
    && adduser -S kotlin -u 1001 -G kotlin

WORKDIR /app

# Copy the built JAR
COPY --from=builder /app/build/libs/{{PROJECT_NAME}}-all.jar ./app.jar

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
