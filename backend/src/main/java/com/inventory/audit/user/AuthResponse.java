package com.inventory.audit.user;

import java.util.Set;
import java.util.stream.Collectors;

/**
 * DTO for authentication response containing token and user information.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */

/* This class is the AuthResponse. */
public class AuthResponse 
{
    
    private String token;
    private Long id;
    private String username;
    private String email;
    private Set<String> roles;
    
    /* This constructor is the default constructor. */
    public AuthResponse() {}
    
    /* This constructor is the constructor for the AuthResponse. */
    public AuthResponse(String token, User user)
    {
        this.token = token;
        this.id = user.getId();
        this.username = user.getUsername();
        this.email = user.getEmail();
        this.roles = user.getRoles().stream()
                .map(role -> role.getName())
                .collect(Collectors.toSet());
    }
    
    /* These methods are the getters and setters for the AuthResponse. */
    public String getToken() {return token;}
    
    public void setToken(String token) {this.token = token;}
    
    public Long getId() {return id;}
    
    public void setId(Long id) {this.id = id;}
    
    public String getUsername() {return username;}
    
    public void setUsername(String username) {this.username = username;}
    
    public String getEmail() {return email;}
    
    public void setEmail(String email) {this.email = email;}
    
    public Set<String> getRoles() {return roles;}
    
    public void setRoles(Set<String> roles) {this.roles = roles;}
}

