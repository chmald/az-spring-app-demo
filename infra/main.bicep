// Azure Container Apps deployment for Spring Boot microservices
// This template creates a complete Container Apps environment with:
// - Container Apps Environment with Log Analytics integration
// - Azure Container Registry for image storage
// - Container Apps for each microservice
// - PostgreSQL Flexible Server with multiple databases
// - Application Insights for monitoring
// - Managed Identity for secure access

targetScope = 'resourceGroup'

// Parameters
@description('The environment name')
param environmentName string

@description('Primary location for all resources')
param location string = resourceGroup().location

@description('Name of the PostgreSQL server')
param databaseServerName string = 'az-demo-dbserver'

@description('Database administrator login')
param databaseAdministratorLogin string = 'azureadmin'

@description('Database administrator password (minimum 8 characters)')
@secure()
param databaseAdministratorPassword string

// Environment variables for each service - to be configured by user
@description('Spring profiles active setting')
param springProfilesActive string = 'azure'

@description('Eureka server configuration - whether to register with eureka')
param eurekaClientRegisterWithEureka string = 'false'

@description('Eureka server configuration - whether to fetch registry')
param eurekaClientFetchRegistry string = 'false'

@description('Spring Cloud Config Server Git URI')
param springCloudConfigServerGitUri string = 'https://github.com/chmald/az-spring-app-demo-config'

// Variables
var resourceToken = uniqueString(subscription().id, resourceGroup().id, location, environmentName)
var resourcePrefix = 'demo'

// Resource names following the naming convention
var logAnalyticsWorkspaceName = 'az-${resourcePrefix}-law-${resourceToken}'
var applicationInsightsName = 'az-${resourcePrefix}-ai-${resourceToken}'
var containerRegistryName = 'az${resourcePrefix}cr${replace(resourceToken, '-', '')}'
var containerAppsEnvironmentName = 'az-${resourcePrefix}-env-${resourceToken}'
var managedIdentityName = 'az-${resourcePrefix}-id-${resourceToken}'
var keyVaultName = 'az-${resourcePrefix}-kv-${resourceToken}'

// Container App names
var containerAppNames = {
  eurekaServer: 'az-${resourcePrefix}-eureka-${resourceToken}'
  configServer: 'az-${resourcePrefix}-config-${resourceToken}'
  gatewayService: 'az-${resourcePrefix}-gateway-${resourceToken}'
  userService: 'az-${resourcePrefix}-user-${resourceToken}'
  productService: 'az-${resourcePrefix}-product-${resourceToken}'
  orderService: 'az-${resourcePrefix}-order-${resourceToken}'
}

// Log Analytics Workspace - Foundation for monitoring
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
  tags: {
    'azd-env-name': environmentName
  }
}

// Application Insights - Application monitoring and telemetry
resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
  tags: {
    'azd-env-name': environmentName
  }
}

// User-assigned Managed Identity
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: managedIdentityName
  location: location
  tags: {
    'azd-env-name': environmentName
  }
}

// Azure Container Registry - Store container images
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: containerRegistryName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
  }
  tags: {
    'azd-env-name': environmentName
  }
}

// Grant AcrPull role to managed identity for container registry
resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: containerRegistry
  name: guid(containerRegistry.id, managedIdentity.id, '7f951dda-4ed3-4680-a7ca-43fe172d538d')
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull
    principalId: managedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Key Vault for storing secrets
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenant().tenantId
    accessPolicies: [
      {
        tenantId: tenant().tenantId
        objectId: managedIdentity.properties.principalId
        permissions: {
          secrets: ['get', 'list']
        }
      }
    ]
    enableRbacAuthorization: false
  }
  tags: {
    'azd-env-name': environmentName
  }
}

// Store database connection secrets in Key Vault
resource dbPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'database-password'
  properties: {
    value: databaseAdministratorPassword
  }
}

// PostgreSQL Flexible Server - Database backend
resource postgresqlServer 'Microsoft.DBforPostgreSQL/flexibleServers@2022-12-01' = {
  name: databaseServerName
  location: location
  sku: {
    name: 'Standard_B1ms'
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: databaseAdministratorLogin
    administratorLoginPassword: databaseAdministratorPassword
    version: '14'
    storage: {
      storageSizeGB: 32
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
  }
  tags: {
    'azd-env-name': environmentName
  }
}

// Database for user service
resource userDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2022-12-01' = {
  parent: postgresqlServer
  name: 'userdb'
}

