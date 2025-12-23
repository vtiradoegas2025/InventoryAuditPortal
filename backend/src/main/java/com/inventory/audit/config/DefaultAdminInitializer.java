package com.inventory.audit.config;

import com.inventory.audit.user.Role;
import com.inventory.audit.user.RoleRepository;
import com.inventory.audit.user.User;
import com.inventory.audit.user.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.time.Instant;

/**
 * Initializes default admin user on application startup.
 * Creates an admin user if one doesn't already exist.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */
@Component
public class DefaultAdminInitializer implements CommandLineRunner 
{
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private RoleRepository roleRepository;
    
    @Autowired
    private PasswordEncoder passwordEncoder;
    
    @Value("${app.admin.email:vtiradoegas@gmail.com}")
    private String adminEmail;
    
    @Value("${app.admin.username:vtiradoegas}")
    private String adminUsername;
    
    @Value("${app.admin.password:walmart2002!}")
    private String adminPassword;
    
    @Value("${app.admin.enabled:true}")
    private boolean adminEnabled;
    
    @Override
    public void run(String... args) throws Exception 
    {
        // Check if admin creation is enabled
        if (!adminEnabled) 
        {
            System.out.println("Admin user creation is disabled (app.admin.enabled=false)");
            return;
        }
        
        // Check if admin user already exists (by email or username)
        if (userRepository.existsByEmail(adminEmail) || userRepository.existsByUsername(adminUsername)) 
        {
            System.out.println("Default admin user already exists: " + adminEmail);
            return;
        }
        
        // Get ADMIN role
        Role adminRole = roleRepository.findByName("ADMIN")
                .orElseThrow(() -> new RuntimeException("ADMIN role not found in database"));
        
        // Create admin user
        User admin = new User();
        admin.setUsername(adminUsername);
        admin.setEmail(adminEmail);
        admin.setPasswordHash(passwordEncoder.encode(adminPassword));
        admin.setEnabled(true);
        admin.setCreatedAt(Instant.now());
        admin.setUpdatedAt(Instant.now());
        admin.addRole(adminRole);
        
        userRepository.save(admin);
        System.out.println("Default admin user created successfully:");
        System.out.println("  Username: " + adminUsername);
        System.out.println("  Email: " + adminEmail);
        System.out.println("  Note: Password is configured via app.admin.password (not logged for security)");
    }
}

