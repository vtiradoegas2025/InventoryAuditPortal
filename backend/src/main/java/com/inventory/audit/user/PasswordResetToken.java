package com.inventory.audit.user;

import jakarta.persistence.*;
import java.time.Instant;

/**
 * Entity representing a password reset token.
 * Tokens expire after a configured time period.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */
@Entity
@Table(name = "password_reset_tokens", indexes = 
{
    @Index(name = "idx_password_reset_tokens_token", columnList = "token"),
    @Index(name = "idx_password_reset_tokens_user_id", columnList = "user_id"),
    @Index(name = "idx_password_reset_tokens_expires_at", columnList = "expires_at")
})

public class PasswordResetToken 
{
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    
    @Column(nullable = false, unique = true)
    private String token;
    
    @Column(nullable = false, name = "expires_at")
    private Instant expiresAt;
    
    @Column(nullable = false)
    private Boolean used = false;
    
    @Column(nullable = false, name = "created_at")
    private Instant createdAt = Instant.now();
    
    /* This constructor is the default constructor. */
    public PasswordResetToken() {}
    
    /* This constructor is the constructor for the PasswordResetToken. */
    public PasswordResetToken(User user, String token, Instant expiresAt) 
    {
        this.user = user;
        this.token = token;
        this.expiresAt = expiresAt;
    }
    
    /* These methods are the getters and setters for the PasswordResetToken. */
    public Long getId() {return id;}
    
    public void setId(Long id) {this.id = id;}
    
    public User getUser() {return user;}
    
    public void setUser(User user) {this.user = user;}
    
    public String getToken() {return token;}
    
    public void setToken(String token) {this.token = token;}
    
    public Instant getExpiresAt() {return expiresAt;}
    
    public void setExpiresAt(Instant expiresAt) {this.expiresAt = expiresAt;}
    
    public Boolean getUsed() {return used;}
    
    public void setUsed(Boolean used) {this.used = used;}
    
    public Instant getCreatedAt() {return createdAt;}
    
    public void setCreatedAt(Instant createdAt) {this.createdAt = createdAt;}
    
    public boolean isExpired() {return Instant.now().isAfter(expiresAt);}
    
    public boolean isValid() {return !used && !isExpired();}
}

