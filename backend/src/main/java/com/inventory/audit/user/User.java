package com.inventory.audit.user;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import java.time.Instant;
import java.util.HashSet;
import java.util.Set;

/**
 * Represents a user in the system.
 * Users can have multiple roles that define their permissions.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */
@Entity
@Table(name = "users", indexes = {
    @Index(name = "idx_users_username", columnList = "username"),
    @Index(name = "idx_users_email", columnList = "email")
})

/* This class is the User. */
public class User 
{
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false, unique = true, length = 100)
    private String username;
    
    @Column(nullable = false, unique = true)
    private String email;
    
    @Column(nullable = false, name = "password_hash")
    private String passwordHash;
    
    @Column(nullable = false)
    private Boolean enabled = true;
    
    @Column(nullable = false, name = "created_at")
    private Instant createdAt = Instant.now();
    
    @Column(nullable = false, name = "updated_at")
    private Instant updatedAt = Instant.now();
    
    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(
        name = "user_roles",
        joinColumns = @JoinColumn(name = "user_id"),
        inverseJoinColumns = @JoinColumn(name = "role_id")
    )
    private Set<Role> roles = new HashSet<>();
    
    /* This constructor is the default constructor. */
    public User() {}
    
    /* This constructor is the constructor for the User. */
    public User(String username, String email, String passwordHash) {this.username = username; this.email = email; this.passwordHash = passwordHash;}
    
    /* These methods are the getters and setters for the User. */
    public Long getId() {return id;}
    
    public void setId(Long id) {this.id = id;}
    
    public String getUsername() {return username;}
    
    public void setUsername(String username) {this.username = username;}
    
    public String getEmail() {return email;}
    
    public void setEmail(String email) {this.email = email;}
    
    @JsonIgnore
    public String getPasswordHash() {return passwordHash;}
    
    public void setPasswordHash(String passwordHash) {this.passwordHash = passwordHash;}
    
    public Boolean getEnabled() {return enabled;}
    
    public void setEnabled(Boolean enabled) {this.enabled = enabled;}
    
    public Instant getCreatedAt() {return createdAt;}
    
    public void setCreatedAt(Instant createdAt) {this.createdAt = createdAt;}
    
    public Instant getUpdatedAt() {return updatedAt;}
    
    public void setUpdatedAt(Instant updatedAt) {this.updatedAt = updatedAt;}
    
    public Set<Role> getRoles() {return roles;}
    
    public void setRoles(Set<Role> roles) {this.roles = roles;}
    
    public void addRole(Role role) {this.roles.add(role);}
    
    public boolean hasRole(String roleName) {return roles.stream().anyMatch(role -> role.getName().equals(roleName));}
}

