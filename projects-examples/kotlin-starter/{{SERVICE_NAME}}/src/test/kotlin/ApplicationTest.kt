package {{GROUP_ID}}

import io.ktor.client.request.*
import io.ktor.client.statement.*
import io.ktor.http.*
import io.ktor.server.testing.*
import kotlin.test.*

/**
 * Application tests for {{OB_PROJECT_NAME}}.
 */
class ApplicationTest {

    @Test
    fun `root endpoint returns service info`() = testApplication {
        application {
            module()
        }
        
        client.get("/").apply {
            assertEquals(HttpStatusCode.OK, status)
            assertTrue(bodyAsText().contains("{{OB_PROJECT_NAME}}"))
        }
    }

    @Test
    fun `health endpoint returns healthy status`() = testApplication {
        application {
            module()
        }
        
        client.get("/health").apply {
            assertEquals(HttpStatusCode.OK, status)
            assertTrue(bodyAsText().contains("healthy"))
        }
    }

    @Test
    fun `hello endpoint returns greeting`() = testApplication {
        application {
            module()
        }
        
        client.get("/api/v1/hello").apply {
            assertEquals(HttpStatusCode.OK, status)
            assertTrue(bodyAsText().contains("Hello, World!"))
        }
    }

    @Test
    fun `hello endpoint with name parameter returns personalized greeting`() = testApplication {
        application {
            module()
        }
        
        client.get("/api/v1/hello?name=Kotlin").apply {
            assertEquals(HttpStatusCode.OK, status)
            assertTrue(bodyAsText().contains("Hello, Kotlin!"))
        }
    }
}
