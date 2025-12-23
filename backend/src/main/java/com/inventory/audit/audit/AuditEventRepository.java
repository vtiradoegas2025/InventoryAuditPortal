package com.inventory.audit.audit;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

/**
 * Repository interface for audit events.
 * Provides data access methods for querying and filtering audit events in the database.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */

/* This interface is the repository for the audit events. */
public interface AuditEventRepository extends JpaRepository<AuditEvent, Long> 
{
  // Paginated queries
  Page<AuditEvent> findByEntityTypeAndEntityId(String entityType, Long entityId, Pageable pageable);
  Page<AuditEvent> findByEntityType(String entityType, Pageable pageable);
  Page<AuditEvent> findByEventType(String eventType, Pageable pageable);
  Page<AuditEvent> findByUserId(String userId, Pageable pageable);
}

