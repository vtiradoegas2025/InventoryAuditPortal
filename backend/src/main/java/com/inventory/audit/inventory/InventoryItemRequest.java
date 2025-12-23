package com.inventory.audit.inventory;

import jakarta.validation.constraints.*;

/**
 * Request DTO for creating or updating inventory items.
 * Contains validation constraints for inventory item data.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */
public class InventoryItemRequest 
{
  @NotBlank 
  private String sku;
  
  @NotBlank 
  private String name;
  
  @NotNull 
  @Min(0) 
  private Integer qty;
  
  @NotBlank 
  private String location;
  
  // Getters and setters
  public String getSku() { return sku; }
  public void setSku(String sku) { this.sku = sku; }
  
  public String getName() { return name; }
  public void setName(String name) { this.name = name; }
  
  public Integer getQty() { return qty; }
  public void setQty(Integer qty) { this.qty = qty; }
  
  public String getLocation() { return location; }
  public void setLocation(String location) { this.location = location; }
}