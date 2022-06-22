AKS_RESOURCE_GROUP=AKS-CLI-RG-007
AKS_REGION=westeurope
AKS_CLUSTER=AKS-CLI
AKS_WORSPACE=AKSWorkspaceCLI
AKS_ACR=aksacrcli

az group create \
   --location ${AKS_REGION} \
   --name ${AKS_RESOURCE_GROUP}

IDENTITY_ID=$(az identity create \
    --resource-group ${AKS_RESOURCE_GROUP} \
    --name idAks \
    --location ${AKS_REGION} \
    --query id \
    --output tsv)

az network public-ip create \
    --resource-group ${AKS_RESOURCE_GROUP} \
    --name natGatewaypIpAks \
    --location ${AKS_REGION} \
    --sku standard       

az network nat gateway create \
    --resource-group ${AKS_RESOURCE_GROUP} \
    --name natGatewayAks \
    --location ${AKS_REGION} \
    --public-ip-addresses natGatewaypIpAks

az network vnet create \
    --resource-group ${AKS_RESOURCE_GROUP} \
    --name AKSvnet \
    --location ${AKS_REGION} \
    --address-prefixes 172.16.0.0/20

SUBNET_ID=$(az network vnet subnet create \
    --resource-group ${AKS_RESOURCE_GROUP} \
    --vnet-name AKSvnet \
    --name natclusterAKS \
    --address-prefixes 172.16.0.0/22 \
    --nat-gateway natGatewayAks \
    --query id \
    --output tsv)

AKS_MONITORING_LOG_ANALYTICS_WORKSPACE_ID=$(
   az monitor log-analytics workspace create \
      --resource-group ${AKS_RESOURCE_GROUP} \
      --workspace-name ${AKS_WORSPACE} \
      --location ${AKS_REGION} \
      --query id \
      -o tsv
)

az acr create \
  --name ${AKS_ACR} \
  --resource-group ${AKS_RESOURCE_GROUP} \
  --sku basic

az aks create \
    --resource-group ${AKS_RESOURCE_GROUP} \
    --name ${AKS_CLUSTER} \
    --location ${AKS_REGION} \
    --network-plugin azure \
    --generate-ssh-keys \
    --node-count 1 \
    --enable-cluster-autoscaler \
    --min-count 1 \
    --max-count 3 \
    --vnet-subnet-id $SUBNET_ID \
    --outbound-type userAssignedNATGateway \
    --enable-managed-identity \
    --assign-identity $IDENTITY_ID \
    --enable-addons monitoring \
    --workspace-resource-id ${AKS_MONITORING_LOG_ANALYTICS_WORKSPACE_ID} \
    --attach-acr ${AKS_ACR} \