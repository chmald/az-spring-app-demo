# Azure Integrations Documentation

## Overview

This document describes the Azure cloud integrations implemented in the Azure Spring Apps Demo, including Azure Key Vault, Application Insights, Service Bus, Database, Container Registry, and deployment options.

## Azure Services Integration

### 1. Azure Key Vault Integration

Azure Key Vault provides secure secrets management for the application.

#### Configuration

The application is configured to use Azure Key Vault for secrets management in the `azure` profile:

```yaml
spring:
  cloud:
    azure:
      keyvault:
        secret:
          enabled: true
          endpoint: ${AZURE_KEYVAULT_ENDPOINT:}
          property-sources:
            - endpoint: ${AZURE_KEYVAULT_ENDPOINT:}
              name: azure-keyvault
```

#### Required Secrets in Key Vault

| Secret Name | Description | Example Value |
|-------------|-------------|---------------|
| `db-username` | Database username | `azureadmin` |
| `db-password` | Database password | `SecurePassword123!` |
| `git-username` | Git repository username for config server | `your-username` |
| `git-password` | Git repository password/token | `your-token` |
| `servicebus-connection-string` | Azure Service Bus connection string | `Endpoint=sb://...` |

#### Setup Steps

1. Create Azure Key Vault:
   ```bash
   az keyvault create --name your-keyvault --resource-group your-rg --location eastus
   ```

2. Add secrets:
   ```bash
   az keyvault secret set --vault-name your-keyvault --name db-username --value "azureadmin"
   az keyvault secret set --vault-name your-keyvault --name db-password --value "SecurePassword123!"
   ```

3. Grant access to Azure Spring Apps:
   ```bash
   az keyvault set-policy --name your-keyvault --object-id <spring-apps-principal-id> --secret-permissions get list
   ```

### 2. Azure Application Insights

Application Insights provides distributed tracing, performance monitoring, and telemetry collection.

#### Configuration

Application Insights is automatically configured when the connection string is provided:

```yaml
management:
  metrics:
    export:
      azure-monitor:
        enabled: true
```

#### Features

- **Distributed Tracing**: Track requests across microservices
- **Performance Monitoring**: Monitor response times and throughput
- **Exception Tracking**: Automatic exception collection
- **Custom Metrics**: Application-specific metrics
- **Live Metrics**: Real-time monitoring

#### Setup

The Application Insights Java agent is automatically included in Docker images and provides automatic instrumentation.

### 3. Azure Service Bus

Azure Service Bus enables asynchronous messaging between services, particularly for order processing.

#### Configuration

Service Bus is configured in the order-service:

```yaml
spring:
  cloud:
    azure:
      servicebus:
        connection-string: ${AZURE_SERVICEBUS_CONNECTION_STRING:@azure-keyvault[servicebus-connection-string]}
        processor:
          max-concurrent-calls: 10

azure:
  servicebus:
    queues:
      order-processing: order-processing-queue
      order-notifications: order-notifications-queue
    topics:
      order-events: order-events-topic
```

#### Message Flow

1. **Order Created**: When an order is created, an event is published to the `order-processing-queue`
2. **Order Processing**: Background processing consumes messages from the queue
3. **Status Updates**: Order status changes are published to `order-notifications-queue`
4. **Event Broadcasting**: Major order events are published to `order-events-topic`

#### Implementation

The messaging is implemented using:
- `OrderEventPublisher`: Publishes order events
- `OrderEventConsumer`: Consumes and processes order events
- `OrderEvent`: Event data structure

### 4. Azure Database for PostgreSQL

Production data storage using Azure Database for PostgreSQL Flexible Server.

#### Configuration

Each service connects to its own database:

```yaml
spring:
  datasource:
    url: ${DB_URL:jdbc:postgresql://your-server.postgres.database.azure.com:5432/userdb}
    username: ${DB_USERNAME:@azure-keyvault[db-username]}
    password: ${DB_PASSWORD:@azure-keyvault[db-password]}
    driver-class-name: org.postgresql.Driver
  jpa:
    database-platform: org.hibernate.dialect.PostgreSQLDialect
    hibernate:
      ddl-auto: validate
```

#### Database Schema

- **userdb**: User service database
- **productdb**: Product service database  
- **orderdb**: Order service database

#### Migration Strategy

For production deployment, use Flyway or Liquibase for database migrations:

1. Set `ddl-auto: validate` in production
2. Create migration scripts for schema changes
3. Run migrations as part of deployment pipeline