// Database for product service
resource productDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2022-12-01' = {
  parent: postgresqlServer
  name: 'productdb'
}

// Database for order service
resource orderDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2022-12-01' = {
  parent: postgresqlServer
  name: 'orderdb'
}

// Container Apps Environment - Shared environment for all container apps
resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: containerAppsEnvironmentName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
  tags: {
    'azd-env-name': environmentName
  }
}

// Eureka Server Container App
resource eurekaServerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppNames.eurekaServer
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    environmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 8761
        allowInsecure: false
        corsPolicy: {
          allowedOrigins: ['*']
          allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
          allowedHeaders: ['*']
          allowCredentials: false
        }
      }
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: managedIdentity.id
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'eureka-server'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              name: 'SPRING_PROFILES_ACTIVE'
              value: springProfilesActive
            }
            {
              name: 'EUREKA_CLIENT_REGISTER_WITH_EUREKA'
              value: eurekaClientRegisterWithEureka
            }
            {
              name: 'EUREKA_CLIENT_FETCH_REGISTRY'
              value: eurekaClientFetchRegistry
            }
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: applicationInsights.properties.ConnectionString
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
      }
    }
  }
  tags: {
    'azd-service-name': 'eureka-server'
    'azd-env-name': environmentName
  }
}

// Config Server Container App
resource configServerApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppNames.configServer
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    environmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 8888
        allowInsecure: false
        corsPolicy: {
          allowedOrigins: ['*']
          allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
          allowedHeaders: ['*']
          allowCredentials: false
        }
      }
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: managedIdentity.id
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'config-server'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              name: 'SPRING_PROFILES_ACTIVE'
              value: springProfilesActive
            }
            {
              name: 'SPRING_CLOUD_CONFIG_SERVER_GIT_URI'
              value: springCloudConfigServerGitUri
            }
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: applicationInsights.properties.ConnectionString
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
      }
    }
  }
  tags: {
    'azd-service-name': 'config-server'
    'azd-env-name': environmentName
  }
}

// Gateway Service Container App
resource gatewayServiceApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppNames.gatewayService
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    environmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 8080
        allowInsecure: false
        corsPolicy: {
          allowedOrigins: ['*']
          allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
          allowedHeaders: ['*']
          allowCredentials: false
        }
      }
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: managedIdentity.id
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'gateway-service'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              name: 'SPRING_PROFILES_ACTIVE'
              value: springProfilesActive
            }
            {
              name: 'EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE'
              value: 'http://${eurekaServerApp.properties.configuration.ingress.fqdn}/eureka/'
            }
            {
              name: 'SPRING_CLOUD_CONFIG_URI'
              value: 'http://${configServerApp.properties.configuration.ingress.fqdn}'
            }
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: applicationInsights.properties.ConnectionString
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 5
      }
    }
  }
  tags: {
    'azd-service-name': 'gateway-service'
    'azd-env-name': environmentName
  }
}

// User Service Container App
resource userServiceApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppNames.userService
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    environmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: false
        targetPort: 8080
        allowInsecure: false
        corsPolicy: {
          allowedOrigins: ['*']
          allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
          allowedHeaders: ['*']
          allowCredentials: false
        }
      }
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: managedIdentity.id
        }
      ]
      secrets: [
        {
          name: 'db-password'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/database-password'
          identity: managedIdentity.id
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'user-service'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              name: 'SPRING_PROFILES_ACTIVE'
              value: springProfilesActive
            }
            {
              name: 'EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE'
              value: 'http://${eurekaServerApp.properties.configuration.ingress.fqdn}/eureka/'
            }
            {
              name: 'SPRING_CLOUD_CONFIG_URI'
              value: 'http://${configServerApp.properties.configuration.ingress.fqdn}'
            }
            {
              name: 'SPRING_DATASOURCE_URL'
              value: 'jdbc:postgresql://${postgresqlServer.properties.fullyQualifiedDomainName}:5432/userdb'
            }
            {
              name: 'SPRING_DATASOURCE_USERNAME'
              value: databaseAdministratorLogin
            }
            {
              name: 'SPRING_DATASOURCE_PASSWORD'
              secretRef: 'db-password'
            }
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: applicationInsights.properties.ConnectionString
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 5
      }
    }
  }
  tags: {
    'azd-service-name': 'user-service'
    'azd-env-name': environmentName
  }
}

