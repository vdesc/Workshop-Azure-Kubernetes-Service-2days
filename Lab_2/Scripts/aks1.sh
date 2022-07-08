#!/bin/bash
AKS_RESOURCE_GROUP=AKS-CLI-RG-001
AKS_REGION=westeurope
AKS_CLUSTER=AKS-CLI
AKS_WORSPACE=AKSWorkspaceCLI
AKS_ACR=aksacrcli

AKS_VNET=aks-vnet
AKS_VNET_ADDRESS_PREFIX=10.0.0.0/8
AKS_VNET_SUBNET_DEFAULT=aks-subnet-default
AKS_VNET_SUBNET_DEFAULT_PREFIX=10.240.0.0/16
AKS_VNET_SUBNET_VIRTUALNODES=aks-subnet-virtual-nodes
AKS_VNET_SUBNET_VIRTUALNODES_PREFIX=10.241.0.0/16

az group create \
   --location ${AKS_REGION} \
   --name ${AKS_RESOURCE_GROUP}

az network vnet create \
   --resource-group ${AKS_RESOURCE_GROUP} \
   --name ${AKS_VNET} \
   --address-prefix ${AKS_VNET_ADDRESS_PREFIX} \
   --subnet-name ${AKS_VNET_SUBNET_DEFAULT} \
   --subnet-prefix ${AKS_VNET_SUBNET_DEFAULT_PREFIX}

AKS_VNET_SUBNET_VIRTUALNODES_ID=$(
   az network vnet subnet create \
      --resource-group ${AKS_RESOURCE_GROUP} \
      --vnet-name ${AKS_VNET} \
      --name ${AKS_VNET_SUBNET_VIRTUALNODES} \
      --address-prefixes ${AKS_VNET_SUBNET_VIRTUALNODES_PREFIX} \
      --query id \
      -o tsv
)
echo ${AKS_VNET_SUBNET_VIRTUALNODES_ID}

AKS_MONITORING_LOG_ANALYTICS_WORKSPACE_ID=$(
   az monitor log-analytics workspace create \
      --resource-group ${AKS_RESOURCE_GROUP} \
      --workspace-name ${AKS_WORSPACE} \
      --location ${AKS_REGION} \
      --query id \
      -o tsv
)
echo $AKS_MONITORING_LOG_ANALYTICS_WORKSPACE_ID

az acr create \
  --name ${AKS_ACR} \
  --resource-group ${AKS_RESOURCE_GROUP} \
  --sku basic

az aks create \
  --resource-group ${AKS_RESOURCE_GROUP} \
  --name ${AKS_CLUSTER} \
  --os-sku CBLMariner \
  --enable-managed-identity \
  --generate-ssh-keys \
  --node-count 1 \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 100 \
  --network-plugin azure \
  --service-cidr 10.0.0.0/16 \
  --dns-service-ip 10.0.0.10 \
  --docker-bridge-address 172.17.0.1/16 \
  --vnet-subnet-id ${AKS_VNET_SUBNET_VIRTUALNODES_ID} \
  --enable-addons monitoring \
  --workspace-resource-id ${AKS_MONITORING_LOG_ANALYTICS_WORKSPACE_ID} \
  --attach-acr ${AKS_ACR} \
  --yes