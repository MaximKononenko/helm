package {{GROUP_ID}}.service;

import org.springframework.stereotype.Service;

/**
 * Sample service for {{PROJECT_NAME}}.
 */
@Service
public class HelloService {

    /**
     * Generate a greeting message.
     *
     * @param name Name to greet
     * @return Greeting message
     */
    public String greet(String name) {
        return String.format("Hello, %s! Welcome to {{PROJECT_NAME}}", name);
    }
}
