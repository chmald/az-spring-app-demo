# Azure Spring Apps Demo

A comprehensive demonstration of Azure Spring Apps with microservices architecture, featuring service discovery with Eureka, centralized configuration management, API Gateway, and inter-service communication.### ✅ Infrastructure Security**
- Bicep template with latest API versions
- Parameterized configuration without hardcoded secrets
- Resource group isolation
- Managed service updates
- Configuration Service with Git-based settings
- Application Insights APM integration## 🏗️ Architecture Overview

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

**🎯 We've consolidated into a single production-ready Bicep template** (`infra/main.bicep`) that includes:

### ✅ Included Production Features
- **Azure Spring Apps Service** (Standard tier)
- **Application Insights** with distributed tracing via APM integration
- **Log Analytics Workspace** for centralized logging  
- **Azure Database for PostgreSQL** (Flexible Server)
  - Separate databases: `userdb`, `productdb`, `orderdb`
  - Automated connection string configuration
- **Configuration Service** with Git-based configuration management
- **Environment-specific profiles** (azure profile activated)
- **Security best practices** with parameterized passwords
- **Cost-optimized resource sizing** for demos

### 🚫 Excluded from Consolidation (Available in enhanced-template.json)
- Azure Key Vault (can be added later)
- Azure Container Registry (for future containerization)
- Azure Service Bus (for advanced messaging scenarios)
- Additional networking and VNet integration

**Why Bicep over ARM?**
- **Cleaner syntax**: More readable and maintainable than JSON
- **Type safety**: Better IntelliSense and validation
- **Simplified expressions**: No need for complex ARM template functions
- **Automatic dependency management**: Bicep handles resource dependencies
- **Latest Azure features**: Access to newest API versions and features

## 🎯 Key Bicep Template Features

### Modern Azure Spring Apps Architecture
The Bicep template uses the latest Azure Spring Apps API (2023-12-01) with:

- **Separate Configuration Service**: Dedicated resource for centralized config management
- **Application Performance Monitoring**: Native Application Insights integration via APM
- **Enhanced Security**: Latest security practices and resource isolation
- **Type Safety**: Compile-time validation and IntelliSense support

### Resource Organization
```
├── infra/
│   ├── main.bicep              # Main Bicep template
│   └── main.parameters.json    # Deployment parameters
└── infrastructure/azure/        # Legacy ARM templates (for reference)
    ├── spring-apps-template.json
    └── spring-apps-template.parameters.json
```

## 🚀 Deployment to Azure (Production-Ready)

> **✨ Modern Deployment Approach**: This project now uses **Azure Container Apps** with **Azure Developer CLI (azd)** for streamlined, cost-effective deployment. The setup has been validated and optimized for azd compatibility.

### Key Deployment Features:
- ✅ **One-command deployment** with `azd up`
- ✅ **Container Apps** for modern, serverless container hosting
- ✅ **Individual Dockerfiles** per service for better isolation
- ✅ **Automated CI/CD** with infrastructure provisioning
- ✅ **Cost-optimized** compared to Azure Spring Apps
- ✅ **Production-ready** with monitoring, logging, and security

### Prerequisites

1. **Azure Developer CLI (azd)** - Recommended approach
   ```bash
   # Install Azure Developer CLI
   # Windows: Download from https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/install-azd
   # Verify installation
   azd version
   ```

2. **Azure CLI** (latest version)
   ```bash
   # Install Azure CLI
   # Windows: Download from https://aka.ms/installazurecliwindows
   # Verify installation
   az --version
   ```

3. **Docker** for containerized deployment
   ```bash
   # Verify Docker installation
   docker version
   ```

4. **Azure Subscription** with appropriate permissions
   ```bash
   # Login to Azure
   az login
   azd auth login
   
   # Set subscription (if you have multiple)
   az account set --subscription "your-subscription-id"
   
   # Verify current subscription
   az account show
   ```

### Step 1: Clone and Prepare the Repository

