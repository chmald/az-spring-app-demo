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

### Production Azure Services
- **Azure Spring Apps** - Fully managed Spring Boot application platform
- **Application Insights** - Application performance monitoring and distributed tracing
- **Log Analytics Workspace** - Centralized logging and monitoring
- **Azure Database for PostgreSQL** - Production-ready database with separate databases per service
- **Azure Config Server** - External configuration management via Git repository

## 📋 Infrastructure Consolidation

This project originally had two ARM templates:
- **Basic Template**: Just Azure Spring Apps with minimal configuration
- **Enhanced Template**: Full production setup with monitoring, databases, and security

**🎯 We've consolidated into a single production-ready template** (`spring-apps-template.json`) that includes:

### ✅ Included Production Features
- **Azure Spring Apps Service** (Standard tier)
- **Application Insights** with distributed tracing
- **Log Analytics Workspace** for centralized logging  
- **Azure Database for PostgreSQL** (Flexible Server)
  - Separate databases: `userdb`, `productdb`, `orderdb`
  - Automated connection string configuration
- **Git-based Configuration Server**
- **Environment-specific profiles** (azure profile activated)
- **Security best practices** with parameterized passwords
- **Cost-optimized resource sizing** for demos

### 🚫 Excluded from Consolidation (Available in enhanced-template.json)
- Azure Key Vault (can be added later)
- Azure Container Registry (for future containerization)
- Azure Service Bus (for advanced messaging scenarios)
- Additional networking and VNet integration

**Why This Approach?**
- Single template for most production scenarios
- Reduced complexity while maintaining enterprise features
- Easy to extend with additional Azure services when needed
- Clear upgrade path from basic to advanced features

## 🚀 Deployment to Azure (Production-Ready)

### Prerequisites

1. **Azure CLI** (latest version)
   ```bash
   # Install Azure CLI
   # Windows: Download from https://aka.ms/installazurecliwindows
   # Verify installation
   az --version
   ```

2. **Azure Subscription** with appropriate permissions
   ```bash
   # Login to Azure
   az login
   
   # Set subscription (if you have multiple)
   az account set --subscription "your-subscription-id"
   
   # Verify current subscription
   az account show
   ```

3. **Java 17 and Maven** for building applications
   ```bash
   # Verify Java version
   java -version
   
   # Verify Maven
   mvn --version
   ```

### Step 1: Clone and Prepare the Repository

```bash
# Clone the repository
git clone https://github.com/chmald/az-spring-app-demo.git
cd az-spring-app-demo

# Build all applications
mvn clean package -DskipTests
```

### Step 2: Deploy Azure Infrastructure

#### Manual Azure CLI Deployment

1. **Create Resource Group**
   ```bash
   az group create --name "az-spring-app-demo-rg" --location "westus2"
   ```

2. **Deploy Infrastructure Template**
   ```bash
   az deployment group create --resource-group "az-spring-app-demo-rg" --template-file "infrastructure/azure/spring-apps-template.json" --parameters springAppsServiceName="az-spring-app-demo" location="westus2" databaseAdministratorPassword="YourSecurePassword123!"
   ```

   **Alternative: Using Parameters File**
   ```bash
   az deployment group create --resource-group "az-spring-app-demo-rg" --template-file "infrastructure/azure/spring-apps-template.json" --parameters "@infrastructure/azure/spring-apps-template.parameters.json"
   ```

