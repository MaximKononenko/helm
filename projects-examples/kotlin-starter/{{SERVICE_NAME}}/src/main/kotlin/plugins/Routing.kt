package {{GROUP_ID}}.plugins

import {{GROUP_ID}}.routes.healthRoutes
import {{GROUP_ID}}.routes.helloRoutes
import io.ktor.server.application.*
import io.ktor.server.plugins.callloging.*
import io.ktor.server.plugins.defaultheaders.*
import io.ktor.server.plugins.statuspages.*
import io.ktor.server.request.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import io.ktor.http.*
import org.slf4j.event.Level

/**
 * Configure application routing and plugins.
 */
fun Application.configureRouting() {
    // Default headers
    install(DefaultHeaders) {
        header("X-Service-Name", "{{PROJECT_NAME}}")
    }
    
    // Request logging
    install(CallLogging) {
        level = Level.INFO
        filter { call -> call.request.path().startsWith("/") }
    }
    
    // Status pages for error handling
    install(StatusPages) {
        exception<Throwable> { call, cause ->
            call.application.log.error("Unhandled exception", cause)
            call.respond(
                HttpStatusCode.InternalServerError,
                mapOf(
                    "error" to "Internal Server Error",
                    "message" to (cause.message ?: "Unknown error")
                )
            )
        }
        
        status(HttpStatusCode.NotFound) { call, status ->
            call.respond(
                status,
                mapOf(
                    "error" to "Not Found",
                    "message" to "The requested resource was not found"
                )
            )
        }
    }
    
    // Routes
    routing {
        healthRoutes()
        helloRoutes()
        
        // Root endpoint
        get("/") {
            call.respond(mapOf(
                "service" to "{{PROJECT_NAME}}",
                "version" to "0.0.1",
                "status" to "running"
            ))
        }
    }
}
