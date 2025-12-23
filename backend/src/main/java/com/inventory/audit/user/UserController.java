package com.inventory.audit.user;

import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * REST controller for user authentication and management operations.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */
@RestController
@RequestMapping("/api/auth")
public class UserController 
{
    
    @Autowired
    private UserService userService;
    
    /* This method registers a new user. */
    @PostMapping("/register")
    public ResponseEntity<Map<String, Object>> register(@Valid @RequestBody RegisterRequest request) 
    {
        User user = userService.register(request);
        
        Map<String, Object> response = new HashMap<>();
        response.put("message", "User registered successfully");
        response.put("username", user.getUsername());
        response.put("email", user.getEmail());
        
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
    
    /* This method logs in the user. */
    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) 
    {
        AuthResponse response = userService.login(request);
        return ResponseEntity.ok(response);
    }
    
    /* This method returns the current user. */
    @GetMapping("/me")
    public ResponseEntity<Map<String, Object>> getCurrentUser() 
    {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) 
        {
            throw new com.inventory.audit.common.UnauthorizedException("Not authenticated");
        }
        
        User user = userService.getCurrentUser(authentication.getName());
        
        Map<String, Object> response = new HashMap<>();
        response.put("id", user.getId());
        response.put("username", user.getUsername());
        response.put("email", user.getEmail());
        response.put("roles", user.getRoles().stream()
                .map(role -> role.getName())
                .collect(Collectors.toSet()));
        
        return ResponseEntity.ok(response);
    }
    
    /* This method logs out the user. */
    @PostMapping("/logout")
    public ResponseEntity<Map<String, String>> logout() 
    {
        // In a stateless JWT system, logout is handled client-side by removing the token
        // If using sessions, invalidate the session here
        Map<String, String> response = new HashMap<>();
        response.put("message", "Logged out successfully");
        return ResponseEntity.ok(response);
    }
    
    /* This method sends a password reset link to the user's email. */
    @PostMapping("/forgot-password")
    public ResponseEntity<Map<String, String>> forgotPassword(@Valid @RequestBody ForgotPasswordRequest request) 
    {
        userService.forgotPassword(request);
        
        Map<String, String> response = new HashMap<>();
        response.put("message", "If the email exists, a password reset link has been sent");
        return ResponseEntity.ok(response);
    }
    
    /* This method resets the password for a user. */
    @PostMapping("/reset-password")
    public ResponseEntity<Map<String, String>> resetPassword(@Valid @RequestBody ResetPasswordRequest request) 
    {
        userService.resetPassword(request);
        
        Map<String, String> response = new HashMap<>();
        response.put("message", "Password reset successfully");
        return ResponseEntity.ok(response);
    }
    
    /* This method resets the password for an admin user. */
    @PostMapping("/admin/reset-password")
    public ResponseEntity<Map<String, String>> adminResetPassword(@Valid @RequestBody AdminResetPasswordRequest request) 
    {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) 
        {
            throw new com.inventory.audit.common.UnauthorizedException("Not authenticated");
        }
        
        String adminUsername = authentication.getName();
        userService.adminResetPassword(request, adminUsername);
        
        Map<String, String> response = new HashMap<>();
        response.put("message", "Password reset successfully");
        return ResponseEntity.ok(response);
    }
}

