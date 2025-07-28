@echo off
REM Azure Spring Apps Demo Deployment Script for Windows
REM This script deploys the demo to Azure Spring Apps

setlocal enabledelayedexpansion

REM Configuration with default values
if "%AZURE_RESOURCE_GROUP%"=="" set AZURE_RESOURCE_GROUP=az-spring-app-demo-rg
if "%AZURE_SPRING_APPS_SERVICE%"=="" set AZURE_SPRING_APPS_SERVICE=az-spring-app-demo
if "%AZURE_LOCATION%"=="" set AZURE_LOCATION=eastus

echo 🚀 Starting Azure Spring Apps Demo Deployment...
echo Resource Group: %AZURE_RESOURCE_GROUP%
echo Spring Apps Service: %AZURE_SPRING_APPS_SERVICE%
echo Location: %AZURE_LOCATION%
echo.

REM Check if Azure CLI is installed
az --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Azure CLI is not installed. Please install it first.
    echo Download from: https://aka.ms/installazurecliwindows
    exit /b 1
)

REM Check if logged in to Azure
az account show >nul 2>&1
if errorlevel 1 (
    echo ❌ Please log in to Azure first: az login
    exit /b 1
)

REM Prompt for database password
set /p DB_PASSWORD="Enter secure database administrator password (min 8 chars): "
if "%DB_PASSWORD%"=="" (
    echo ❌ Database password cannot be empty
    exit /b 1
)

REM Create resource group if it doesn't exist
echo 📦 Creating resource group if needed...
az group create --name "%AZURE_RESOURCE_GROUP%" --location "%AZURE_LOCATION%" --output table

REM Build the applications
echo 🔨 Building applications...
mvn clean package -DskipTests
if errorlevel 1 (
    echo ❌ Maven build failed
    exit /b 1
)

REM Deploy using ARM template
echo 🚀 Deploying Azure Spring Apps service and infrastructure...
az deployment group create ^
    --resource-group "%AZURE_RESOURCE_GROUP%" ^
    --template-file "infrastructure\azure\spring-apps-template.json" ^
    --parameters springAppsServiceName="%AZURE_SPRING_APPS_SERVICE%" ^
    --parameters location="%AZURE_LOCATION%" ^
    --parameters databaseAdministratorPassword="%DB_PASSWORD%"

if errorlevel 1 (
    echo ❌ Infrastructure deployment failed
    exit /b 1
)

REM Deploy applications
echo 📤 Deploying applications...

set services=eureka-server config-server gateway-service user-service product-service order-service

for %%s in (%services%) do (
    echo Deploying %%s...
    az spring app deploy ^
        --resource-group "%AZURE_RESOURCE_GROUP%" ^
        --service "%AZURE_SPRING_APPS_SERVICE%" ^
        --name "%%s" ^
        --artifact-path "%%s\target\%%s-1.0.0.jar" ^
        --jvm-options="-Xms1024m -Xmx1024m" ^
        --env SPRING_PROFILES_ACTIVE=azure ^
        --output table
    
    if errorlevel 1 (
        echo ❌ Failed to deploy %%s
        exit /b 1
    )
)

REM Set gateway as public endpoint
echo 🌐 Setting up gateway service as public endpoint...
az spring app update ^
    --resource-group "%AZURE_RESOURCE_GROUP%" ^
    --service "%AZURE_SPRING_APPS_SERVICE%" ^
    --name "gateway-service" ^
    --assign-endpoint true ^
    --output table

REM Get the gateway URL
echo 🔍 Getting gateway URL...
for /f "delims=" %%i in ('az spring app show --resource-group "%AZURE_RESOURCE_GROUP%" --service "%AZURE_SPRING_APPS_SERVICE%" --name "gateway-service" --query "properties.url" --output tsv') do set GATEWAY_URL=%%i

echo.
echo ✅ Deployment completed successfully!
echo 🌐 Gateway URL: %GATEWAY_URL%
echo 🔍 Eureka Dashboard: %GATEWAY_URL%/eureka/web
echo.
echo API Endpoints:
echo   Users API: %GATEWAY_URL%/api/users
echo   Products API: %GATEWAY_URL%/api/products
echo   Orders API: %GATEWAY_URL%/api/orders
echo.
echo 📊 Monitor your applications in the Azure portal:

REM Get subscription ID for portal URL
for /f "delims=" %%i in ('az account show --query id -o tsv') do set SUBSCRIPTION_ID=%%i
echo https://portal.azure.com/#@/resource/subscriptions/%SUBSCRIPTION_ID%/resourceGroups/%AZURE_RESOURCE_GROUP%/providers/Microsoft.AppPlatform/Spring/%AZURE_SPRING_APPS_SERVICE%

echo.
echo 🔐 Don't forget to:
echo   1. Review Application Insights for monitoring data
echo   2. Check PostgreSQL databases for data persistence
echo   3. Configure any additional security settings as needed
echo.

pause