```bash
# Clone the repository
git clone https://github.com/chmald/az-spring-app-demo.git
cd az-spring-app-demo
```

**Note**: This project uses individual Dockerfiles for each service rather than Maven builds. The containerized approach provides better deployment consistency and isolation.

### Step 2: Deploy Azure Infrastructure

#### Option 1: Azure Developer CLI (Recommended)

The easiest and most modern approach using Azure Developer CLI:

1. **Initialize and Deploy**
   ```bash
   # Initialize the project (if not already done)
   azd init
   
   # Provision infrastructure and deploy applications in one command
   azd up
   ```

   This single command will:
   - ✅ Create all Azure resources (Container Apps, PostgreSQL, Log Analytics, etc.)
   - ✅ Build Docker images for each microservice
   - ✅ Push images to Azure Container Registry
   - ✅ Deploy all services to Azure Container Apps
   - ✅ Configure networking and security
   - ✅ Set up monitoring and logging

2. **Monitor Deployment**
   ```bash
   # View deployment logs
   azd logs
   
   # Check service status
   azd show
   ```

#### Option 2: Bicep with Azure CLI (Manual)

For more control over the deployment process:

1. **Create Resource Group**
   ```bash
   az group create --name "az-spring-app-demo-rg" --location "westus2"
   ```

2. **Deploy Infrastructure with Bicep**
   ```bash
   # Validate the Bicep template first
   az bicep build --file infra/main.bicep
   
   # Preview what will be deployed
   az deployment group what-if \
     --resource-group "az-spring-app-demo-rg" \
     --template-file "infra/main.bicep" \
     --parameters environmentName="demo" \
                  location="westus2" \
                  databaseAdministratorPassword="YourSecurePassword123!"
   
   # Deploy the infrastructure
   az deployment group create \
     --resource-group "az-spring-app-demo-rg" \
     --template-file "infra/main.bicep" \
     --parameters environmentName="demo" \
                  location="westus2" \
                  databaseAdministratorPassword="YourSecurePassword123!"
   ```

   **Alternative: Using Parameters File**
   ```bash
   # First, update the password in infra/main.parameters.json
   az deployment group create \
     --resource-group "az-spring-app-demo-rg" \
     --template-file "infra/main.bicep" \
     --parameters "@infra/main.parameters.json"
   ```

**Note**: The Bicep template creates Container Apps instead of Azure Spring Apps for better cost efficiency and modern containerized deployment.

### Step 3: Verify Deployment

**If you used `azd up`, your applications are automatically deployed and running!**

1. **Get Service URLs**
   ```bash
   # Get all service endpoints
   azd show --output json | jq '.services'
   
   # Or get the gateway URL specifically
   azd show --output table
   ```

2. **Test API Endpoints**
   ```bash
   # Replace <gateway-url> with your actual gateway URL from azd show
   curl https://<gateway-url>/api/users
   curl https://<gateway-url>/api/products
   curl https://<gateway-url>/eureka/web
   ```

3. **Monitor in Azure Portal**
   - Navigate to your resource group in Azure Portal
   - Open Container Apps Environment to see all running services
   - Check Application Insights for telemetry and performance data
   - Review logs in Log Analytics Workspace

### Step 4: Application Management

```bash
# View application logs
azd logs --service eureka-server

# Monitor all services
azd monitor

# Update a specific service
azd deploy --service user-service

# Scale services (if needed)
az containerapp update --name user-service --resource-group <rg-name> --min-replicas 2 --max-replicas 5
```

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
- Azure Container Apps Environment: ~$5-10/month (shared environment)
- Container Apps (6 services): ~$10-30/month per service (usage-based)
- Azure Database for PostgreSQL (Flexible Server): ~$15-50/month
- Azure Container Registry: ~$5/month (Basic tier)
- Application Insights: ~$5-20/month (usage-based)
- Log Analytics: ~$5-15/month (usage-based)

**Total Estimated: $100-200/month**

