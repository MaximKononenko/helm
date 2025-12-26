# ============================================
# Spring Boot Microservice Dockerfile
# Project: {{PROJECT_NAME}}
# ============================================
# Multi-stage build with layered JARs for optimized caching

# === BUILD STAGE ===
FROM eclipse-temurin:{{JAVA_VERSION}}-jdk-alpine AS builder

WORKDIR /app

# Copy Maven wrapper and pom.xml
COPY mvnw .
COPY .mvn .mvn
COPY pom.xml .

# Download dependencies (cached layer)
RUN ./mvnw dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application
RUN ./mvnw clean package -DskipTests

# Extract layers for optimized Docker caching
RUN java -Djarmode=layertools -jar target/*.jar extract

# === PRODUCTION STAGE ===
FROM eclipse-temurin:{{JAVA_VERSION}}-jre-alpine AS production

# Create non-root user for security
RUN addgroup -g 1001 -S spring \
    && adduser -S spring -u 1001 -G spring

WORKDIR /app

# Copy layers in order of change frequency (least to most)
COPY --from=builder /app/dependencies/ ./
COPY --from=builder /app/spring-boot-loader/ ./
COPY --from=builder /app/snapshot-dependencies/ ./
COPY --from=builder /app/application/ ./

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
