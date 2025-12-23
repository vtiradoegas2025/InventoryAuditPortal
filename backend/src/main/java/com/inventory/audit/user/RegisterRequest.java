package com.inventory.audit.user;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * DTO for user registration requests.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */

/* This class is the RegisterRequest. */
public class RegisterRequest 
{
    
    @NotBlank(message = "Username is required")
    @Size(min = 3, max = 100, message = "Username must be between 3 and 100 characters")
    private String username;
    
    @NotBlank(message = "Email is required")
    @Email(message = "Email must be valid")
    private String email;
    
    @NotBlank(message = "Password is required")
    @Size(min = 8, message = "Password must be at least 8 characters")
    private String password;
    
    @Pattern(regexp = "^$|USER|MANAGER", message = "Role must be either USER or MANAGER")
    private String role;
    
    public RegisterRequest() {}
    
    /* This constructor is the constructor for the RegisterRequest. */
    public RegisterRequest(String username, String email, String password) {this.username = username; this.email = email; this.password = password;}
    
    /* This constructor is the constructor for the RegisterRequest with role. */
    public RegisterRequest(String username, String email, String password, String role) {
        this.username = username;
        this.email = email;
        this.password = password;
        this.role = role;
    }

    /* These methods are the getters and setters for the RegisterRequest. */
    public String getUsername() {return username;}
    
    public void setUsername(String username) {this.username = username;}
    
    public String getEmail() {return email;}
    
    public void setEmail(String email) {this.email = email;}
    
    public String getPassword() {return password;}
    
    public void setPassword(String password) {this.password = password;}
    
    public String getRole() {return role;}
    
    public void setRole(String role) {this.role = role;}
}

