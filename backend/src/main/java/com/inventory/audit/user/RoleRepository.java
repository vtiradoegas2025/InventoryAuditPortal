package com.inventory.audit.user;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

/**
 * Repository interface for Role entities.
 * Provides data access methods for role operations.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */
@Repository
public interface RoleRepository extends JpaRepository<Role, Long>{Optional<Role> findByName(String name);}

