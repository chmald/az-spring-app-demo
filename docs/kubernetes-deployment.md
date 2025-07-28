# Kubernetes Deployment Guide

## Overview

This guide provides instructions for deploying the Azure Spring Apps Demo to Kubernetes, including Azure Kubernetes Service (AKS) and local Kubernetes clusters.

## Prerequisites

- Azure CLI installed and configured
- kubectl installed
- Docker installed (for building images)
- Access to Azure Container Registry
- Azure Kubernetes Service cluster (or local Kubernetes cluster)

## Kubernetes Resources

### Architecture

The Kubernetes deployment includes:

- **Infrastructure Services**: Eureka Server, Config Server, Gateway Service
- **Business Services**: User Service, Product Service, Order Service
- **Configuration**: ConfigMaps and Secrets for application configuration
- **Networking**: Services and LoadBalancers for service communication

### Resource Organization

```
k8s/
├── base/                          # Base Kubernetes manifests
│   ├── configmaps-secrets.yaml   # Configuration and secrets
│   ├── eureka-server.yaml        # Service discovery
│   ├── config-server.yaml        # Configuration management
│   ├── gateway-service.yaml      # API Gateway
│   ├── user-service.yaml         # User management
│   ├── product-service.yaml      # Product catalog
│   └── order-service.yaml        # Order processing
└── overlays/                     # Environment-specific overrides
    ├── development/
    └── production/
```

## Deployment Steps

### Step 1: Prepare Azure Resources

1. **Create Azure Kubernetes Service (AKS)**:
   ```bash
   # Create resource group
   az group create --name az-spring-app-demo-rg --location eastus
   
   # Create AKS cluster
   az aks create \
     --resource-group az-spring-app-demo-rg \
     --name az-spring-app-demo-aks \
     --node-count 3 \
     --node-vm-size Standard_D2s_v3 \
     --enable-addons monitoring \
     --generate-ssh-keys
   ```

2. **Create Azure Container Registry**:
   ```bash
   az acr create \
     --resource-group az-spring-app-demo-rg \
     --name azspringappdemo \
     --sku Basic \
     --admin-enabled true
   ```

3. **Attach ACR to AKS**:
   ```bash
   az aks update \
     --resource-group az-spring-app-demo-rg \
     --name az-spring-app-demo-aks \
     --attach-acr azspringappdemo
   ```

### Step 2: Build and Push Images

1. **Build applications**:
   ```bash
   mvn clean package -DskipTests
   ```

2. **Login to ACR**:
   ```bash
   az acr login --name azspringappdemo
   ```

3. **Build and push Docker images**:
   ```bash
   # Array of services
   services=("eureka-server" "config-server" "gateway-service" "user-service" "product-service" "order-service")
   
   for service in "${services[@]}"; do
     echo "Building $service..."
     
     # Create Dockerfile
     cat > $service/Dockerfile <<EOF
   FROM eclipse-temurin:17-jre-noble
   
   # Install curl for health checks
   RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
   
   # Add Application Insights agent
   ADD https://github.com/microsoft/ApplicationInsights-Java/releases/download/3.4.18/applicationinsights-agent-3.4.18.jar /app/applicationinsights-agent.jar
   
   COPY target/$service-1.0.0.jar /app/app.jar
   
   EXPOSE 8080
   
   ENTRYPOINT ["java", "-javaagent:/app/applicationinsights-agent.jar", "-jar", "/app/app.jar"]
   EOF
     
     # Build and push
     docker build -t azspringappdemo.azurecr.io/$service:latest $service/
     docker push azspringappdemo.azurecr.io/$service:latest
   done
   ```

### Step 3: Configure Kubernetes

1. **Get AKS credentials**:
   ```bash
   az aks get-credentials --resource-group az-spring-app-demo-rg --name az-spring-app-demo-aks
   ```

2. **Create namespace** (optional):
   ```bash
   kubectl create namespace spring-demo
   kubectl config set-context --current --namespace=spring-demo
   ```

