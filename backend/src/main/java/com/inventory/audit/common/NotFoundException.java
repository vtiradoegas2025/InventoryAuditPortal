package com.inventory.audit.common;

/**
 * Exception thrown when a requested resource is not found.
 * Typically used when an entity with the given ID does not exist.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */
public class NotFoundException extends RuntimeException
{
  public NotFoundException(String message) { super(message); }
}