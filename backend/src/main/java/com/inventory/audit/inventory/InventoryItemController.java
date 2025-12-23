package com.inventory.audit.inventory;

import com.inventory.audit.common.BadRequestException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.lang.NonNull;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import jakarta.validation.Valid;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * REST controller for inventory item operations.
 * Provides endpoints for CRUD operations, searching, and location-based queries on inventory items.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */
@RestController
@RequestMapping("/api/inventory")
public class InventoryItemController 
{
    
    private static final Set<String> VALID_SORT_FIELDS = Stream.of(
        "id", "sku", "name", "qty", "location", "updatedAt"
    ).collect(Collectors.toSet());
    
    @Autowired
    private InventoryItemService service;
    
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
            throw new BadRequestException("Invalid sort field: " + sortBy + ". Valid fields are: " + String.join(", ", VALID_SORT_FIELDS));
        }
    }
    
    /* This method gets the current authenticated username. */
    private String getCurrentUsername() 
    {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.isAuthenticated()) 
        {
            return authentication.getName();
        }
        return null;
    }
    
    /* This method returns all the inventory items. */
    @GetMapping
    public ResponseEntity<Page<InventoryItem>> getAllItems(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size,
            @RequestParam(defaultValue = "updatedAt") String sortBy,
            @RequestParam(defaultValue = "DESC") String sortDir) 
    {
        validatePaginationParams(page, size);
        validateSortField(sortBy);
        
        Sort sort = sortDir.equalsIgnoreCase("ASC") 
            ? Sort.by(sortBy).ascending() 
            : Sort.by(sortBy).descending();
        Pageable pageable = PageRequest.of(page, size, sort);
        Page<InventoryItem> items = service.list(pageable);
        return ResponseEntity.ok(items);
    }
    
    /* This method returns the inventory items by location. */
    @GetMapping("/location/{location}")
    public ResponseEntity<Page<InventoryItem>> getItemsByLocation(
            @PathVariable String location,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size,
            @RequestParam(defaultValue = "updatedAt") String sortBy,
            @RequestParam(defaultValue = "DESC") String sortDir) 
    {
        validatePaginationParams(page, size);
        validateSortField(sortBy);
        
        Sort sort = sortDir.equalsIgnoreCase("ASC") 
            ? Sort.by(sortBy).ascending() 
            : Sort.by(sortBy).descending();
        Pageable pageable = PageRequest.of(page, size, sort);
        Page<InventoryItem> items = service.findByLocation(location, pageable);
        return ResponseEntity.ok(items);
    }
    
    /* This method returns the inventory items by SKU. */
    @GetMapping("/search/sku")
    public ResponseEntity<Page<InventoryItem>> searchBySku(
            @RequestParam String pattern,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) 
    {
        validatePaginationParams(page, size);
        Pageable pageable = PageRequest.of(page, size);
        Page<InventoryItem> items = service.searchBySku(pattern, pageable);
        return ResponseEntity.ok(items);
    }
    
    /* This method returns the inventory items by name. */
    @GetMapping("/search/name")
    public ResponseEntity<Page<InventoryItem>> searchByName(
            @RequestParam String pattern,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "50") int size) 
    {
        validatePaginationParams(page, size);
        Pageable pageable = PageRequest.of(page, size);
        Page<InventoryItem> items = service.searchByName(pattern, pageable);
        return ResponseEntity.ok(items);
    }
    
    /* This method returns the location summary. */
    @GetMapping("/summary/location")
    public ResponseEntity<List<Object[]>> getLocationSummary() 
    {
        List<Object[]> summary = service.getLocationSummary();
        return ResponseEntity.ok(summary);
    }
    
    /* This method returns the inventory item by id. */
    @GetMapping("/{id}")
    public ResponseEntity<InventoryItem> getItemById(@PathVariable @NonNull Long id) 
    {
        InventoryItem item = service.get(id);
        return ResponseEntity.ok(item);
    }
    
    /* This method returns the inventory item by SKU. */
    @GetMapping("/sku/{sku}")
    public ResponseEntity<InventoryItem> getItemBySku(@PathVariable String sku) 
    {
        InventoryItem item = service.getBySku(sku);
        return ResponseEntity.ok(item);
    }
    
    /* This method creates a new inventory item. */
    @PostMapping
    public ResponseEntity<InventoryItem> createItem(
            @Valid @RequestBody InventoryItemRequest request) 
    {
        InventoryItem item = service.create(request, getCurrentUsername());
        return ResponseEntity.status(HttpStatus.CREATED).body(item);
    }
    
    /* This method creates a new inventory item batch. */
    @PostMapping("/batch")
    public ResponseEntity<List<InventoryItem>> createBatch(
            @Valid @RequestBody List<InventoryItemRequest> requests) 
    {
        List<InventoryItem> items = service.createBatch(requests, getCurrentUsername());
        return ResponseEntity.status(HttpStatus.CREATED).body(items);
    }
    
    /* This method updates the inventory item by id. */
    @PutMapping("/{id}")
    public ResponseEntity<InventoryItem> updateItem(
            @PathVariable @NonNull Long id,
            @Valid @RequestBody InventoryItemRequest request) 
    {
        InventoryItem item = service.update(id, request, getCurrentUsername());
        return ResponseEntity.ok(item);
    }
    
    /* This method deletes the inventory item by id. */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteItem(@PathVariable @NonNull Long id) 
    {
        service.delete(id, getCurrentUsername());
        return ResponseEntity.noContent().build();
    }
}