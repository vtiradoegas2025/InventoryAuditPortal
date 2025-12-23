package com.inventory.audit.config;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;

/**
 * Utility class for JWT token operations.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */

/* This class is the JWT utility. */
@Component
public class JwtUtil 
{
    
    @Autowired
    private JwtConfig jwtConfig;
    
    /* This method extracts the username from the token. */
    public String extractUsername(String token) {return extractClaim(token, Claims::getSubject);}
    
    /* This method extracts the expiration date from the token. */
    public Date extractExpiration(String token) {return extractClaim(token, Claims::getExpiration);}

    /* This method extracts a specific claim from the token. */
    public <T> T extractClaim(String token, Function<Claims, T> claimsResolver) 
    {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }
    
    /* This method extracts all the claims from the token. */
    private Claims extractAllClaims(String token) {return Jwts.parser().verifyWith(jwtConfig.getSecretKey()).build().parseSignedClaims(token).getPayload();}
    
    /* This method checks if the token is expired. */
    private Boolean isTokenExpired(String token) {return extractExpiration(token).before(new Date());}
    
    /* This method generates a new token. */
    public String generateToken(UserDetails userDetails) {Map<String, Object> claims = new HashMap<>();return createToken(claims, userDetails.getUsername());}
    
    /* This method creates a new token. */
    private String createToken(Map<String, Object> claims, String subject) 
    {
        return Jwts.builder()
                .claims(claims)
                .subject(subject)
                .issuedAt(new Date(System.currentTimeMillis()))
                .expiration(new Date(System.currentTimeMillis() + jwtConfig.getExpiration()))
                .signWith(jwtConfig.getSecretKey())
                .compact();
    }
    
    /* This method validates the token. */
    public Boolean validateToken(String token, UserDetails userDetails) 
    {
        final String username = extractUsername(token);
        return (username.equals(userDetails.getUsername()) && !isTokenExpired(token));
    }
}

