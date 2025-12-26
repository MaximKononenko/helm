package {{GROUP_ID}}

import {{GROUP_ID}}.plugins.configureRouting
import {{GROUP_ID}}.plugins.configureSerialization
import io.ktor.server.application.*
import io.ktor.server.engine.*
import io.ktor.server.netty.*

/**
 * Main application entry point for {{PROJECT_NAME}}.
 */
fun main() {
    val port = System.getenv("PORT")?.toIntOrNull() ?: {{PORT}}
    
    embeddedServer(Netty, port = port, host = "0.0.0.0", module = Application::module)
        .start(wait = true)
}

/**
 * Application module configuration.
 */
fun Application.module() {
    configureSerialization()
    configureRouting()
    
    log.info("{{PROJECT_NAME}} started on port ${environment.config.propertyOrNull("ktor.deployment.port")?.getString() ?: "{{PORT}}"}")
}