3. **Configure secrets** in `k8s/base/configmaps-secrets.yaml`:
   ```yaml
   # Update with your actual values
   apiVersion: v1
   kind: Secret
   metadata:
     name: azure-secrets
   type: Opaque
   data:
     # Base64 encoded values
     AZURE_KEYVAULT_ENDPOINT: <base64-encoded-keyvault-url>
     APPLICATIONINSIGHTS_CONNECTION_STRING: <base64-encoded-ai-connection-string>
     DB_USERNAME: <base64-encoded-db-username>
     DB_PASSWORD: <base64-encoded-db-password>
     AZURE_SERVICEBUS_CONNECTION_STRING: <base64-encoded-servicebus-connection>
   ```

   To encode values:
   ```bash
   echo -n "your-value" | base64
   ```

### Step 4: Deploy to Kubernetes

1. **Deploy configurations first**:
   ```bash
   kubectl apply -f k8s/base/configmaps-secrets.yaml
   ```

2. **Deploy infrastructure services**:
   ```bash
   # Deploy Eureka Server first
   kubectl apply -f k8s/base/eureka-server.yaml
   
   # Wait for Eureka to be ready
   kubectl wait --for=condition=available --timeout=300s deployment/eureka-server
   
   # Deploy Config Server
   kubectl apply -f k8s/base/config-server.yaml
   kubectl wait --for=condition=available --timeout=300s deployment/config-server
   
   # Deploy Gateway
   kubectl apply -f k8s/base/gateway-service.yaml
   kubectl wait --for=condition=available --timeout=300s deployment/gateway-service
   ```

3. **Deploy business services**:
   ```bash
   # Deploy all business services
   kubectl apply -f k8s/base/user-service.yaml
   kubectl apply -f k8s/base/product-service.yaml
   kubectl apply -f k8s/base/order-service.yaml
   
   # Wait for all to be ready
   kubectl wait --for=condition=available --timeout=300s deployment/user-service
   kubectl wait --for=condition=available --timeout=300s deployment/product-service
   kubectl wait --for=condition=available --timeout=300s deployment/order-service
   ```

### Step 5: Verify Deployment

1. **Check pod status**:
   ```bash
   kubectl get pods
   ```

2. **Check services**:
   ```bash
   kubectl get services
   ```

3. **Get external IP of Gateway**:
   ```bash
   kubectl get service gateway-service
   ```

4. **Test application**:
   ```bash
   # Replace <EXTERNAL-IP> with the actual external IP
   curl http://<EXTERNAL-IP>:8080/actuator/health
   ```

## Configuration Management

### Environment-Specific Configuration

For different environments, create overlay configurations:

**Development Overlay** (`k8s/overlays/development/kustomization.yaml`):
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: spring-demo-dev

resources:
- ../../base

patchesStrategicMerge:
- replica-patch.yaml

images:
- name: azspringappdemo.azurecr.io/eureka-server
  newTag: develop
- name: azspringappdemo.azurecr.io/config-server
  newTag: develop
```

**Production Overlay** (`k8s/overlays/production/kustomization.yaml`):
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: spring-demo-prod

resources:
- ../../base

patchesStrategicMerge:
- replica-patch.yaml
- resource-patch.yaml

images:
- name: azspringappdemo.azurecr.io/eureka-server
  newTag: latest
```

Deploy with Kustomize:
```bash
# Development
kubectl apply -k k8s/overlays/development

# Production
kubectl apply -k k8s/overlays/production
```

## Monitoring and Logging

### Application Insights

Application Insights automatically collects:
- Request telemetry
- Dependency tracking
- Exception information
- Custom metrics

### Kubernetes Monitoring

1. **Enable Azure Monitor for Containers**:
   ```bash
   az aks enable-addons \
     --resource-group az-spring-app-demo-rg \
     --name az-spring-app-demo-aks \
     --addons monitoring
   ```

2. **View logs**:
   ```bash
   # View pod logs
   kubectl logs -f deployment/gateway-service
   
   # View logs for all pods of a service
   kubectl logs -f -l app=user-service
   ```

### Prometheus and Grafana (Optional)

1. **Install Prometheus**:
   ```bash
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm install prometheus prometheus-community/kube-prometheus-stack
   ```

2. **Access Grafana**:
   ```bash
   kubectl port-forward service/prometheus-grafana 3000:80
   ```

