package com.inventory.audit.inventory;

import com.inventory.audit.audit.AuditEventService;
import com.inventory.audit.common.BadRequestException;
import com.inventory.audit.common.NotFoundException;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.lang.NonNull;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Service class for managing inventory items.
 * Provides business logic for CRUD operations, searching, and batch operations on inventory items.
 * Automatically records audit events for all changes.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */
@Service
public class InventoryItemService 
{

  private final InventoryItemRepository repo;
  private final AuditEventService auditEventService;

  /* This method is the constructor for the inventory item service. */
  public InventoryItemService(InventoryItemRepository repo, AuditEventService auditEventService) 
  {
    this.repo = repo;
    this.auditEventService = auditEventService;
  }

  /* This method returns all the inventory items. */
  public Page<InventoryItem> list(@NonNull Pageable pageable) 
  {
    return repo.findAll(pageable);
  }

  /* This method returns the inventory item by id. */
  @Cacheable(value = "inventoryItems", key = "#id")
  public InventoryItem get(Long id) 
  {
    if (id == null) throw new BadRequestException("ID cannot be null");
    return repo.findById(id).orElseThrow(() -> new NotFoundException("Item not found"));
  }

  /* This method returns the inventory item by SKU. */
  @Cacheable(value = "inventoryItems", key = "'sku:' + #sku")
  public InventoryItem getBySku(String sku) 
  {
    if (sku == null || sku.isBlank()) {throw new BadRequestException("SKU cannot be null or empty");}
    
    return repo.findBySku(sku).orElseThrow(() -> new NotFoundException("Item not found with SKU: " + sku));
  }

  /* This method returns the inventory items by location. */
  public Page<InventoryItem> findByLocation(String location, @NonNull Pageable pageable) 
  {
    return repo.findByLocation(location, pageable);
  }

  /* This method returns the inventory items by SKU. */
  public Page<InventoryItem> searchBySku(String skuPattern, @NonNull Pageable pageable) 
  {
    return repo.findBySkuContainingIgnoreCase(skuPattern, pageable);
  }

  /* This method returns the inventory items by name. */
  public Page<InventoryItem> searchByName(String namePattern, @NonNull Pageable pageable) 
  {
    return repo.findByNameContainingIgnoreCase(namePattern, pageable);
  }

  /* This method creates a new inventory item. */
  @CacheEvict(value = "inventoryItems", allEntries = true)
  public InventoryItem create(InventoryItemRequest req, String userId) 
  {
    if (repo.existsBySku(req.getSku())) throw new BadRequestException("SKU already exists");

    InventoryItem item = new InventoryItem();
    item.setSku(req.getSku());
    item.setName(req.getName());
    item.setQty(req.getQty());
    item.setLocation(req.getLocation());
    item.setUpdatedAt(Instant.now());
    InventoryItem saved = repo.save(item);
    
    // Audit CREATE event
    String details = String.format("Created item: SKU=%s, Name=%s, Qty=%d, Location=%s", 
        saved.getSku(), saved.getName(), saved.getQty(), saved.getLocation());
    auditEventService.record("CREATE", "InventoryItem", saved.getId(), userId, details);
    
    return saved;
  }

  /* This method updates the inventory item by id. */
  @CacheEvict(value = "inventoryItems", allEntries = true)
  public InventoryItem update(Long id, InventoryItemRequest req, String userId) 
  {
    InventoryItem item = get(id);
    
    // Optimized: Only check if SKU is being changed and use existsBySku for better performance
    if (!item.getSku().equals(req.getSku())) 
    {
      if (repo.existsBySku(req.getSku())) 
      {
        // Double-check it's not the same item
        InventoryItem existing = repo.findBySku(req.getSku()).orElse(null);
        if (existing != null && !existing.getId().equals(id)) {throw new BadRequestException("SKU already exists on another item");}
      }
      item.setSku(req.getSku());
    }
    
    String oldDetails = String.format("SKU=%s, Name=%s, Qty=%d, Location=%s", 
        item.getSku(), item.getName(), item.getQty(), item.getLocation());
    
    item.setName(req.getName());
    item.setQty(req.getQty());
    item.setLocation(req.getLocation());
    item.setUpdatedAt(Instant.now());
    InventoryItem saved = repo.save(item);
    
    // Audit UPDATE event
    String newDetails = String.format("SKU=%s, Name=%s, Qty=%d, Location=%s", 
        saved.getSku(), saved.getName(), saved.getQty(), saved.getLocation());
    String auditDetails = String.format("Old: %s | New: %s", oldDetails, newDetails);
    auditEventService.record("UPDATE", "InventoryItem", saved.getId(), userId, auditDetails);
    
    return saved;
  }

  /* This method deletes the inventory item by id. */
  @CacheEvict(value = "inventoryItems", allEntries = true)
  public void delete(Long id, String userId) 
  {
    if (id == null) throw new BadRequestException("ID cannot be null");
    
    // Get item before delete for audit
    InventoryItem item = get(id);
    String details = String.format("Deleted item: SKU=%s, Name=%s, Qty=%d, Location=%s", 
        item.getSku(), item.getName(), item.getQty(), item.getLocation());
    
    repo.deleteById(id);
    
    // Audit DELETE event (use id before it's deleted)
    auditEventService.record("DELETE", "InventoryItem", id, userId, details);
  }

  /* This method creates a new inventory item batch. */
  @Transactional 
  @CacheEvict(value = "inventoryItems", allEntries = true)
  @SuppressWarnings("null")
  public List<InventoryItem> createBatch(List<InventoryItemRequest> requests, String userId) 
  {
    List<InventoryItem> items = requests.stream()
        .map(req -> {
          InventoryItem item = new InventoryItem();
          item.setSku(req.getSku());
          item.setName(req.getName());
          item.setQty(req.getQty());
          item.setLocation(req.getLocation());
          item.setUpdatedAt(Instant.now());
          return item;
        })
        .collect(Collectors.toList());
    
    List<InventoryItem> saved = repo.saveAll(items);
    
    // Batch audit events
    saved.forEach(item -> 
    {
      String details = String.format("Created item: SKU=%s", item.getSku());
      auditEventService.record("CREATE", "InventoryItem", item.getId(), userId, details);
    });
    
    return saved;
  }

  public List<Object[]> getLocationSummary() {return repo.getLocationSummary();}
}