*Significantly lower than Azure Spring Apps due to usage-based pricing of Container Apps*

### Security Best Practices Applied

✅ **Database Security**
- PostgreSQL Flexible Server with strong password requirements
- Separate databases per microservice
- Private networking and security group restrictions

✅ **Container Security**
- HTTPS-only communication
- Non-root container execution
- Managed identities for Azure service authentication
- Container registry with user-assigned managed identity access

✅ **Infrastructure Security**
- Bicep template with parameterized configuration
- Resource group isolation
- No hardcoded credentials or connection strings

## 🛠️ Troubleshooting

### Common Deployment Issues

**ERROR: Bicep compilation failed**
```bash
# Validate Bicep syntax and compile
az bicep build --file infra/main.bicep

# Check for Bicep CLI updates
az bicep upgrade
```

**ERROR: "Resource provider not registered"**
```bash
az provider register --namespace Microsoft.ContainerRegistry --wait
az provider register --namespace Microsoft.App --wait
az provider register --namespace Microsoft.OperationalInsights --wait
```

**ERROR: "azd up fails during deployment"**
```bash
# Check azd logs for detailed error information
azd logs

# Verify Docker is running
docker version

# Check authentication
azd auth login --check-status
```

**ERROR: "Container app startup timeout"**
```bash
# Check container logs
az containerapp logs show --name user-service --resource-group <rg-name>

# Monitor real-time logs
azd logs --service user-service --follow
```

### Monitoring and Diagnostics

**View Application Insights**
1. Go to Azure Portal → Resource Group → Application Insights
2. Check "Application Map" for service dependencies
3. Review "Performance" for response times
4. Monitor "Failures" for error rates

**Access Logs**
```bash
# Using azd (recommended)
azd logs --service gateway-service --follow

# Using Azure CLI
az containerapp logs show --name gateway-service --resource-group <rg-name> --follow
```

**Health Checks**
```bash
# Get service URLs first
azd show

# Then test health endpoints
curl https://<gateway-url>/actuator/health
curl https://<eureka-url>/actuator/health
```

### Cleanup Resources

**WARNING: This will delete all deployed resources and data**

```bash
# Using azd (recommended)
azd down --purge

# Or using Azure CLI
az group delete --name "az-spring-app-demo-rg" --yes --no-wait
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

### Gateway Service (Local: http://localhost:8080, Azure: provided by azd show)
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
- **Docker Profile**: Configured for container deployment
- **Azure Profile**: Optimized for Azure Container Apps deployment
- **Environment-specific**: Supports dev, staging, and production profiles

## 🏥 Health Checks and Monitoring

All services expose actuator endpoints:

- **Health**: `/actuator/health`
- **Info**: `/actuator/info`
- **Metrics**: `/actuator/metrics`
- **Gateway Routes**: `/actuator/gateway/routes` (Gateway Service only)

### Service Discovery Dashboard
- **Local**: http://localhost:8761
- **Azure**: Access via the Eureka service URL from `azd show`

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

### Azure Container Apps (Primary)
Deploy to fully managed container platform with azd:
```bash
# One-command deployment
azd up

# Or step by step
azd provision  # Create infrastructure
azd deploy     # Deploy applications
```

### Azure Spring Apps (Alternative)
Deploy to fully managed Spring Boot platform:
```bash
# Requires switching to Azure Spring Apps Bicep template
az spring app deploy --resource-group rg-name --service spring-service-name --name app-name --artifact-path target/app.jar
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
| `docker` | Docker Compose deployment | Local container testing |
| `azure` | Azure Container Apps deployment | Production Azure |
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

This project uses modern Infrastructure as Code practices:

- **Bicep Templates**: Modern, type-safe infrastructure definitions in `infra/`
- **ARM Templates**: Legacy JSON templates in `infrastructure/azure/` (for compatibility)
- **Kubernetes Manifests**: Container orchestration and deployment in `k8s/`
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
