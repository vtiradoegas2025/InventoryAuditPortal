package com.inventory.audit.user;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.Optional;

/**
 * Repository interface for PasswordResetToken entities.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */
@Repository
public interface PasswordResetTokenRepository extends JpaRepository<PasswordResetToken, Long> 
{
    
    Optional<PasswordResetToken> findByToken(String token);
    
    @Modifying
    @Query("DELETE FROM PasswordResetToken p WHERE p.expiresAt < ?1")
    void deleteExpiredTokens(Instant now);
    
    @Modifying
    @Query("UPDATE PasswordResetToken p SET p.used = true WHERE p.user.id = ?1 AND p.used = false")
    void invalidateUserTokens(Long userId);
}

