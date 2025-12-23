package com.inventory.audit.user;

import com.inventory.audit.common.BadRequestException;
import com.inventory.audit.common.NotFoundException;
import com.inventory.audit.config.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.UUID;

/**
 * Service class for user management operations.
 * Handles registration, authentication, and password management.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */

/* This class is the UserService. */
@Service
public class UserService 
{
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private RoleRepository roleRepository;
    
    @Autowired
    private PasswordEncoder passwordEncoder;
    
    @Autowired
    private AuthenticationManager authenticationManager;
    
    @Autowired
    private UserDetailsService userDetailsService;
    
    @Autowired
    private JwtUtil jwtUtil;
    
    @Autowired
    private EmailService emailService;
    
    @Autowired
    private PasswordResetTokenRepository passwordResetTokenRepository;
    
    @Value("${app.frontend-url:http://localhost:5173}")
    private String frontendUrl;
    
    @Value("${app.password-reset-token-expiration-hours:1}")
    private int tokenExpirationHours;
    
    @Transactional
    public User register(RegisterRequest request) 
    {
        // Validate username uniqueness
        if (userRepository.existsByUsername(request.getUsername())) {throw new BadRequestException("Username already exists");}
        
        if (userRepository.existsByEmail(request.getEmail())) {throw new BadRequestException("Email already exists");}
        
        validatePassword(request.getPassword());
        
        // Validate and determine role
        String requestedRole = request.getRole();
        final String roleName;
        if (requestedRole == null || requestedRole.trim().isEmpty()) {
            roleName = "USER"; // Default to USER if not provided
        } else {
            String normalizedRole = requestedRole.trim().toUpperCase();
            // Security: Prevent ADMIN role assignment during registration
            if ("ADMIN".equals(normalizedRole)) {
                throw new BadRequestException("ADMIN role cannot be assigned during registration");
            }
            // Validate role is either USER or MANAGER
            if (!"USER".equals(normalizedRole) && !"MANAGER".equals(normalizedRole)) {
                throw new BadRequestException("Role must be either USER or MANAGER");
            }
            roleName = normalizedRole;
        }
        
        // Create new user
        User user = new User();
        user.setUsername(request.getUsername());
        user.setEmail(request.getEmail());
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setEnabled(true);
        user.setCreatedAt(Instant.now());
        user.setUpdatedAt(Instant.now());
        
        // Assign selected role
        final String finalRoleName = roleName;
        Role selectedRole = roleRepository.findByName(finalRoleName)
                .orElseThrow(() -> new RuntimeException("Role not found: " + finalRoleName));
        user.addRole(selectedRole);
        
        return userRepository.save(user);
    }
    
    /* This method logs in the user. */
    public AuthResponse login(LoginRequest request) 
    {
        try 
        {
            
            authenticationManager.authenticate(new UsernamePasswordAuthenticationToken(request.getUsername(), request.getPassword()));
            
            UserDetails userDetails = userDetailsService.loadUserByUsername(request.getUsername());
            String token = jwtUtil.generateToken(userDetails);
            
            User user = userRepository.findByUsername(request.getUsername())
                    .orElseThrow(() -> new NotFoundException("User not found"));
            
            return new AuthResponse(token, user);
        } 
        catch (org.springframework.security.core.AuthenticationException e) {throw new BadRequestException("Invalid username or password");}
    }
    
    /* This method returns the current user. */
    public User getCurrentUser(String username) {return userRepository.findByUsername(username).orElseThrow(() -> new NotFoundException("User not found"));}
    
    @Transactional
    public void forgotPassword(ForgotPasswordRequest request) 
    {
        // Security: Check if email exists without throwing exception
        // This prevents email enumeration attacks
        if (!userRepository.existsByEmail(request.getEmail())) 
        {
            // Email doesn't exist, but return success anyway (security best practice)
            // Don't reveal whether the email is registered
            return;
        }
        
        // Email exists, proceed with password reset
        User user = userRepository.findByEmail(request.getEmail())
                .orElse(null); // Should never be null due to existsByEmail check above
        
        //Safe guard        
        if (user == null) {return;}
        
        // Invalidate any existing unused tokens for this user
        passwordResetTokenRepository.invalidateUserTokens(user.getId());
        
        // Generate reset token
        String resetToken = UUID.randomUUID().toString();
        
        // Calculate expiration time
        Instant expiresAt = Instant.now().plusSeconds(tokenExpirationHours * 3600L);
        
        // Store token in database
        PasswordResetToken tokenEntity = new PasswordResetToken(user, resetToken, expiresAt);
        passwordResetTokenRepository.save(tokenEntity);
        
        // Build reset URL
        String resetUrl = frontendUrl + "/reset-password?token=" + resetToken;
        
        // Send email (wrapped in try-catch to handle failures gracefully)
        try 
        {
            emailService.sendPasswordResetEmail(user.getEmail(), resetToken, resetUrl);
        } catch (Exception e) 
        {
            // Log error but don't fail the request
            // Reset token is already created, user can still use it
            System.err.println("Failed to send password reset email: " + e.getMessage());
        }
    }
    
    /* This method resets the password for a user. */
    @Transactional
    public void resetPassword(ResetPasswordRequest request) 
    {
        // Find token in database
        PasswordResetToken tokenEntity = passwordResetTokenRepository.findByToken(request.getToken())
                .orElseThrow(() -> new BadRequestException("Invalid or expired reset token"));
        
        if (!tokenEntity.isValid()) {throw new BadRequestException("Invalid or expired reset token");}
        
        User user = tokenEntity.getUser();
        
        validatePassword(request.getNewPassword());
        
        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        user.setUpdatedAt(Instant.now());
        userRepository.save(user);
        

        tokenEntity.setUsed(true);
        passwordResetTokenRepository.save(tokenEntity);
        
        // Invalidate any other unused tokens for this user
        passwordResetTokenRepository.invalidateUserTokens(user.getId());
    }
    

    /* This method resets the password for an admin user. */
    @Transactional
    public void adminResetPassword(AdminResetPasswordRequest request, String adminUsername) 
    {
        // Verify admin has ADMIN role
        User admin = userRepository.findByUsername(adminUsername)
                .orElseThrow(() -> new NotFoundException("Admin user not found"));
        
        if (!admin.hasRole("ADMIN")) 
        {
            throw new com.inventory.audit.common.ForbiddenException("Only administrators can reset passwords");
        }
        
        User user = userRepository.findByUsername(request.getUsername())
                .orElseThrow(() -> new NotFoundException("User not found: " + request.getUsername()));
        
        validatePassword(request.getNewPassword());
        
        user.setPasswordHash(passwordEncoder.encode(request.getNewPassword()));
        user.setUpdatedAt(Instant.now());
        userRepository.save(user);
    }
    
    /* This method validates the password. */
    private void validatePassword(String password) 
    {
        if (password == null || password.length() < 8) {throw new BadRequestException("Password must be at least 8 characters");}
        
        // Check for at least one letter and one number
        boolean hasLetter = password.chars().anyMatch(Character::isLetter);
        boolean hasDigit = password.chars().anyMatch(Character::isDigit);
        
        if (!hasLetter || !hasDigit) {throw new BadRequestException("Password must contain at least one letter and one number");}
    }
    
    /**
     * Scheduled task to clean up expired password reset tokens.
     * Runs daily at midnight.
     */
    @Scheduled(cron = "0 0 0 * * ?")
    @Transactional
    public void cleanupExpiredTokens() {passwordResetTokenRepository.deleteExpiredTokens(Instant.now());}
}

