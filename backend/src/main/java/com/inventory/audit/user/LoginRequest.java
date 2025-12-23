package com.inventory.audit.user;

import jakarta.validation.constraints.NotBlank;

/**
 * DTO for user login requests.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */
public class LoginRequest 
{
    
    @NotBlank(message = "Username is required")
    private String username;
    
    @NotBlank(message = "Password is required")
    private String password;
    
    /* This constructor is the default constructor. */
    public LoginRequest() {}
    
    /* This constructor is the constructor for the LoginRequest. */
    public LoginRequest(String username, String password) {this.username = username;this.password = password;}
    
    /* These methods are the getters and setters for the LoginRequest. */
    public String getUsername() {return username;}
    
    public void setUsername(String username) {this.username = username;}
    
    public String getPassword() {return password;}
    
    public void setPassword(String password) {this.password = password;}
}

