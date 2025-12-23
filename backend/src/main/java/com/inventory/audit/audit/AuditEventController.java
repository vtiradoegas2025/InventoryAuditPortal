package com.inventory.audit.audit;

import com.inventory.audit.common.BadRequestException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.lang.NonNull;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * REST controller for audit event operations.
 * Provides endpoints for querying and creating audit events with various filtering options.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */
@RestController
@RequestMapping("/api/audit-events")
public class AuditEventController 
{

  private static final Set<String> VALID_SORT_FIELDS = Stream.of(
      "id", "eventType", "entityType", "entityId", "userId", "timestamp"
  ).collect(Collectors.toSet());

  @Autowired
  private AuditEventService service;

  /* This method validates the pagination parameters. */
  private void validatePaginationParams(int page, int size) 
  {
    if (page < 0) {throw new BadRequestException("Page number must be non-negative");}
    if (size <= 0) {throw new BadRequestException("Page size must be greater than 0");}
    if (size > 1000) {throw new BadRequestException("Page size cannot exceed 1000");}
  }

  /* This method validates the sort field. */
  private void validateSortField(String sortBy) 
  {
    if (sortBy != null && !VALID_SORT_FIELDS.contains(sortBy)) 
    {
      throw new BadRequestException("Invalid sort field: " + sortBy + ". Valid fields are: " + 
          String.join(", ", VALID_SORT_FIELDS));
    }
  }

  /* This method returns all the audit events. */
  @GetMapping
  public ResponseEntity<Page<AuditEvent>> getAllEvents(
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "50") int size,
      @RequestParam(defaultValue = "timestamp") String sortBy,
      @RequestParam(defaultValue = "DESC") String sortDir) 
  {
    validatePaginationParams(page, size);
    validateSortField(sortBy);
    
    Sort sort = sortDir.equalsIgnoreCase("ASC") 
        ? Sort.by(sortBy).ascending() 
        : Sort.by(sortBy).descending();
    Pageable pageable = PageRequest.of(page, size, sort);
    Page<AuditEvent> events = service.list(pageable);
    return ResponseEntity.ok(events);
  }

  /* This method returns the audit event by id. */
  @GetMapping("/{id}")
  public ResponseEntity<AuditEvent> getEventById(@PathVariable @NonNull Long id) 
  {
    AuditEvent event = service.get(id);
    return ResponseEntity.ok(event);
  }

  /* This method creates a new audit event. */
  @PostMapping
  public ResponseEntity<AuditEvent> createEvent(@Valid @RequestBody AuditEventRequest request) 
  {
    AuditEvent event = service.create(request);
    return ResponseEntity.status(HttpStatus.CREATED).body(event);
  }

  /* This method returns the audit events by entity type and entity id. */
  @GetMapping("/entity/{entityType}/{entityId}")
  public ResponseEntity<Page<AuditEvent>> getEventsByEntity(
      @PathVariable String entityType,
      @PathVariable Long entityId,
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "50") int size,
      @RequestParam(defaultValue = "timestamp") String sortBy,
      @RequestParam(defaultValue = "DESC") String sortDir) 
  {
    validatePaginationParams(page, size);
    validateSortField(sortBy);
    
    Sort sort = sortDir.equalsIgnoreCase("ASC") 
        ? Sort.by(sortBy).ascending() 
        : Sort.by(sortBy).descending();
    Pageable pageable = PageRequest.of(page, size, sort);
    Page<AuditEvent> events = service.findByEntity(entityType, entityId, pageable);
    return ResponseEntity.ok(events);
  }

  /* This method returns the audit events by entity type. */
  @GetMapping("/entity-type/{entityType}")
  public ResponseEntity<Page<AuditEvent>> getEventsByEntityType(
      @PathVariable String entityType,
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "50") int size,
      @RequestParam(defaultValue = "timestamp") String sortBy,
      @RequestParam(defaultValue = "DESC") String sortDir) 
  {
    validatePaginationParams(page, size);
    validateSortField(sortBy);
    
    Sort sort = sortDir.equalsIgnoreCase("ASC") 
        ? Sort.by(sortBy).ascending() 
        : Sort.by(sortBy).descending();
    Pageable pageable = PageRequest.of(page, size, sort);
    Page<AuditEvent> events = service.findByEntityType(entityType, pageable);
    return ResponseEntity.ok(events);
  }

  /* This method returns the audit events by event type. */
  @GetMapping("/event-type/{eventType}")
  public ResponseEntity<Page<AuditEvent>> getEventsByEventType(
      @PathVariable String eventType,
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "50") int size,
      @RequestParam(defaultValue = "timestamp") String sortBy,
      @RequestParam(defaultValue = "DESC") String sortDir) 
  {
    validatePaginationParams(page, size);
    validateSortField(sortBy);
    
    Sort sort = sortDir.equalsIgnoreCase("ASC") 
        ? Sort.by(sortBy).ascending() 
        : Sort.by(sortBy).descending();
    Pageable pageable = PageRequest.of(page, size, sort);
    Page<AuditEvent> events = service.findByEventType(eventType, pageable);
    return ResponseEntity.ok(events);
  }

  /* This method returns the audit events by user id. */
  @GetMapping("/user/{userId}")
  public ResponseEntity<Page<AuditEvent>> getEventsByUserId(
      @PathVariable String userId,
      @RequestParam(defaultValue = "0") int page,
      @RequestParam(defaultValue = "50") int size,
      @RequestParam(defaultValue = "timestamp") String sortBy,
      @RequestParam(defaultValue = "DESC") String sortDir) 
  {
    validatePaginationParams(page, size);
    validateSortField(sortBy);
    
    Sort sort = sortDir.equalsIgnoreCase("ASC") 
        ? Sort.by(sortBy).ascending() 
        : Sort.by(sortBy).descending();
    Pageable pageable = PageRequest.of(page, size, sort);
    Page<AuditEvent> events = service.findByUserId(userId, pageable);
    return ResponseEntity.ok(events);
  }
}

