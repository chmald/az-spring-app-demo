# Architecture Overview

## System Architecture

The Azure Spring Apps Demo follows a microservices architecture pattern with the following components:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│                 │    │                 │    │                 │
│   Client Apps   │───▶│  API Gateway   │───▶│  Load Balancer  │
│                 │    │  (Port 8080)   │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                               │
                               ▼
                    ┌─────────────────┐
                    │                 │
                    │ Service Registry│
                    │   (Eureka)     │
                    │  (Port 8761)   │
                    └─────────────────┘
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
        ▼                      ▼                      ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│User Service │    │Product Svc  │    │Order Service│
│(Port 8081)  │    │(Port 8082)  │    │(Port 8083)  │
└─────────────┘    └─────────────┘    └─────────────┘
        │                      │             │
        │                      │             │
        ▼                      ▼             ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│  User DB    │    │ Product DB  │    │  Order DB   │
│   (H2)      │    │    (H2)     │    │    (H2)     │
└─────────────┘    └─────────────┘    └─────────────┘

                    ┌─────────────────┐
                    │                 │
                    │ Config Server   │
                    │  (Port 8888)    │
                    └─────────────────┘
```

## Service Responsibilities

### Infrastructure Services

#### Eureka Server (Service Discovery)
- **Purpose**: Service registration and discovery
- **Port**: 8761
- **Key Features**:
  - Service health monitoring
  - Client-side load balancing
  - Service instance management
  - Dashboard for monitoring registered services

#### Config Server (Configuration Management)
- **Purpose**: Centralized configuration management
- **Port**: 8888
- **Key Features**:
  - Git-based configuration storage
  - Environment-specific configurations
  - Real-time configuration refresh
  - Security for sensitive configurations

#### Gateway Service (API Gateway)
- **Purpose**: Single entry point for all client requests
- **Port**: 8080
- **Key Features**:
  - Request routing and load balancing
  - Cross-cutting concerns (security, logging)
  - Rate limiting and circuit breaking
  - API versioning and documentation

### Business Services

#### User Service
- **Purpose**: User management and authentication
- **Port**: 8081
- **Database**: H2 (in-memory)
- **Key Features**:
  - User CRUD operations
  - Email and username validation
  - User profile management

#### Product Service
- **Purpose**: Product catalog and inventory management
- **Port**: 8082
- **Database**: H2 (in-memory)
- **Key Features**:
  - Product CRUD operations
  - Inventory tracking
  - Category management
  - Stock management operations

#### Order Service
- **Purpose**: Order processing and orchestration
- **Port**: 8083
- **Database**: H2 (in-memory)
- **Key Features**:
  - Order creation and management
  - Inter-service communication (User & Product services)
  - Order status tracking
  - Transaction management

## Communication Patterns

### Service-to-Service Communication
- **Technology**: OpenFeign (declarative REST client)
- **Load Balancing**: Spring Cloud LoadBalancer
- **Service Discovery**: Eureka-based discovery

### API Gateway Routing
- **Technology**: Spring Cloud Gateway
- **Routing Strategy**: Path-based routing with service discovery
- **Load Balancing**: Round-robin across service instances

### Configuration Management
- **Technology**: Spring Cloud Config
- **Strategy**: Pull-based configuration refresh
- **Source**: Git repository (configurable)

## Data Flow

### User Creation Flow
1. Client sends POST request to Gateway (`/api/users`)
2. Gateway routes to User Service
3. User Service validates and persists user data
4. Response flows back through Gateway to client

### Order Creation Flow
1. Client sends POST request to Gateway (`/api/orders`)
2. Gateway routes to Order Service
3. Order Service validates user via User Service (Feign call)
4. Order Service validates products via Product Service (Feign call)
5. Order Service updates product inventory (Feign call)
6. Order Service creates order with calculated totals
7. Response flows back through Gateway to client

## Deployment Architecture

### Local Development
- **Container Orchestration**: Docker Compose
- **Service Discovery**: Eureka Server container
- **Database**: H2 in-memory (per service)
- **Configuration**: Local profile configurations

### Azure Spring Apps
- **Platform**: Azure Spring Apps (Standard tier)
- **Service Discovery**: Azure Spring Apps service registry
- **Configuration**: Azure Config Server with Git integration
- **Database**: Azure Database for PostgreSQL (production)
- **Monitoring**: Azure Application Insights

## Security Architecture

### Current Implementation
- Basic authentication for infrastructure services
- Input validation on all endpoints
- Actuator endpoint security

### Production Recommendations
- **Authentication**: Azure AD integration
- **Authorization**: OAuth2/JWT tokens
- **API Security**: Rate limiting and throttling
- **Network Security**: Azure Virtual Network integration
- **Secrets Management**: Azure Key Vault integration

## Scalability Considerations

### Horizontal Scaling
- Stateless service design enables horizontal scaling
- Load balancing across multiple service instances
- Database connection pooling and optimization

### Performance Optimization
- Connection pooling for inter-service calls
- Caching strategies for frequently accessed data
- Asynchronous processing for non-critical operations

## Monitoring and Observability

### Health Checks
- Spring Boot Actuator endpoints
- Custom health indicators
- Service dependency health checks

### Metrics and Tracing
- **Metrics**: Micrometer with Azure Application Insights
- **Tracing**: Spring Cloud Sleuth integration
- **Logging**: Structured logging with correlation IDs

### Monitoring Stack
- **Azure Application Insights**: Application performance monitoring
- **Azure Monitor**: Infrastructure monitoring
- **Custom Dashboards**: Service-specific monitoring