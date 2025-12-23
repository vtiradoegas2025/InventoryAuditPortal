package com.inventory.audit.common;

import java.time.Instant;

/**
 * Record representing an API error response.
 * Contains error details including timestamp, HTTP status, error type, message, and request path.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */

public record ApiError( Instant timestamp, int status, String error, String message, String path){}