3. **Deploy Applications**
   ```bash
   az spring app deploy --resource-group "az-spring-app-demo-rg" --service "az-spring-app-demo" --name "eureka-server" --artifact-path "eureka-server/target/eureka-server-1.0.0.jar" --jvm-options="-Xms1024m -Xmx1024m" --env SPRING_PROFILES_ACTIVE=azure
   ```
   ```bash
   az spring app deploy --resource-group "az-spring-app-demo-rg" --service "az-spring-app-demo" --name "config-server" --artifact-path "config-server/target/config-server-1.0.0.jar" --jvm-options="-Xms1024m -Xmx1024m" --env SPRING_PROFILES_ACTIVE=azure
   ```
   ```bash
   az spring app deploy --resource-group "az-spring-app-demo-rg" --service "az-spring-app-demo" --name "gateway-service" --artifact-path "gateway-service/target/gateway-service-1.0.0.jar" --jvm-options="-Xms1024m -Xmx1024m" --env SPRING_PROFILES_ACTIVE=azure
   ```
   ```bash
   az spring app deploy --resource-group "az-spring-app-demo-rg" --service "az-spring-app-demo" --name "user-service" --artifact-path "user-service/target/user-service-1.0.0.jar" --jvm-options="-Xms1024m -Xmx1024m" --env SPRING_PROFILES_ACTIVE=azure
   ```
   ```bash
   az spring app deploy --resource-group "az-spring-app-demo-rg" --service "az-spring-app-demo" --name "product-service" --artifact-path "product-service/target/product-service-1.0.0.jar" --jvm-options="-Xms1024m -Xmx1024m" --env SPRING_PROFILES_ACTIVE=azure
   ```
   ```bash
   az spring app deploy --resource-group "az-spring-app-demo-rg" --service "az-spring-app-demo" --name "order-service" --artifact-path "order-service/target/order-service-1.0.0.jar" --jvm-options="-Xms1024m -Xmx1024m" --env SPRING_PROFILES_ACTIVE=azure
   ```

4. **Configure Public Endpoint**
   ```bash
   az spring app update --resource-group "az-spring-app-demo-rg" --service "az-spring-app-demo" --name "gateway-service" --assign-endpoint true
   ```

### Step 3: Verify Deployment

1. **Get Gateway URL**
   ```bash
   az spring app show --resource-group "az-spring-app-demo-rg" --service "az-spring-app-demo" --name "gateway-service" --query "properties.url" --output tsv
   ```

2. **Test API Endpoints**
   ```bash
   curl https://YOUR_GATEWAY_URL/api/users
   ```
   ```bash
   curl https://YOUR_GATEWAY_URL/api/products
   ```
   ```bash
   curl https://YOUR_GATEWAY_URL/eureka/web
   ```

3. **Monitor in Azure Portal**
   - Navigate to your resource group in Azure Portal
   - Open Azure Spring Apps service
   - Check Application Insights for telemetry and performance data
   - Review logs in Log Analytics Workspace

### Environment Variables Configuration

The template automatically configures the following environment variables for production:

| Variable | Description | Value |
|----------|-------------|-------|
| `SPRING_PROFILES_ACTIVE` | Active Spring profile | `azure` |
| `APPLICATIONINSIGHTS_CONNECTION_STRING` | Application Insights connection | Auto-configured |
| `SPRING_DATASOURCE_URL` | PostgreSQL connection URL | Auto-configured |
| `SPRING_DATASOURCE_USERNAME` | Database username | From template parameter |
| `SPRING_DATASOURCE_PASSWORD` | Database password | From template parameter |

### Cost Considerations

**Estimated Monthly Cost (West US 2 region):**
- Azure Spring Apps (Standard): ~$50/month per app (6 apps = $300)
- Azure Database for PostgreSQL (Burstable B1ms): ~$15/month
- Application Insights: ~$5-20/month (usage-based)
- Log Analytics: ~$5-15/month (usage-based)

**Total Estimated: $325-350/month**

### Security Best Practices Applied

✅ **Database Security**
- PostgreSQL with strong password requirements
- Separate databases per microservice
- Network security group restrictions

✅ **Application Security**
- HTTPS-only communication
- Environment-specific configuration
- No hardcoded credentials

✅ **Monitoring & Compliance**
- Application Insights distributed tracing
- Centralized logging with Log Analytics
- Health check endpoints

✅ **Infrastructure Security**
- ARM template with parameterized configuration
- Resource group isolation
- Managed service updates

## 🛠️ Troubleshooting

### Common Deployment Issues

**ERROR: Problem: "Resource 'Microsoft.AppPlatform/Spring' was disallowed by policy"**
```bash
az provider register --namespace Microsoft.AppPlatform --wait
```

**ERROR: Problem: "Database connection failed"**
```bash
az postgres flexible-server firewall-rule create --resource-group "az-spring-app-demo-rg" --name "allowAzureServices" --rule-name "AllowAllWindowsAzureIps" --start-ip-address "0.0.0.0" --end-ip-address "0.0.0.0"
```

**ERROR: Problem: "Application startup timeout"**
```bash
az spring app logs --resource-group "az-spring-app-demo-rg" --service "az-spring-app-demo" --name "user-service" --follow
```
```bash
az spring app update --resource-group "az-spring-app-demo-rg" --service "az-spring-app-demo" --name "user-service" --memory "3Gi"
```

