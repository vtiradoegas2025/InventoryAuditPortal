package com.inventory.audit.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.servers.Server;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.List;

/**
 * OpenAPI/Swagger configuration for API documentation.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */

/* This class is the OpenAPI configuration. */
@Configuration
public class OpenApiConfig 
{

    @Value("${springdoc.swagger-ui.enabled:true}")
    private boolean swaggerEnabled;

    /* This method returns the custom OpenAPI. */
    @Bean
    public OpenAPI customOpenAPI() 
    {
        return new OpenAPI()
                .info(new Info()
                        .title("Inventory Audit Portal API")
                        .version("1.0.0")
                        .description("REST API for managing inventory items with comprehensive audit logging")
                        .contact(new Contact()
                                .name("Victor Tiradoegas")
                                .email("support@example.com"))
                        .license(new License()
                                .name("Apache 2.0")
                                .url("https://www.apache.org/licenses/LICENSE-2.0.html")))
                .servers(List.of(
                        new Server().url("http://localhost:8080").description("Development Server"),
                        new Server().url("https://api.example.com").description("Production Server")
                ));
    }
}

