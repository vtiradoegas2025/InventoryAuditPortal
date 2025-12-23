package com.inventory.audit.user;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * DTO for password reset requests.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */
public class ResetPasswordRequest {
    
    @NotBlank(message = "Token is required")
    private String token;
    
    @NotBlank(message = "Password is required")
    @Size(min = 8, message = "Password must be at least 8 characters")
    private String newPassword;
    
    /* This constructor is the default constructor. */
    public ResetPasswordRequest() {}
    
    /* This constructor is the constructor for the ResetPasswordRequest. */
    public ResetPasswordRequest(String token, String newPassword) {this.token = token; this.newPassword = newPassword;}
    
    /* These methods are the getters and setters for the ResetPasswordRequest. */
    public String getToken() {return token;}
    
    public void setToken(String token) {this.token = token;}
    
    public String getNewPassword() {return newPassword;}
    
    public void setNewPassword(String newPassword) {this.newPassword = newPassword;}
}

