# Lab 4 : Activation du monitoring avec Azure Monitor
## Objectif:
Savoir utiliser Azure Monitor pour surveiller l’intégrité et les performances d’Azure Kubernetes Service (AKS). Cela comprend :<br>
- la collecte des données de télémétrie critiques pour la surveillance <br>
- l’analyse et la visualisation des données collectées pour identifier les tendances <br>
- configurer des alertes pour être informé de manière proactive des problèmes critiques <br>

1. Création de l'environnement de démonstration <br>
- Déploiement du "resource group"<br>
```
az group create \
    --location "eastus2" \
    --resource-group "RG-AKS-Lab-4"

```
- Déploiement d'un virtual network
```
az network vnet create \
    --resource-group "RG-AKS-Lab-4" \
    --name AKSvnet \
    --location "eastus2" \
    --address-prefixes 10.0.0.0/8
```
- Déploiement du subnet
```
SUBNET_ID=$(az network vnet subnet create \
    --resource-group "RG-AKS-Lab-4" \
    --vnet-name AKSvnet \
    --name subnetAKS \
    --address-prefixes 10.240.0.0/16 \
    --query id \
    --output tsv)
```
- Création d'une "Managed Identity" <br>
```
IDENTITY_ID=$(az identity create \
    --resource-group "RG-AKS-Lab-4" \
    --name idAks \
    --location "eastus2" \
    --query id \
    --output tsv)
```
- Création du "cluster AKS" <br>
```
az aks create \
    --resource-group "RG-AKS-Lab-4" \
    --name "AKS-Lab-4" \
    --location "eastus2" \
    --network-plugin azure \
    --generate-ssh-keys \
    --node-count 2 \
    --enable-cluster-autoscaler \
    --min-count 1 \
    --max-count 3 \
    --vnet-subnet-id $SUBNET_ID \
    --enable-managed-identity \
    --assign-identity $IDENTITY_ID \
    --yes

```
2. Activation du monitoring
- Création d'un "Log Analytics workspace" <br>
```
AKS_MONITORING_LOG_ANALYTICS_WORKSPACE_ID=$(
   az monitor log-analytics workspace create \
      --resource-group "RG-AKS-Lab-4"  \
      --workspace-name "Workspace-AKS-Lab-4" \
      --location "eastus2" \
      --query id \
      -o tsv
)
```
- Activation du monitoring du cluster AKS avec le "Log Analytics workspace"
```
az aks enable-addons \
   --addons monitoring \
   --name "AKS-Lab-4" \
   --resource-group "RG-AKS-Lab-4" \
   --workspace-resource-id $AKS_MONITORING_LOG_ANALYTICS_WORKSPACE_ID
```
3. Monitoring<br>
cf: https://docs.microsoft.com/fr-fr/azure/aks/monitor-aks <br>
Exemple de requetes "Kusto" : <br>
```
// Container CPU 
// View all the container CPU usage averaged over 30mins. 
// To create an alert for this query, click '+ New alert rule'
//Select the Line chart display option: can we calculate percentage?
Perf
| where ObjectName == "K8SContainer" and CounterName == "cpuUsageNanoCores"
| summarize AvgCPUUsageNanoCores = avg(CounterValue) by bin(TimeGenerated, 30m), InstanceName, _ResourceId
```
```
// Container memory 
// View container CPU averaged over 30 mins intervals. 
// To create an alert for this query, click '+ New alert rule'
//Select the Line chart display option: can we calculate percentage?
let threshold = 75000000; // choose a threshold 
Perf
| where ObjectName == "K8SContainer" and CounterName == "memoryRssBytes"
| summarize AvgUsedRssMemoryBytes = avg(CounterValue) by bin(TimeGenerated, 30m), InstanceName, _ResourceId
| where AvgUsedRssMemoryBytes > threshold 
| render timechart
```
```
// Avg node CPU usage percentage per minute  
// For your cluster view avg node CPU usage percentage per minute over the last hour. 
// To create an alert for this query, click '+ New alert rule'
//Modify the startDateTime & endDateTime to customize the timerange
let endDateTime = now();
let startDateTime = ago(1h);
let trendBinSize = 1m;
let capacityCounterName = 'cpuCapacityNanoCores';
let usageCounterName = 'cpuUsageNanoCores';
KubeNodeInventory
| where TimeGenerated < endDateTime
| where TimeGenerated >= startDateTime
// cluster filter would go here if multiple clusters are reporting to the same Log Analytics workspace
| distinct ClusterName, Computer, _ResourceId
| join hint.strategy=shuffle (
  Perf
  | where TimeGenerated < endDateTime
  | where TimeGenerated >= startDateTime
  | where ObjectName == 'K8SNode'
  | where CounterName == capacityCounterName
  | summarize LimitValue = max(CounterValue) by Computer, CounterName, bin(TimeGenerated, trendBinSize)
  | project Computer, CapacityStartTime = TimeGenerated, CapacityEndTime = TimeGenerated + trendBinSize, LimitValue
) on Computer
| join kind=inner hint.strategy=shuffle (
  Perf
  | where TimeGenerated < endDateTime + trendBinSize
  | where TimeGenerated >= startDateTime - trendBinSize
  | where ObjectName == 'K8SNode'
  | where CounterName == usageCounterName
  | project Computer, UsageValue = CounterValue, TimeGenerated
) on Computer
| where TimeGenerated >= CapacityStartTime and TimeGenerated < CapacityEndTime
| project ClusterName, Computer, TimeGenerated, UsagePercent = UsageValue * 100.0 / LimitValue, _ResourceId
| summarize AggregatedValue = avg(UsagePercent) by bin(TimeGenerated, trendBinSize), ClusterName, _ResourceId
```

