package com.azure.demo.orderservice.messaging;

import java.time.LocalDateTime;

/**
 * Order event for messaging
 */
public class OrderEvent {
    private Long orderId;
    private Long userId;
    private String eventType;
    private String status;
    private LocalDateTime timestamp;
    private String details;

    public OrderEvent() {
        this.timestamp = LocalDateTime.now();
    }

    public OrderEvent(Long orderId, Long userId, String eventType, String status) {
        this();
        this.orderId = orderId;
        this.userId = userId;
        this.eventType = eventType;
        this.status = status;
    }

    // Getters and setters
    public Long getOrderId() {
        return orderId;
    }

    public void setOrderId(Long orderId) {
        this.orderId = orderId;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getEventType() {
        return eventType;
    }

    public void setEventType(String eventType) {
        this.eventType = eventType;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDateTime getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(LocalDateTime timestamp) {
        this.timestamp = timestamp;
    }

    public String getDetails() {
        return details;
    }

    public void setDetails(String details) {
        this.details = details;
    }
}