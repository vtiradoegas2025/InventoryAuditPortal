package com.inventory.audit.user;

/**
 * Interface for email service operations.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */
public interface EmailService 
{
    
    /**
     * Sends a password reset email to the user.
     * 
     * @param email The user's email address
     * @param resetToken The password reset token
     * @param resetUrl The full URL for password reset
     */
    void sendPasswordResetEmail(String email, String resetToken, String resetUrl);
}

