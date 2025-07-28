#!/bin/bash

# Azure Spring Apps Demo Deployment Script
# This script deploys the demo to Azure Spring Apps with production-ready infrastructure

set -e

# Configuration
RESOURCE_GROUP_NAME="${AZURE_RESOURCE_GROUP:-az-spring-app-demo-rg}"
SPRING_APPS_SERVICE="${AZURE_SPRING_APPS_SERVICE:-az-spring-app-demo}"
LOCATION="${AZURE_LOCATION:-eastus}"

echo "🚀 Starting Azure Spring Apps Demo Deployment..."
echo "Resource Group: $RESOURCE_GROUP_NAME"
echo "Spring Apps Service: $SPRING_APPS_SERVICE"
echo "Location: $LOCATION"

# Check if Azure CLI is installed
if ! command -v az &> /dev/null; then
    echo "❌ Azure CLI is not installed. Please install it first."
    exit 1
fi

# Check if logged in to Azure
if ! az account show &> /dev/null; then
    echo "❌ Please log in to Azure first: az login"
    exit 1
fi

# Prompt for database password if not set
if [ -z "$DB_PASSWORD" ]; then
    read -s -p "Enter secure database administrator password (min 8 chars): " DB_PASSWORD
    echo
    if [ -z "$DB_PASSWORD" ]; then
        echo "❌ Database password cannot be empty"
        exit 1
    fi
fi

# Create resource group if it doesn't exist
echo "📦 Creating resource group if needed..."
az group create --name "$RESOURCE_GROUP_NAME" --location "$LOCATION" --output table

# Build the applications
echo "🔨 Building applications..."
mvn clean package -DskipTests

# Deploy using ARM template with enhanced features
echo "🚀 Deploying Azure Spring Apps service with production infrastructure..."
az deployment group create \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --template-file infrastructure/azure/spring-apps-template.json \
    --parameters springAppsServiceName="$SPRING_APPS_SERVICE" \
    --parameters location="$LOCATION" \
    --parameters databaseAdministratorPassword="$DB_PASSWORD"

# Deploy applications
echo "📤 Deploying applications..."

# Array of services to deploy
services=("eureka-server" "config-server" "gateway-service" "user-service" "product-service" "order-service")

for service in "${services[@]}"; do
    echo "Deploying $service..."
    az spring app deploy \
        --resource-group "$RESOURCE_GROUP_NAME" \
        --service "$SPRING_APPS_SERVICE" \
        --name "$service" \
        --artifact-path "$service/target/$service-1.0.0.jar" \
        --jvm-options="-Xms1024m -Xmx1024m" \
        --env SPRING_PROFILES_ACTIVE=azure \
        --output table
done

# Set gateway as public endpoint
echo "🌐 Setting up gateway service as public endpoint..."
az spring app update \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --service "$SPRING_APPS_SERVICE" \
    --name "gateway-service" \
    --assign-endpoint true \
    --output table

# Get the gateway URL
GATEWAY_URL=$(az spring app show \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --service "$SPRING_APPS_SERVICE" \
    --name "gateway-service" \
    --query "properties.url" \
    --output tsv)

echo "✅ Deployment completed successfully!"
echo "🌐 Gateway URL: $GATEWAY_URL"
echo "🔍 Eureka Dashboard: $GATEWAY_URL/eureka/web"
echo ""
echo "API Endpoints:"
echo "  Users API: $GATEWAY_URL/api/users"
echo "  Products API: $GATEWAY_URL/api/products" 
echo "  Orders API: $GATEWAY_URL/api/orders"
echo ""
echo "📊 Monitor your applications in the Azure portal:"
echo "https://portal.azure.com/#@/resource/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP_NAME/providers/Microsoft.AppPlatform/Spring/$SPRING_APPS_SERVICE"
echo ""
echo "🔐 Production features enabled:"
echo "  ✅ Application Insights monitoring"
echo "  ✅ PostgreSQL databases (userdb, productdb, orderdb)"
echo "  ✅ Log Analytics workspace"
echo "  ✅ Distributed tracing"
echo "  ✅ Production-ready configuration"