**ERROR: Problem: "Maven build fails"**
```bash
mvn clean install -DskipTests
```

### Monitoring and Diagnostics

**View Application Insights**
1. Go to Azure Portal → Resource Group → Application Insights
2. Check "Application Map" for service dependencies
3. Review "Performance" for response times
4. Monitor "Failures" for error rates

**Access Logs**
```bash
az spring app logs --resource-group "az-spring-app-demo-rg" --service "az-spring-app-demo" --name "gateway-service" --follow
```

**Health Checks**
```bash
curl https://YOUR_GATEWAY_URL/actuator/health
```
```bash
curl https://YOUR_GATEWAY_URL/eureka/apps
```

### Cleanup Resources

**WARNING: This will delete all deployed resources and data**

```bash
az group delete --name "az-spring-app-demo-rg" --yes --no-wait
```

**Or delete specific resources**
```bash
az spring delete --resource-group "az-spring-app-demo-rg" --name "az-spring-app-demo"
```

## 🚀 Local Development Setup

### Prerequisites for Local Development
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

### Docker Deployment (Local)

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

## 🚀 Deployment Options

### Azure Spring Apps
Deploy to fully managed Spring Boot platform:
```bash
# Deploy using Azure CLI
az spring app deploy --resource-group rg-name --service spring-service-name --name app-name --artifact-path target/app.jar

# Or use the provided GitHub Actions pipeline
git push origin main  # Triggers automatic deployment
```

### Azure Kubernetes Service (AKS)
Deploy to Kubernetes with full container orchestration:
```bash
# Build and push images
mvn clean package -DskipTests
docker build -t azspringappdemo.azurecr.io/service-name:latest service/
docker push azspringappdemo.azurecr.io/service-name:latest

# Deploy to Kubernetes
kubectl apply -f k8s/base/
```

### Local Development with Azure Services
Run locally while connecting to Azure services:
```bash
# Set Azure profile
export SPRING_PROFILES_ACTIVE=azure
export AZURE_KEYVAULT_ENDPOINT=https://your-keyvault.vault.azure.net/
export APPLICATIONINSIGHTS_CONNECTION_STRING=InstrumentationKey=your-key

# Run services
mvn spring-boot:run
```

## 📚 Documentation

- **[Azure Integrations Guide](docs/azure-integrations.md)** - Complete Azure services integration
- **[Kubernetes Deployment Guide](docs/kubernetes-deployment.md)** - Kubernetes deployment instructions  
- **[Architecture Overview](docs/architecture.md)** - System architecture and design

## 🔧 Configuration Profiles

The application supports multiple configuration profiles:

| Profile | Description | Use Case |
|---------|-------------|----------|
| `default` | Local development with H2 database | Development |
| `docker` | Docker Compose deployment | Local testing |
| `azure` | Azure Spring Apps deployment | Production Azure |
| `k8s` | Kubernetes deployment | Production Kubernetes |

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

## 🎯 Azure Cloud Integrations

This demo now includes comprehensive Azure cloud integrations:

### ☁️ Implemented Azure Services

- **✅ Azure Key Vault** integration for secrets management
- **✅ Azure Application Insights** for distributed tracing and monitoring
- **✅ Azure Service Bus** for asynchronous messaging
- **✅ Azure Database for PostgreSQL** for production data storage
- **✅ Azure Container Registry** for container management
- **✅ GitHub Actions CI/CD** pipeline with Azure deployment
- **✅ Kubernetes deployment** manifests for AKS

### 🏗️ Infrastructure as Code

- **Azure ARM Templates**: Complete infrastructure provisioning
- **Kubernetes Manifests**: Container orchestration and deployment
- **Docker Configurations**: Optimized container images with Application Insights
- **CI/CD Pipelines**: Automated build, test, and deployment

### 📊 Enhanced Monitoring

- **Application Insights**: Distributed tracing across all microservices
- **Custom Metrics**: Business and technical metrics collection
- **Health Checks**: Comprehensive health monitoring
- **Structured Logging**: Correlated logging with trace IDs

### 🔐 Security Features

- **Azure Key Vault**: Centralized secrets management
- **Managed Identities**: Secure authentication to Azure services
- **Network Security**: VNet integration and security groups
- **Container Security**: Non-root containers and security contexts

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
