#!/bin/bash
AKS_RESOURCE_GROUP=RG-AKS-CLI
AKS_REGION=westeurope

AKS_VNET=aks-vnet
AKS_VNET_ADDRESS_PREFIX=10.0.0.0/8
AKS_VNET_SUBNET_DEFAULT=aks-subnet-default
AKS_VNET_SUBNET_DEFAULT_PREFIX=10.240.0.0/16
AKS_VNET_SUBNET_VIRTUALNODES=aks-subnet-virtual-nodes
AKS_VNET_SUBNET_VIRTUALNODES_PREFIX=10.241.0.0/16

# Create Resource Group
echo -e "${vert}Creation du Resource Group"
az group create --location ${AKS_REGION} \
                --name ${AKS_RESOURCE_GROUP}

# Create Virtual Network & default Subnet
echo "Creation du Vnet & Subnet default"
az network vnet create -g ${AKS_RESOURCE_GROUP} \
                       -n ${AKS_VNET} \
                       --address-prefix ${AKS_VNET_ADDRESS_PREFIX} \
                       --subnet-name ${AKS_VNET_SUBNET_DEFAULT} \
                       --subnet-prefix ${AKS_VNET_SUBNET_DEFAULT_PREFIX}

# Create Virtual Nodes Subnet in Virtual Network
echo "Creation du Node Subnet"
az network vnet subnet create --resource-group ${AKS_RESOURCE_GROUP} \
                              --vnet-name ${AKS_VNET} \
                              --name ${AKS_VNET_SUBNET_VIRTUALNODES} \
                              --address-prefixes ${AKS_VNET_SUBNET_VIRTUALNODES_PREFIX}

# Get Virtual Network default subnet id
echo "recupération de l'Id du Subnet Default"
AKS_VNET_SUBNET_DEFAULT_ID=$(az network vnet subnet show \
                           --resource-group ${AKS_RESOURCE_GROUP} \
                           --vnet-name ${AKS_VNET} \
                           --name ${AKS_VNET_SUBNET_DEFAULT} \
                           --query id \
                           -o tsv)
echo ${AKS_VNET_SUBNET_DEFAULT_ID}

AKS_AD_AKSADMIN_GROUP_ID=$(az ad group create --display-name aksadmins --mail-nickname aksadmins --query id -o tsv)    
echo $AKS_AD_AKSADMIN_GROUP_ID

# Create Azure AD AKS Admin User 
# Replace with your AD Domain - aksadmin1@stacksimplifygmail.onmicrosoft.com
AKS_AD_AKSADMIN1_USER_OBJECT_ID=$(az ad user create \
  --display-name "AKS Admin1" \
  --user-principal-name aksadmin1@admapme.onmicrosoft.com \
  --password @AKSDemo123 \
  --query id -o tsv)
echo $AKS_AD_AKSADMIN1_USER_OBJECT_ID

az ad group member add --group aksadmins --member-id $AKS_AD_AKSADMIN1_USER_OBJECT_ID

AKS_MONITORING_LOG_ANALYTICS_WORKSPACE_ID=$(az monitor log-analytics workspace create \
                                           --resource-group ${AKS_RESOURCE_GROUP} \
                                           --workspace-name aksprod-loganalytics-workspace1 \
                                           --query id \
                                           -o tsv)
echo $AKS_MONITORING_LOG_ANALYTICS_WORKSPACE_ID

