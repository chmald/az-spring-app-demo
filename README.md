# Azure Spring Apps Demo

A comprehensive demonstration of Azure Spring Apps with microservices architecture, featuring service discovery with Eureka, centralized configuration management, API Gateway, and inter-service communication.

## 🏗️ Architecture Overview

This demo showcases a complete microservices ecosystem with the following components:

### Core Infrastructure Services
- **Eureka Server** (`port 8761`) - Service discovery and registration
- **Config Server** (`port 8888`) - Centralized configuration management
- **Gateway Service** (`port 8080`) - API Gateway with routing and load balancing

### Business Microservices
- **User Service** (`port 8081`) - User management with full CRUD operations
- **Product Service** (`port 8082`) - Product catalog management with inventory tracking
- **Order Service** (`port 8083`) - Order processing with inter-service communication

## 🚀 Quick Start

### Prerequisites
- Java 17 or higher
- Maven 3.6+
- Docker and Docker Compose (for containerized deployment)

### Local Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/chmald/az-spring-app-demo.git
   cd az-spring-app-demo
   ```

2. **Build all services**
   ```bash
   mvn clean compile
   ```

3. **Run services locally (sequential startup)**
   ```bash
   # Terminal 1 - Eureka Server
   cd eureka-server && mvn spring-boot:run
   
   # Terminal 2 - Config Server (wait for Eureka to start)
   cd config-server && mvn spring-boot:run
   
   # Terminal 3 - Gateway Service
   cd gateway-service && mvn spring-boot:run
   
   # Terminal 4 - User Service
   cd user-service && mvn spring-boot:run
   
   # Terminal 5 - Product Service
   cd product-service && mvn spring-boot:run
   
   # Terminal 6 - Order Service
   cd order-service && mvn spring-boot:run
   ```

### Docker Deployment

1. **Build and start all services**
   ```bash
   docker-compose up --build
   ```

2. **Scale specific services** (optional)
   ```bash
   docker-compose up --scale user-service=2 --scale product-service=2
   ```

## 📋 API Documentation

### Gateway Service (http://localhost:8080)
All microservices are accessible through the API Gateway:

- **Users API**: `GET/POST/PUT/DELETE /api/users/**`
- **Products API**: `GET/POST/PUT/DELETE /api/products/**`
- **Orders API**: `GET/POST/PUT/DELETE /api/orders/**`
- **Eureka Dashboard**: `GET /eureka/web`

### User Service API Examples
```bash
# Create a user
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{
    "username": "johndoe",
    "email": "john@example.com",
    "firstName": "John",
    "lastName": "Doe"
  }'

# Get all users
curl http://localhost:8080/api/users

# Get user by ID
curl http://localhost:8080/api/users/1
```

### Product Service API Examples
```bash
# Create a product
curl -X POST http://localhost:8080/api/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Laptop",
    "description": "High-performance laptop",
    "price": 999.99,
    "category": "Electronics",
    "stockQuantity": 50
  }'

# Get all active products
curl http://localhost:8080/api/products/active

# Search products by name
curl "http://localhost:8080/api/products/search?name=laptop"
```

### Order Service API Examples
```bash
# Create an order
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
  }'

# Get orders by user
curl http://localhost:8080/api/orders/user/1

# Update order status
curl -X PATCH "http://localhost:8080/api/orders/1/status?status=CONFIRMED"
```

## 🔧 Configuration Management

The Config Server supports external configuration management:

- **Default Profile**: Uses classpath-based configuration
- **Git Profile**: Configured to use external Git repository for configurations
- **Environment-specific**: Supports dev, staging, and production profiles

## 🏥 Health Checks and Monitoring

All services expose actuator endpoints:

- **Health**: `/actuator/health`
- **Info**: `/actuator/info`
- **Metrics**: `/actuator/metrics`
- **Gateway Routes**: `/actuator/gateway/routes` (Gateway Service only)

### Service Discovery Dashboard
Access the Eureka dashboard at: http://localhost:8761

## 🐳 Docker Configuration

The project includes:
- **Multi-stage Dockerfile** for optimized container builds
- **Docker Compose** configuration with health checks
- **Service dependencies** and startup ordering
- **Network isolation** for microservices communication

## 🔒 Security Features

- Basic authentication for Eureka Server and Config Server
- Input validation on all API endpoints
- Structured error handling and logging
- Actuator endpoint security configuration

## 📊 Key Features Demonstrated

### Service Discovery
- Automatic service registration with Eureka
- Client-side load balancing
- Service health monitoring
- Dynamic service discovery

### Configuration Management
- Centralized configuration with Config Server
- Environment-specific property files
- Configuration refresh capabilities
- External configuration sources

### API Gateway
- Request routing based on service names
- Load balancing across service instances
- Gateway filters and predicates
- Centralized API access point

### Inter-Service Communication
- Feign client for service-to-service calls
- Circuit breaker patterns (ready for implementation)
- Distributed tracing support (ready for implementation)
- Error handling and fallback mechanisms

### Data Management
- JPA/Hibernate with H2 database
- Transactional operations
- Entity relationships and cascading
- Repository pattern implementation

## 🚀 Azure Spring Apps Deployment

This demo is designed to deploy seamlessly to Azure Spring Apps:

1. **Build Configuration**: Maven-based builds compatible with Azure Spring Apps
2. **Service Discovery**: Eureka configuration works with Azure Spring Apps service registry
3. **Configuration**: Supports Azure Key Vault integration for production secrets
4. **Monitoring**: Ready for Azure Application Insights integration
5. **Scaling**: Designed for horizontal scaling in Azure environment

## 📁 Project Structure

```
├── config-server/           # Spring Cloud Config Server
├── eureka-server/          # Service Discovery Server
├── gateway-service/        # API Gateway
├── user-service/          # User Management Microservice
├── product-service/       # Product Catalog Microservice
├── order-service/         # Order Processing Microservice
├── docker-compose.yml     # Local development setup
├── Dockerfile            # Multi-service container build
└── README.md            # This file
```

## 🔧 Development Commands

```bash
# Build all services
mvn clean compile

# Run tests
mvn test

# Package applications
mvn clean package

# Build Docker images
docker-compose build

# Start all services
docker-compose up

# Stop all services
docker-compose down

# View service logs
docker-compose logs -f [service-name]
```

## 🎯 Future Enhancements

This demo provides a foundation for implementing:

- **Azure Key Vault** integration for secrets management
- **Azure Application Insights** for distributed tracing
- **Azure Service Bus** for asynchronous messaging
- **Azure Database** for production data storage
- **Azure Container Registry** for container management
- **GitHub Actions** CI/CD pipeline
- **Kubernetes** deployment manifests

## 📝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Built with ❤️ for Azure Spring Apps demonstrations**
