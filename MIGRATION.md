# Azure Container Apps Migration Guide

This document outlines the migration from Azure Spring Apps to Azure Container Apps for the az-spring-app-demo application.

## Migration Overview

This Spring Boot microservices application has been migrated from Azure Spring Apps to Azure Container Apps to provide:

- Better container orchestration and scalability
- More control over container runtime and configuration
- Cost optimization through pay-per-use pricing model
- Enhanced integration with other Azure Container services

## Architecture Changes

### Before (Azure Spring Apps)
- Azure Spring Apps service hosting all microservices
- Built-in service discovery and configuration management
- Platform-managed infrastructure

### After (Azure Container Apps)
- Individual Container Apps for each microservice
- Azure Container Registry for image storage
- Container Apps Environment for shared infrastructure
- Service-to-service communication via environment variables

## Services Migrated

1. **eureka-server** - Service discovery (port 8761)
2. **config-server** - Configuration management (port 8888)
3. **gateway-service** - API Gateway (port 8080)
4. **user-service** - User management service (port 8080)
5. **product-service** - Product catalog service (port 8080)
6. **order-service** - Order processing service (port 8080)

## Key Changes

### Infrastructure
- **Container Registry**: Stores Docker images for all services
- **Container Apps Environment**: Shared environment with Log Analytics integration
- **Managed Identity**: Secure access to Azure resources
- **PostgreSQL Database**: Retained for data persistence

### Deployment Model
- Each service runs in its own Container App
- Docker images built from individual service Dockerfiles
- Environment variables manage service dependencies
- CORS enabled for cross-origin requests

### Networking
- Internal service-to-service communication
- External access through Container Apps ingress
- Environment-based service discovery

## Migration Benefits

1. **Cost Efficiency**: Pay only for actual resource consumption
2. **Scalability**: Individual scaling policies per service
3. **Flexibility**: Custom container configurations
4. **Integration**: Better integration with Azure DevOps and GitHub Actions
5. **Monitoring**: Enhanced observability with Application Insights

## Next Steps

1. Deploy the infrastructure using `azd up`
2. Configure environment variables for each service
3. Set up CI/CD pipelines for automated deployments
4. Monitor application performance and adjust scaling policies
