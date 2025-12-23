package com.inventory.audit.inventory;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.util.Optional;

/**
 * Repository interface for inventory items.
 * Provides data access methods for querying and managing inventory items in the database.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */
public interface InventoryItemRepository extends JpaRepository<InventoryItem, Long> 
{
  Optional<InventoryItem> findBySku(String sku);
  boolean existsBySku(String sku);
  
  // Paginated queries
  Page<InventoryItem> findByLocation(String location, Pageable pageable);
  Page<InventoryItem> findBySkuContainingIgnoreCase(String skuPattern, Pageable pageable);
  Page<InventoryItem> findByNameContainingIgnoreCase(String namePattern, Pageable pageable);
  
  // Optimized count query
  @Query("SELECT COUNT(i) FROM InventoryItem i WHERE i.location = :location")
  long countByLocation(@Param("location") String location);
  
  // Location summary projection
  @Query("SELECT i.location as location, COUNT(i) as count, SUM(i.qty) as totalQty FROM InventoryItem i GROUP BY i.location")
  java.util.List<Object[]> getLocationSummary();
}