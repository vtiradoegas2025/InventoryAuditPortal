package com.inventory.audit.user;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

/**
 * DTO for forgot password requests.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */

/* This class is the ForgotPasswordRequest. */
public class ForgotPasswordRequest 
{
    
    @NotBlank(message = "Email is required")
    @Email(message = "Email must be valid")
    private String email;
    
    /* This constructor is the default constructor. */
    public ForgotPasswordRequest() {}
    
    /* This constructor is the constructor for the ForgotPasswordRequest. */
    public ForgotPasswordRequest(String email) {this.email = email;}
    
    /* These methods are the getters and setters for the ForgotPasswordRequest. */
    public String getEmail() {return email;}
    
    public void setEmail(String email) {this.email = email;}
}