### 5. Azure Container Registry (ACR)

ACR stores Docker images for Kubernetes and Azure Spring Apps deployments.

#### Configuration

Images are built and pushed to ACR in the CI/CD pipeline:

```yaml
docker build -t azspringappdemo.azurecr.io/service-name:tag .
docker push azspringappdemo.azurecr.io/service-name:tag
```

#### Image Structure

Each service image includes:
- OpenJDK 17 runtime
- Application JAR file
- Application Insights Java agent
- Health check utilities

### 6. GitHub Actions CI/CD Pipeline

Enhanced CI/CD pipeline with Azure integrations.

#### Pipeline Stages

1. **Test**: Run unit tests and integration tests
2. **Build**: Compile and package applications
3. **Docker Build & Push**: Build and push images to ACR
4. **Deploy to Staging**: Deploy to staging environment
5. **Deploy to Production**: Deploy to production environment

#### Environment Variables

Set these secrets in GitHub repository:

| Secret | Description |
|--------|-------------|
| `AZURE_CREDENTIALS` | Azure service principal credentials |
| `AZURE_CONTAINER_REGISTRY` | ACR name |
| `AZURE_RESOURCE_GROUP` | Resource group name |

#### Deployment Targets

- **Azure Spring Apps**: Managed Spring Boot hosting
- **Azure Kubernetes Service (AKS)**: Container orchestration

## Deployment Options

### Option 1: Azure Spring Apps

Managed Spring Boot platform with built-in service discovery and configuration management.

**Pros:**
- Fully managed platform
- Built-in Spring Boot features
- Automatic scaling
- Integrated monitoring

**Cons:**
- Less flexibility
- Azure-specific platform

### Option 2: Azure Kubernetes Service (AKS)

Container orchestration with full control over deployment.

**Pros:**
- Full container orchestration
- Portable across cloud providers
- Fine-grained control
- Rich ecosystem

**Cons:**
- More complex management
- Requires Kubernetes expertise

## Monitoring and Observability

### Application Insights Integration

- **Custom Metrics**: Business metrics collection
- **Request Tracing**: End-to-end request tracking
- **Performance Counters**: JVM and application metrics
- **Log Correlation**: Correlated logging across services

### Health Checks

Each service exposes health endpoints:

```
/actuator/health
/actuator/metrics
/actuator/prometheus
```

### Alerting

Configure alerts in Application Insights for:
- High error rates
- Slow response times
- High memory usage
- Service availability

## Security Considerations

### Identity and Access Management

- Use Azure AD for authentication
- Implement RBAC for resource access
- Use managed identities where possible

### Network Security

- Configure Azure Virtual Networks
- Use private endpoints for databases
- Implement network security groups

### Secrets Management

- Store all secrets in Azure Key Vault
- Use managed identities for authentication
- Rotate secrets regularly

## Cost Optimization

### Resource Sizing

- Monitor resource usage and adjust sizes
- Use autoscaling for variable workloads
- Consider reserved instances for predictable workloads

### Development/Testing

- Use lower-tier services for non-production environments
- Implement automated shutdown for development resources
- Use shared resources where appropriate

## Troubleshooting

### Common Issues

1. **Key Vault Access**: Ensure proper permissions are configured
2. **Service Bus Connectivity**: Verify connection string and network access
3. **Database Connectivity**: Check firewall rules and connection strings
4. **Container Registry**: Verify authentication and image tags

### Diagnostic Commands

```bash
# Check Azure Spring Apps logs
az spring app logs --name service-name --resource-group rg-name --service spring-service-name

# Check Kubernetes pod logs
kubectl logs -f deployment/service-name

# Test Key Vault connectivity
az keyvault secret show --vault-name vault-name --name secret-name

# Check Service Bus metrics
az servicebus namespace show --name namespace-name --resource-group rg-name
```

## Best Practices

1. **Environment Separation**: Use separate Azure resources for each environment
2. **Configuration Management**: Use Key Vault for all secrets and configuration
3. **Monitoring**: Implement comprehensive monitoring and alerting
4. **Security**: Follow principle of least privilege
5. **Documentation**: Keep deployment and configuration documentation up to date
6. **Testing**: Include infrastructure and integration testing in CI/CD pipeline

## Next Steps

1. Set up Azure resources using the provided ARM templates
2. Configure Key Vault with required secrets
3. Update GitHub Actions with Azure credentials
4. Deploy to staging environment first
5. Configure monitoring and alerting
6. Deploy to production environment