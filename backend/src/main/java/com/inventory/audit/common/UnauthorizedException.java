package com.inventory.audit.common;

/**
 * Exception thrown when a user is not authenticated.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */
public class UnauthorizedException extends RuntimeException 
{
    
    public UnauthorizedException(String message) {super(message);}
    
    public UnauthorizedException(String message, Throwable cause) {super(message, cause);}
}

