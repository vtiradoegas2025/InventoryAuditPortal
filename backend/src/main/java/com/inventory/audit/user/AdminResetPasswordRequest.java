package com.inventory.audit.user;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * DTO for admin password reset requests.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */
public class AdminResetPasswordRequest 
{
    
    @NotBlank(message = "Username is required")
    private String username;
    
    @NotBlank(message = "Password is required")
    @Size(min = 8, message = "Password must be at least 8 characters")
    private String newPassword;
    
    /* This constructor is the default constructor. */
    public AdminResetPasswordRequest() {}
    
    /* This constructor is the constructor for the AdminResetPasswordRequest. */
    public AdminResetPasswordRequest(String username, String newPassword) {this.username = username;this.newPassword = newPassword;}
    
    /* These methods are the getters and setters for the AdminResetPasswordRequest. */
    public String getUsername() {return username;}
    
    public void setUsername(String username) {this.username = username;}
    
    public String getNewPassword() {return newPassword;}
    
    public void setNewPassword(String newPassword) {this.newPassword = newPassword;}
}

