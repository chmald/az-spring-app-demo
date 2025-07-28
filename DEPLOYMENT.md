# Azure Container Apps Deployment Guide

This guide provides step-by-step instructions for deploying the Spring Boot microservices application to Azure Container Apps.

## Prerequisites

1. **Azure CLI** - Install the latest version
2. **Azure Developer CLI (azd)** - Install from [here](https://aka.ms/azd-install)
3. **Docker** - For local testing (optional)
4. **Java 17** - For local development
5. **Maven** - For building applications

## Pre-Deployment Setup

### 1. Initialize Azure Developer CLI

```bash
# Login to Azure
azd auth login

# Initialize the project (if not already done)
azd init
```

### 2. Set Environment Variables

Create a `.env` file in the project root or set these environment variables:

```bash
# Required environment variables
AZURE_ENV_NAME=your-environment-name
AZURE_LOCATION=eastus  # or your preferred region
DATABASE_PASSWORD=YourSecurePassword123!
```

### 3. Build the Applications

Before deployment, ensure all services are built:

```bash
# Build all services
mvn clean package -DskipTests

# Or build individually
cd eureka-server && mvn clean package -DskipTests && cd ..
cd config-server && mvn clean package -DskipTests && cd ..
cd gateway-service && mvn clean package -DskipTests && cd ..
cd user-service && mvn clean package -DskipTests && cd ..
cd product-service && mvn clean package -DskipTests && cd ..
cd order-service && mvn clean package -DskipTests && cd ..
```

## Deployment Steps

### 1. Deploy Infrastructure and Applications

```bash
# Deploy everything with azd
azd up
```

This command will:
- Create the Azure resource group
- Deploy all infrastructure (Container Registry, Container Apps Environment, PostgreSQL, etc.)
- Build and push Docker images
- Deploy container apps
- Configure networking and security

### 2. Verify Deployment

After deployment, azd will output the service URLs. You can also check:

```bash
# List all resources
azd show

# Get service endpoints
azd show --output table
```

### 3. Access the Applications

The deployment creates the following endpoints:
- **Eureka Server**: `https://{eureka-fqdn}` (Service Discovery UI)
- **Config Server**: `https://{config-fqdn}` (Configuration endpoint)
- **Gateway Service**: `https://{gateway-fqdn}` (Main API Gateway)

## Service Architecture

### Container Apps Created

1. **eureka-server** (Port 8761)
   - Service discovery and registration
   - External access for monitoring
   - Auto-scaling: 1-3 replicas

2. **config-server** (Port 8888)
   - Centralized configuration management
   - External access for configuration
   - Auto-scaling: 1-3 replicas

3. **gateway-service** (Port 8080)
   - API Gateway and routing
   - External access for client requests
   - Auto-scaling: 1-5 replicas

4. **user-service** (Port 8080)
   - User management microservice
   - Internal access only
   - Auto-scaling: 1-5 replicas

5. **product-service** (Port 8080)
   - Product catalog microservice
   - Internal access only
   - Auto-scaling: 1-5 replicas

6. **order-service** (Port 8080)
   - Order processing microservice
   - Internal access only
   - Auto-scaling: 1-5 replicas

### Supporting Infrastructure

- **PostgreSQL Flexible Server**: Three databases (userdb, productdb, orderdb)
- **Azure Container Registry**: Stores Docker images
- **Application Insights**: Monitoring and telemetry
- **Log Analytics Workspace**: Centralized logging
- **Key Vault**: Secure storage for database credentials
- **Managed Identity**: Secure access to Azure resources

## Configuration

### Environment Variables

Each service is configured with:
- `SPRING_PROFILES_ACTIVE=azure`
- `APPLICATIONINSIGHTS_CONNECTION_STRING` (for monitoring)
- Service-specific database connections (for data services)
- Eureka and Config Server URLs

### Database Configuration

- Server: Managed PostgreSQL Flexible Server
- Authentication: Username/password stored in Key Vault
- Databases: Separate database per service
- Connection pooling: Managed by Spring Boot

### Service Discovery

Services communicate using:
- Internal FQDNs within the Container Apps Environment
- Environment variables for service endpoints
- Eureka for service registration (optional in containerized environment)

## Monitoring and Logging

### Application Insights

- Automatic telemetry collection
- Performance monitoring
- Dependency tracking
- Custom metrics and logging

### Log Analytics

- Container logs aggregation
- System metrics
- Query capabilities with KQL

### Health Checks

Each service exposes Spring Boot Actuator endpoints:
- `/actuator/health` - Health status
- `/actuator/info` - Application information
- `/actuator/metrics` - Application metrics

## Scaling Configuration

Each Container App is configured with auto-scaling:

```yaml
scale:
  minReplicas: 1
  maxReplicas: 3-5  # varies by service
  rules:
    - name: "http-rule"
      http:
        metadata:
          concurrentRequests: "10"
```

## Security Features

1. **Managed Identity**: Used for secure access to Azure resources
2. **Key Vault Integration**: Database passwords stored securely
3. **Network Security**: Internal services not exposed externally
4. **CORS Configuration**: Properly configured for web access
5. **HTTPS**: All external endpoints use HTTPS

## Troubleshooting

### Check Container App Status

```bash
# View container app status
az containerapp show --name {app-name} --resource-group {resource-group}

# View logs
az containerapp logs show --name {app-name} --resource-group {resource-group}
```

### Common Issues

1. **Service not starting**: Check environment variables and database connectivity
2. **Image pull errors**: Verify Container Registry access and managed identity configuration
3. **Service discovery issues**: Check Eureka server connectivity and configuration
4. **Database connection**: Verify PostgreSQL server firewall and credentials

### Useful Commands

```bash
# Update a specific service
azd deploy {service-name}

# View environment details
azd env show

# Clean up resources
azd down
```

## Cost Optimization

Container Apps pricing is consumption-based:
- No charges when containers are idle
- Minimal compute charges during low traffic
- PostgreSQL uses burstable tier for cost efficiency
- Consider scaling policies based on actual usage patterns

## Next Steps

1. **CI/CD Pipeline**: Set up GitHub Actions or Azure DevOps for automated deployments
2. **Custom Domains**: Configure custom domains for external services
3. **Advanced Monitoring**: Set up alerts and dashboards in Azure Monitor
4. **Performance Tuning**: Analyze and optimize scaling rules based on usage patterns
5. **Security Hardening**: Implement additional security measures as needed

## Support and Documentation

- [Azure Container Apps Documentation](https://docs.microsoft.com/azure/container-apps/)
- [Azure Developer CLI Documentation](https://docs.microsoft.com/azure/developer/azure-developer-cli/)
- [Spring Boot on Azure](https://docs.microsoft.com/azure/developer/java/spring-framework/)
