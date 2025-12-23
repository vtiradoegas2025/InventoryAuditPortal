package com.inventory.audit.common;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.*;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;

import java.time.Instant;

/**
 * Global exception handler for the application.
 * Handles exceptions and converts them to standardized API error responses.
 * 
 * @author Victor Tiradoegas
 * @version 1.0
 */

/* This class is the global exception handler. */
@RestControllerAdvice
public class GlobalExceptionHandler 
{

  /* This method handles the not found exception. */
  @ExceptionHandler(NotFoundException.class)
  public ResponseEntity<ApiError> handleNotFound(NotFoundException ex, HttpServletRequest req) 
  {
    return build(HttpStatus.NOT_FOUND, ex.getMessage(), req.getRequestURI());
  }

  /* This method handles the bad request exception. */
  @ExceptionHandler(BadRequestException.class)
  public ResponseEntity<ApiError> handleBadRequest(BadRequestException ex, HttpServletRequest req) 
  {
    return build(HttpStatus.BAD_REQUEST, ex.getMessage(), req.getRequestURI());
  }

  /* This method handles the method argument not valid exception. */
  @ExceptionHandler(MethodArgumentNotValidException.class)
  public ResponseEntity<ApiError> handleValidation(MethodArgumentNotValidException ex, HttpServletRequest req) 
  {
    String msg = ex.getBindingResult().getFieldErrors().stream()
        .findFirst()
        .map(fe -> fe.getField() + " " + fe.getDefaultMessage())
        .orElse("Validation error");
    return build(HttpStatus.BAD_REQUEST, msg, req.getRequestURI());
  }

  /* This method handles the unauthorized exception. */
  @ExceptionHandler(UnauthorizedException.class)
  public ResponseEntity<ApiError> handleUnauthorized(UnauthorizedException ex, HttpServletRequest req) 
  {
    return build(HttpStatus.UNAUTHORIZED, ex.getMessage(), req.getRequestURI());
  }

  /* This method handles the forbidden exception. */
  @ExceptionHandler(ForbiddenException.class)
  public ResponseEntity<ApiError> handleForbidden(ForbiddenException ex, HttpServletRequest req) 
  {
    return build(HttpStatus.FORBIDDEN, ex.getMessage(), req.getRequestURI());
  }

  /* This method builds the API error response. */
  private ResponseEntity<ApiError> build(HttpStatus status, String message, String path) 
  {
    ApiError body = new ApiError(Instant.now(), status.value(), status.getReasonPhrase(), message, path);
    return ResponseEntity.status(status).body(body);
  }
}