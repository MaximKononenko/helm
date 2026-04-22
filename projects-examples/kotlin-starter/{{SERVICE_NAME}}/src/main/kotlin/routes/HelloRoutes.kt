package {{GROUP_ID}}.routes

import io.ktor.server.application.*
import io.ktor.server.response.*
import io.ktor.server.routing.*
import java.time.Instant

/**
 * Sample API routes.
 */
fun Route.helloRoutes() {
    route("/api/v1") {
        get("/hello") {
            val name = call.request.queryParameters["name"] ?: "World"
            
            call.respond(mapOf(
                "message" to "Hello, $name! Welcome to {{OB_PROJECT_NAME}}",
                "service" to "{{OB_PROJECT_NAME}}",
                "timestamp" to Instant.now().toString()
            ))
        }
    }
}
