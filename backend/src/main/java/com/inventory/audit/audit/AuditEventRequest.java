package com.inventory.audit.audit;

import jakarta.validation.constraints.*;

/**
 * Request DTO for creating audit events.
 * Contains validation constraints for audit event data.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */

/* This class is the request for the audit events. */
public class AuditEventRequest 
{
  
  @NotBlank
  private String eventType;
  
  @NotBlank
  private String entityType;
  
  @NotNull
  private Long entityId;
  
  private String userId;
  
  private String details;
  
  // Getters and setters
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
}

