package com.azure.demo.orderservice.messaging;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Service;

/**
 * Service for publishing order events to Azure Service Bus
 * This is a placeholder implementation that logs events when Azure Service Bus is not available
 */
@Service
@Profile("azure")
public class OrderEventPublisher {

    private static final Logger logger = LoggerFactory.getLogger(OrderEventPublisher.class);

    @Autowired
    private ObjectMapper objectMapper;

    /**
     * Publishes order created event
     */
    public void publishOrderCreated(OrderEvent orderEvent) {
        try {
            String message = objectMapper.writeValueAsString(orderEvent);
            logger.info("Order created event would be published to Azure Service Bus: {}", message);
            // TODO: Implement actual Azure Service Bus publishing when Spring Cloud Azure is properly configured
        } catch (JsonProcessingException e) {
            logger.error("Failed to serialize order event: {}", orderEvent.getOrderId(), e);
        }
    }

    /**
     * Publishes order status changed event
     */
    public void publishOrderStatusChanged(OrderEvent orderEvent) {
        try {
            String message = objectMapper.writeValueAsString(orderEvent);
            logger.info("Order status changed event would be published to Azure Service Bus: {}", message);
            // TODO: Implement actual Azure Service Bus publishing when Spring Cloud Azure is properly configured
        } catch (JsonProcessingException e) {
            logger.error("Failed to serialize order event: {}", orderEvent.getOrderId(), e);
        }
    }
}