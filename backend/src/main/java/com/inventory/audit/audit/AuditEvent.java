package com.inventory.audit.audit;

import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "audit_events", indexes = {
    @Index(name = "idx_entity_type_id", columnList = "entityType,entityId"),
    @Index(name = "idx_user_id", columnList = "userId"),
    @Index(name = "idx_timestamp", columnList = "timestamp"),
    @Index(name = "idx_event_type", columnList = "eventType")
})
/**
 * Represents an audit event in the database.
 * This entity tracks all changes made to entities in the system, including
 * CREATE, UPDATE, DELETE, and READ operations.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */
public class AuditEvent 
{

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(nullable = false)
  private String eventType; // CREATE, UPDATE, DELETE, READ

  @Column(nullable = false)
  private String entityType; // INVENTORY_ITEM, etc.

  @Column(nullable = false)
  private Long entityId;

  @Column
  private String userId; // Optional - who performed the action

  @Column(columnDefinition = "TEXT")
  private String details; // JSON or text details about the change

  @Column(nullable = false)
  private Instant timestamp = Instant.now();

  public Long getId() { return id; }

  public String getEventType() { return eventType; }
  public void setEventType(String eventType) { this.eventType = eventType; }

  public String getEntityType() { return entityType; }
  public void setEntityType(String entityType) { this.entityType = entityType; }

  public Long getEntityId() { return entityId; }
  public void setEntityId(Long entityId) { this.entityId = entityId; }

  public String getUserId() { return userId; }
  public void setUserId(String userId) { this.userId = userId; }

  public String getDetails() { return details; }
  public void setDetails(String details) { this.details = details; }

  public Instant getTimestamp() { return timestamp; }
  public void setTimestamp(Instant timestamp) { this.timestamp = timestamp; }
}

