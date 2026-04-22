package {{GROUP_ID}}.routes

import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import java.lang.management.ManagementFactory
import java.time.Instant

private val startupTime = Instant.now()

/**
 * Health check routes for Kubernetes probes.
 */
fun Route.healthRoutes() {
    // Liveness probe
    get("/health") {
        call.respond(mapOf(
            "status" to "healthy",
            "timestamp" to Instant.now().toString()
        ))
    }
    
    // Readiness probe
    get("/ready") {
        // Add dependency checks here
        val isReady = true
        
        if (isReady) {
            call.respond(mapOf(
                "status" to "ready",
                "timestamp" to Instant.now().toString()
            ))
        } else {
            call.respond(
                io.ktor.http.HttpStatusCode.ServiceUnavailable,
                mapOf(
                    "status" to "not ready",
                    "timestamp" to Instant.now().toString()
                )
            )
        }
    }
    
    // Detailed health check
    get("/health/details") {
        val runtime = Runtime.getRuntime()
        val memoryBean = ManagementFactory.getMemoryMXBean()
        val uptime = java.time.Duration.between(startupTime, Instant.now())
        
        call.respond(mapOf(
            "status" to "healthy",
            "service" to "{{OB_PROJECT_NAME}}",
            "version" to "0.0.1",
            "uptime" to "${uptime.seconds}s",
            "startedAt" to startupTime.toString(),
            "timestamp" to Instant.now().toString(),
            "memory" to mapOf(
                "used" to "${(runtime.totalMemory() - runtime.freeMemory()) / 1024 / 1024}MB",
                "total" to "${runtime.totalMemory() / 1024 / 1024}MB",
                "max" to "${runtime.maxMemory() / 1024 / 1024}MB"
            ),
            "jvm" to mapOf(
                "version" to System.getProperty("java.version"),
                "vendor" to System.getProperty("java.vendor")
            )
        ))
    }
}
