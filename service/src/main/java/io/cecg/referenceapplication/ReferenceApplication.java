package io.cecg.referenceapplication;

import io.prometheus.client.exporter.HTTPServer;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import io.prometheus.client.CollectorRegistry;

import java.io.IOException;



@SpringBootApplication
public class ReferenceApplication {

    public static void main(String[] args) throws IOException {
        SpringApplication.run(ReferenceApplication.class, args);
        CollectorRegistry registry = CollectorRegistry.defaultRegistry;

        try {
            HTTPServer server = new HTTPServer(8001);
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

}
