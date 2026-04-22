package {{GROUP_ID}}.controller;

import {{GROUP_ID}}.service.HelloService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.test.web.servlet.MockMvc;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Unit tests for HelloController.
 */
@WebMvcTest(HelloController.class)
class HelloControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private HelloService helloService;

    @Test
    void hello_shouldReturnGreeting() throws Exception {
        when(helloService.greet("World")).thenReturn("Hello, World!");

        mockMvc.perform(get("/api/v1/hello"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.message").value("Hello, World!"))
            .andExpect(jsonPath("$.service").value("{{OB_PROJECT_NAME}}"));
    }

    @Test
    void hello_withName_shouldReturnPersonalizedGreeting() throws Exception {
        when(helloService.greet("John")).thenReturn("Hello, John!");

        mockMvc.perform(get("/api/v1/hello").param("name", "John"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.message").value("Hello, John!"));
    }
}
