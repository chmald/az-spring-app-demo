package com.azure.demo.orderservice.client;

import com.azure.demo.orderservice.dto.UserDto;
import org.springframework.cloud.openfeign.FeignClient;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;

@FeignClient(name = "user-service")
public interface UserServiceClient {
    
    @GetMapping("/users/{id}")
    UserDto getUserById(@PathVariable("id") Long id);
    
    @GetMapping("/users/username/{username}")
    UserDto getUserByUsername(@PathVariable("username") String username);
}