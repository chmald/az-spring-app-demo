package com.azure.demo.orderservice.service;

import com.azure.demo.orderservice.client.ProductServiceClient;
import com.azure.demo.orderservice.client.UserServiceClient;
import com.azure.demo.orderservice.dto.CreateOrderRequest;
import com.azure.demo.orderservice.dto.ProductDto;
import com.azure.demo.orderservice.dto.UserDto;
import com.azure.demo.orderservice.model.Order;
import com.azure.demo.orderservice.model.OrderItem;
import com.azure.demo.orderservice.model.OrderStatus;
import com.azure.demo.orderservice.repository.OrderRepository;
import feign.FeignException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Service
public class OrderService {
    
    private final OrderRepository orderRepository;
    private final UserServiceClient userServiceClient;
    private final ProductServiceClient productServiceClient;
    
    @Autowired
    public OrderService(OrderRepository orderRepository, 
                       UserServiceClient userServiceClient,
                       ProductServiceClient productServiceClient) {
        this.orderRepository = orderRepository;
        this.userServiceClient = userServiceClient;
        this.productServiceClient = productServiceClient;
    }
    
    public List<Order> getAllOrders() {
        return orderRepository.findAll();
    }
    
    public Optional<Order> getOrderById(Long id) {
        return orderRepository.findById(id);
    }
    
    public List<Order> getOrdersByUserId(Long userId) {
        return orderRepository.findByUserId(userId);
    }
    
    public List<Order> getOrdersByStatus(OrderStatus status) {
        return orderRepository.findByStatus(status);
    }
    
    @Transactional
    public Order createOrder(CreateOrderRequest request) {
        // Validate user exists
        try {
            UserDto user = userServiceClient.getUserById(request.getUserId());
            if (user == null) {
                throw new RuntimeException("User not found with id: " + request.getUserId());
            }
        } catch (FeignException e) {
            throw new RuntimeException("User not found with id: " + request.getUserId());
        }
        
        Order order = new Order(request.getUserId());
        
        // Process each order item
        for (CreateOrderRequest.OrderItemRequest itemRequest : request.getItems()) {
            try {
                // Get product details
                ProductDto product = productServiceClient.getProductById(itemRequest.getProductId());
                if (product == null || !product.getIsActive()) {
                    throw new RuntimeException("Product not available with id: " + itemRequest.getProductId());
                }
                
                // Check stock availability
                if (product.getStockQuantity() < itemRequest.getQuantity()) {
                    throw new RuntimeException("Insufficient stock for product: " + product.getName() + 
                                             ". Available: " + product.getStockQuantity() + 
                                             ", Requested: " + itemRequest.getQuantity());
                }
                
                // Decrease stock
                productServiceClient.decreaseStock(itemRequest.getProductId(), itemRequest.getQuantity());
                
                // Create order item
                OrderItem orderItem = new OrderItem(
                    product.getId(),
                    product.getName(),
                    product.getPrice(),
                    itemRequest.getQuantity()
                );
                
                order.addOrderItem(orderItem);
                
            } catch (FeignException e) {
                throw new RuntimeException("Product not found with id: " + itemRequest.getProductId());
            }
        }
        
        return orderRepository.save(order);
    }
    
    public Order updateOrderStatus(Long id, OrderStatus newStatus) {
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Order not found with id: " + id));
        
        order.setStatus(newStatus);
        return orderRepository.save(order);
    }
    
    public void cancelOrder(Long id) {
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Order not found with id: " + id));
        
        if (order.getStatus() == OrderStatus.SHIPPED || order.getStatus() == OrderStatus.DELIVERED) {
            throw new RuntimeException("Cannot cancel order in status: " + order.getStatus());
        }
        
        order.setStatus(OrderStatus.CANCELLED);
        orderRepository.save(order);
    }
    
    public void deleteOrder(Long id) {
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Order not found with id: " + id));
        orderRepository.delete(order);
    }
}