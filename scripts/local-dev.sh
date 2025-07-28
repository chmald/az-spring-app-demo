#!/bin/bash

# Local Development Helper Script
# This script helps manage the local development environment

set -e

case "$1" in
    "start")
        echo "🚀 Starting Azure Spring Apps Demo locally..."
        echo "Building applications first..."
        mvn clean compile
        
        echo "Starting services with Docker Compose..."
        docker-compose up --build
        ;;
    
    "stop")
        echo "🛑 Stopping all services..."
        docker-compose down
        ;;
    
    "restart")
        echo "🔄 Restarting services..."
        docker-compose down
        docker-compose up --build
        ;;
    
    "build")
        echo "🔨 Building all applications..."
        mvn clean package -DskipTests
        ;;
    
    "test")
        echo "🧪 Running tests..."
        mvn test
        ;;
    
    "logs")
        if [ -z "$2" ]; then
            echo "📋 Showing logs for all services..."
            docker-compose logs -f
        else
            echo "📋 Showing logs for $2..."
            docker-compose logs -f "$2"
        fi
        ;;
    
    "status")
        echo "📊 Service Status:"
        echo "===================="
        
        services=("eureka-server:8761" "config-server:8888" "gateway-service:8080" "user-service:8081" "product-service:8082" "order-service:8083")
        
        for service in "${services[@]}"; do
            IFS=':' read -r name port <<< "$service"
            if curl -s "http://localhost:$port/actuator/health" > /dev/null 2>&1; then
                echo "✅ $name (port $port) - Running"
            else
                echo "❌ $name (port $port) - Not responding"
            fi
        done
        
        echo ""
        echo "🌐 Access Points:"
        echo "  Gateway: http://localhost:8080"
        echo "  Eureka Dashboard: http://localhost:8761"
        echo "  Config Server: http://localhost:8888"
        ;;
    
    "demo")
        echo "🎬 Running API Demo..."
        
        # Wait for services to be ready
        echo "Waiting for services to start..."
        sleep 30
        
        # Create a user
        echo "Creating a user..."
        curl -X POST http://localhost:8080/api/users \
            -H "Content-Type: application/json" \
            -d '{
                "username": "demo-user",
                "email": "demo@example.com",
                "firstName": "Demo",
                "lastName": "User"
            }' | jq '.'
        
        echo ""
        
        # Create a product
        echo "Creating a product..."
        curl -X POST http://localhost:8080/api/products \
            -H "Content-Type: application/json" \
            -d '{
                "name": "Demo Laptop",
                "description": "High-performance demo laptop",
                "price": 999.99,
                "category": "Electronics",
                "stockQuantity": 10
            }' | jq '.'
        
        echo ""
        
        # Create an order
        echo "Creating an order..."
        curl -X POST http://localhost:8080/api/orders \
            -H "Content-Type: application/json" \
            -d '{
                "userId": 1,
                "items": [
                    {
                        "productId": 1,
                        "quantity": 2
                    }
                ]
            }' | jq '.'
        
        echo ""
        echo "✅ Demo completed! Check the APIs:"
        echo "  Users: curl http://localhost:8080/api/users"
        echo "  Products: curl http://localhost:8080/api/products"
        echo "  Orders: curl http://localhost:8080/api/orders"
        ;;
    
    "clean")
        echo "🧹 Cleaning up..."
        docker-compose down -v --remove-orphans
        mvn clean
        echo "✅ Cleanup completed!"
        ;;
    
    *)
        echo "Azure Spring Apps Demo - Local Development Helper"
        echo ""
        echo "Usage: ./scripts/local-dev.sh [command]"
        echo ""
        echo "Commands:"
        echo "  start    - Build and start all services"
        echo "  stop     - Stop all services"
        echo "  restart  - Restart all services"
        echo "  build    - Build all applications"
        echo "  test     - Run tests"
        echo "  logs     - Show logs (optionally for specific service)"
        echo "  status   - Check service status"
        echo "  demo     - Run a demo with sample API calls"
        echo "  clean    - Clean up everything"
        echo ""
        echo "Examples:"
        echo "  ./scripts/local-dev.sh start"
        echo "  ./scripts/local-dev.sh logs user-service"
        echo "  ./scripts/local-dev.sh demo"
        ;;
esac