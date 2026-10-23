package configserver.configserver;

import org.springframework.cloud.config.server.EnableConfigServer;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.SpringApplication;

@SpringBootApplication
@EnableConfigServer
public class ConfigServerApplication {
    static void main(String[] args) {
        SpringApplication.run(ConfigServerApplication.class, args);
    }
}