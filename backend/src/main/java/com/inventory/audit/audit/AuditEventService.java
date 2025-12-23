package com.inventory.audit.audit;

import com.inventory.audit.common.BadRequestException;
import com.inventory.audit.common.NotFoundException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Service;

import java.time.Instant;

/**
 * Service class for managing audit events.
 * Provides business logic for creating, querying, and filtering audit events.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */

/* This class is the service for the audit events. */
@Service
public class AuditEventService 
{

  /* These are the methods for the audit events. */
  private final AuditEventRepository repo;

  public AuditEventService(AuditEventRepository repo) {this.repo = repo;}

  public Page<AuditEvent> list(@NonNull Pageable pageable) {return repo.findAll(pageable);}

  public AuditEvent get(Long id) 
  {
    if (id == null) throw new BadRequestException("ID cannot be null");
    return repo.findById(id).orElseThrow(() -> new NotFoundException("Audit event not found"));
  }

  /* This method creates a new audit event. */
  public AuditEvent create(AuditEventRequest req) 
  {
    AuditEvent event = new AuditEvent();
    event.setEventType(req.getEventType());
    event.setEntityType(req.getEntityType());
    event.setEntityId(req.getEntityId());
    event.setUserId(req.getUserId());
    event.setDetails(req.getDetails());
    event.setTimestamp(Instant.now());
    return repo.save(event);
  }

  /* This method records a new audit event. */
  public AuditEvent record(String eventType, String entityType, Long entityId, String userId, String details) 
  {
    if (eventType == null || eventType.isBlank()) {throw new BadRequestException("Event type cannot be null or empty");}
    if (entityType == null || entityType.isBlank()) {throw new BadRequestException("Entity type cannot be null or empty");}
    if (entityId == null) {throw new BadRequestException("Entity ID cannot be null");}
    
    AuditEvent event = new AuditEvent();
    event.setEventType(eventType);
    event.setEntityType(entityType);
    event.setEntityId(entityId);
    event.setUserId(userId); // Can be null
    event.setDetails(details); // Can be null
    event.setTimestamp(Instant.now());
    return repo.save(event);
  }

  /* This method finds the audit events by entity type and entity id. */
  public Page<AuditEvent> findByEntity(String entityType, Long entityId, @NonNull Pageable pageable) 
  {
    if (entityType == null || entityType.isBlank()) {throw new BadRequestException("Entity type cannot be null or empty");}
    if (entityId == null) {throw new BadRequestException("Entity ID cannot be null");}

    return repo.findByEntityTypeAndEntityId(entityType, entityId, pageable);
  }

  /* This method finds the audit events by entity type. */
  public Page<AuditEvent> findByEntityType(String entityType, @NonNull Pageable pageable) 
  {
    if (entityType == null || entityType.isBlank()) {throw new BadRequestException("Entity type cannot be null or empty");}

    return repo.findByEntityType(entityType, pageable);
  }

  /* This method finds the audit events by event type. */
  public Page<AuditEvent> findByEventType(String eventType, @NonNull Pageable pageable) 
  {
    if (eventType == null || eventType.isBlank()) {throw new BadRequestException("Event type cannot be null or empty");}

    return repo.findByEventType(eventType, pageable);
  }

  /* This method finds the audit events by user id. */
  public Page<AuditEvent> findByUserId(String userId, @NonNull Pageable pageable) 
  {
    if (userId == null || userId.isBlank()) {throw new BadRequestException("User ID cannot be null or empty");}

    return repo.findByUserId(userId, pageable);
  }
}

