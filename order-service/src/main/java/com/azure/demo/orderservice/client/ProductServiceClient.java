package com.azure.demo.orderservice.client;

import com.azure.demo.orderservice.dto.ProductDto;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;

@FeignClient(name = "product-service")
public interface ProductServiceClient {
    
    @GetMapping("/products/{id}")
    ProductDto getProductById(@PathVariable("id") Long id);
    
    @PatchMapping("/products/{id}/decrease-stock")
    ProductDto decreaseStock(@PathVariable("id") Long id, @RequestParam("quantity") Integer quantity);
}