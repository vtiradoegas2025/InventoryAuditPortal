package com.inventory.audit.inventory;

import jakarta.persistence.*;
import java.time.Instant;

/**
 * Represents an inventory item in the database.
 * This entity stores information about items including SKU, name, quantity, and location.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */
@Entity
@Table(name = "inventory_items", indexes = {
    @Index(name = "idx_sku", columnList = "sku"),
    @Index(name = "idx_location", columnList = "location"),
    @Index(name = "idx_updated_at", columnList = "updatedAt"),
    @Index(name = "idx_location_updated", columnList = "location,updatedAt")
})

/* This class is the inventory item. */
public class InventoryItem 
{

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Column(nullable = false, unique = true)
  private String sku;

  @Column(nullable = false)
  private String name;

  @Column(nullable = false)
  private Integer qty;

  @Column(nullable = false)
  private String location;

  @Column(nullable = false)
  private Instant updatedAt = Instant.now();

  public Long getId() { return id; }

  public String getSku() { return sku; }
  public void setSku(String sku) { this.sku = sku; }

  public String getName() { return name; }
  public void setName(String name) { this.name = name; }

  public Integer getQty() { return qty; }
  public void setQty(Integer qty) { this.qty = qty; }

  public String getLocation() { return location; }
  public void setLocation(String location) { this.location = location; }

  public Instant getUpdatedAt() { return updatedAt; }
  public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}