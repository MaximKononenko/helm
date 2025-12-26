package {{GROUP_ID}}.controller;

import {{GROUP_ID}}.service.HelloService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * Sample REST controller for {{PROJECT_NAME}}.
 */
@RestController
@RequestMapping("/api/v1")
public class HelloController {

    private final HelloService helloService;

    public HelloController(HelloService helloService) {
        this.helloService = helloService;
    }

    /**
     * Sample greeting endpoint.
     *
     * @param name Optional name parameter
     * @return Greeting response
     */
    @GetMapping("/hello")
    public ResponseEntity<Map<String, Object>> hello(
            @RequestParam(defaultValue = "World") String name) {
        
        return ResponseEntity.ok(Map.of(
            "message", helloService.greet(name),
            "service", "{{PROJECT_NAME}}",
            "timestamp", System.currentTimeMillis()
        ));
    }
}