// Product Service Container App
resource productServiceApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppNames.productService
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    environmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: false
        targetPort: 8080
        allowInsecure: false
        corsPolicy: {
          allowedOrigins: ['*']
          allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
          allowedHeaders: ['*']
          allowCredentials: false
        }
      }
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: managedIdentity.id
        }
      ]
      secrets: [
        {
          name: 'db-password'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/database-password'
          identity: managedIdentity.id
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'product-service'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              name: 'SPRING_PROFILES_ACTIVE'
              value: springProfilesActive
            }
            {
              name: 'EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE'
              value: 'http://${eurekaServerApp.properties.configuration.ingress.fqdn}/eureka/'
            }
            {
              name: 'SPRING_CLOUD_CONFIG_URI'
              value: 'http://${configServerApp.properties.configuration.ingress.fqdn}'
            }
            {
              name: 'SPRING_DATASOURCE_URL'
              value: 'jdbc:postgresql://${postgresqlServer.properties.fullyQualifiedDomainName}:5432/productdb'
            }
            {
              name: 'SPRING_DATASOURCE_USERNAME'
              value: databaseAdministratorLogin
            }
            {
              name: 'SPRING_DATASOURCE_PASSWORD'
              secretRef: 'db-password'
            }
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: applicationInsights.properties.ConnectionString
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 5
      }
    }
  }
  tags: {
    'azd-service-name': 'product-service'
    'azd-env-name': environmentName
  }
}

// Order Service Container App
resource orderServiceApp 'Microsoft.App/containerApps@2024-03-01' = {
  name: containerAppNames.orderService
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentity.id}': {}
    }
  }
  properties: {
    environmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: false
        targetPort: 8080
        allowInsecure: false
        corsPolicy: {
          allowedOrigins: ['*']
          allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
          allowedHeaders: ['*']
          allowCredentials: false
        }
      }
      registries: [
        {
          server: containerRegistry.properties.loginServer
          identity: managedIdentity.id
        }
      ]
      secrets: [
        {
          name: 'db-password'
          keyVaultUrl: '${keyVault.properties.vaultUri}secrets/database-password'
          identity: managedIdentity.id
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'order-service'
          image: 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
          env: [
            {
              name: 'SPRING_PROFILES_ACTIVE'
              value: springProfilesActive
            }
            {
              name: 'EUREKA_CLIENT_SERVICE_URL_DEFAULTZONE'
              value: 'http://${eurekaServerApp.properties.configuration.ingress.fqdn}/eureka/'
            }
            {
              name: 'SPRING_CLOUD_CONFIG_URI'
              value: 'http://${configServerApp.properties.configuration.ingress.fqdn}'
            }
            {
              name: 'SPRING_DATASOURCE_URL'
              value: 'jdbc:postgresql://${postgresqlServer.properties.fullyQualifiedDomainName}:5432/orderdb'
            }
            {
              name: 'SPRING_DATASOURCE_USERNAME'
              value: databaseAdministratorLogin
            }
            {
              name: 'SPRING_DATASOURCE_PASSWORD'
              secretRef: 'db-password'
            }
            {
              name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
              value: applicationInsights.properties.ConnectionString
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 5
      }
    }
  }
  tags: {
    'azd-service-name': 'order-service'
    'azd-env-name': environmentName
  }
}

// Outputs
@description('Resource Group ID')
output RESOURCE_GROUP_ID string = resourceGroup().id

@description('Azure Container Registry Endpoint')
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.properties.loginServer

@description('Container Apps Environment Name')
output CONTAINER_APPS_ENVIRONMENT_NAME string = containerAppsEnvironment.name

@description('Application Insights Connection String')
output APPLICATIONINSIGHTS_CONNECTION_STRING string = applicationInsights.properties.ConnectionString

@description('Database Server FQDN')
output DATABASE_FQDN string = postgresqlServer.properties.fullyQualifiedDomainName

@description('Eureka Server URL')
output EUREKA_SERVER_URL string = 'https://${eurekaServerApp.properties.configuration.ingress.fqdn}'

@description('Config Server URL')
output CONFIG_SERVER_URL string = 'https://${configServerApp.properties.configuration.ingress.fqdn}'

@description('Gateway Service URL')
output GATEWAY_SERVICE_URL string = 'https://${gatewayServiceApp.properties.configuration.ingress.fqdn}'
