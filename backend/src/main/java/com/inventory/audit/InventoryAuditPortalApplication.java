package com.inventory.audit;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.scheduling.annotation.EnableScheduling;

/**
 * Main Spring Boot application class for the Inventory Audit Portal.
 * This application provides REST APIs for managing inventory items and tracking audit events.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */
@SpringBootApplication
@EnableCaching
@EnableScheduling
public class InventoryAuditPortalApplication 
{

	public static void main(String[] args) {SpringApplication.run(InventoryAuditPortalApplication.class, args);}

}

