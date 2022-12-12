package io.cecg.referenceapplication.api.controllers;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import io.prometheus.client.Counter;


@RestController
public class GreetingController {




    static final Counter totalRequests = Counter.build()
            .namespace("reference_app_canary").name("total_requests").help("Total requests.").register();


    @GetMapping("/hello")
    public String hello(@RequestParam(value = "name", defaultValue = "World") String name) {
        totalRequests.inc();
        return String.format(" V2 : Hello %s!", name);
    }
}
