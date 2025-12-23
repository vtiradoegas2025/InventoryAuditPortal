package com.inventory.audit.config;

import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;

/**
 * Configuration for JWT token settings.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */
@Configuration
public class JwtConfig 
{
    
    @Value("${jwt.secret:defaultSecretKeyThatShouldBeChangedInProductionEnvironmentMinimum32Characters}")
    private String secret;
    
    @Value("${jwt.expiration:86400000}") // 24 hours in milliseconds
    private Long expiration;
    
    public SecretKey getSecretKey() {return Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));}
    
    public Long getExpiration() {return expiration;}
    
    public String getSecret() {return secret;}
}

