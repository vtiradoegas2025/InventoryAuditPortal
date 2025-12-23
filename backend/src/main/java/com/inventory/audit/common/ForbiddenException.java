package com.inventory.audit.common;

/**
 * Exception thrown when a user is authenticated but doesn't have permission to perform an action.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */
public class ForbiddenException extends RuntimeException 
{
    
    public ForbiddenException(String message) {super(message);}
    
    public ForbiddenException(String message, Throwable cause) {super(message, cause);}
}

