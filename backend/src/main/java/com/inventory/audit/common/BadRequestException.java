package com.inventory.audit.common;

/**
 * Exception thrown when a bad request is made to the API.
 * Typically used for validation errors or invalid input parameters.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */
public class BadRequestException extends RuntimeException 
{
  public BadRequestException(String message) { super(message); }
}