## Scaling and Performance

### Horizontal Pod Autoscaling

1. **Create HPA for services**:
   ```yaml
   apiVersion: autoscaling/v2
   kind: HorizontalPodAutoscaler
   metadata:
     name: gateway-service-hpa
   spec:
     scaleTargetRef:
       apiVersion: apps/v1
       kind: Deployment
       name: gateway-service
     minReplicas: 2
     maxReplicas: 10
     metrics:
     - type: Resource
       resource:
         name: cpu
         target:
           type: Utilization
           averageUtilization: 70
   ```

2. **Apply HPA**:
   ```bash
   kubectl apply -f hpa.yaml
   ```

### Cluster Autoscaling

Enable cluster autoscaling for AKS:
```bash
az aks update \
  --resource-group az-spring-app-demo-rg \
  --name az-spring-app-demo-aks \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 10
```

## Security

### Pod Security Standards

1. **Create Pod Security Policy**:
   ```yaml
   apiVersion: policy/v1beta1
   kind: PodSecurityPolicy
   metadata:
     name: spring-demo-psp
   spec:
     privileged: false
     allowPrivilegeEscalation: false
     requiredDropCapabilities:
       - ALL
     volumes:
       - 'configMap'
       - 'emptyDir'
       - 'projected'
       - 'secret'
       - 'downwardAPI'
       - 'persistentVolumeClaim'
     runAsUser:
       rule: 'MustRunAsNonRoot'
     seLinux:
       rule: 'RunAsAny'
     fsGroup:
       rule: 'RunAsAny'
   ```

### Network Policies

1. **Create Network Policy**:
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: spring-demo-network-policy
   spec:
     podSelector:
       matchLabels:
         component: business
     policyTypes:
     - Ingress
     - Egress
     ingress:
     - from:
       - podSelector:
           matchLabels:
             component: infrastructure
   ```

## Troubleshooting

### Common Issues

1. **ImagePullBackOff**:
   ```bash
   # Check if ACR is attached to AKS
   az aks show --resource-group rg-name --name aks-name --query "servicePrincipalProfile"
   
   # Check image exists in ACR
   az acr repository list --name azspringappdemo
   ```

2. **Service Discovery Issues**:
   ```bash
   # Check Eureka server logs
   kubectl logs -f deployment/eureka-server
   
   # Check service registration
   kubectl port-forward service/eureka-server 8761:8761
   # Visit http://localhost:8761
   ```

3. **Database Connection Issues**:
   ```bash
   # Check secrets
   kubectl get secret azure-secrets -o yaml
   
   # Test database connectivity from pod
   kubectl exec -it deployment/user-service -- bash
   # Inside pod: curl http://config-server:8888/user-service/k8s
   ```

### Diagnostic Commands

```bash
# Check cluster status
kubectl cluster-info

# Check node status
kubectl get nodes

# Check all resources
kubectl get all

# Describe problematic pod
kubectl describe pod <pod-name>

# Get events
kubectl get events --sort-by='.lastTimestamp'

# Check resource usage
kubectl top nodes
kubectl top pods
```

## Cleanup

### Remove Application

```bash
kubectl delete -f k8s/base/
```

### Remove Azure Resources

```bash
# Delete AKS cluster
az aks delete --resource-group az-spring-app-demo-rg --name az-spring-app-demo-aks

# Delete resource group (removes all resources)
az group delete --name az-spring-app-demo-rg
```

## Best Practices

1. **Resource Limits**: Always set resource requests and limits
2. **Health Checks**: Configure liveness and readiness probes
3. **Security**: Use non-root containers and security contexts
4. **Secrets**: Never store secrets in container images
5. **Monitoring**: Implement comprehensive monitoring and alerting
6. **Backups**: Regular backups of persistent data
7. **Updates**: Use rolling updates for zero-downtime deployments
8. **Testing**: Test deployments in staging environment first

## Next Steps

1. Set up CI/CD pipeline for automated deployments
2. Configure monitoring and alerting
3. Implement security policies
4. Set up backup and disaster recovery
5. Optimize resource usage and costs
6. Configure network policies for better security