package com.inventory.audit.user;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

/**
 * SMTP implementation of EmailService using Spring Mail.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */
@Service
public class SmtpEmailService implements EmailService 
{
    
    @Autowired(required = false)
    private JavaMailSender mailSender;
    
    @Value("${email.from:noreply@inventory-audit-portal.com}")
    private String fromEmail;
    
    @Value("${email.enabled:false}")
    private boolean emailEnabled;
    
    @Override
    public void sendPasswordResetEmail(String email, String resetToken, String resetUrl) 
    {
        // If email is disabled or mailSender is not configured, log the reset URL instead
        if (!emailEnabled || mailSender == null) 
        {
            System.out.println("========================================");
            System.out.println("EMAIL DISABLED - Password Reset Link");
            System.out.println("========================================");
            System.out.println("Email: " + email);
            System.out.println("Reset URL: " + resetUrl);
            System.out.println("Reset Token: " + resetToken);
            System.out.println("========================================");
            return;
        }
        
        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromEmail);
            message.setTo(email);
            message.setSubject("Password Reset Request");
            message.setText(buildPasswordResetEmailBody(resetUrl, resetToken));
            
            mailSender.send(message);
        } 
        catch (Exception e) 
        {
            // Log error but don't fail the request
            System.err.println("Failed to send password reset email: " + e.getMessage());
            // Still log the reset URL for development/testing
            System.out.println("========================================");
            System.out.println("EMAIL SEND FAILED - Password Reset Link");
            System.out.println("========================================");
            System.out.println("Email: " + email);
            System.out.println("Reset URL: " + resetUrl);
            System.out.println("Reset Token: " + resetToken);
            System.out.println("Error: " + e.getMessage());
            System.out.println("========================================");
        }
    }
    
    private String buildPasswordResetEmailBody(String resetUrl, String resetToken) 
    {
        return String.format(
            "You have requested to reset your password.\n\n" +
            "Please click on the following link to reset your password:\n" +
            "%s\n\n" +
            "If you did not request this password reset, please ignore this email.\n\n" +
            "This link will expire in 1 hour.\n\n" +
            "Best regards,\n" +
            "Inventory Audit Portal Team",
            resetUrl
        );
    }
}

