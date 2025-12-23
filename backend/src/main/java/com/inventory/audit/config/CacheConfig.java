package com.inventory.audit.config;

import com.github.benmanes.caffeine.cache.Caffeine;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cache.caffeine.CaffeineCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.concurrent.TimeUnit;

/**
 * Cache configuration for the application.
 * Configures Caffeine cache manager with size limits and expiration policies.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */
@Configuration
@EnableCaching
public class CacheConfig 
{

    @Bean
    @SuppressWarnings("null")
    public CacheManager cacheManager() 
    {
        CaffeineCacheManager cacheManager = new CaffeineCacheManager("inventoryItems");
        cacheManager.setCaffeine(Caffeine.newBuilder()
            .maximumSize(10000)
            .expireAfterWrite(30, TimeUnit.MINUTES)
            .expireAfterAccess(15, TimeUnit.MINUTES)
            .recordStats());
        return cacheManager;
    }
}

