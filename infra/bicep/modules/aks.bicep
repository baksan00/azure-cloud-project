targetScope = 'resourceGroup'

@description('Azure region.')
param location string

@description('Common tags.')
param tags object

@description('AKS subnet ID.')
param aksSubnetId string

@description('Log Analytics Workspace resource ID.')
param logAnalyticsWorkspaceResourceId string

@description('AKS Kubernetes version.')
param kubernetesVersion string = '1.34.7'

@description('AKS node VM size.')
param nodeVmSize string = 'Standard_B2s'

@description('AKS node count.')
param nodeCount int = 1

var aksName = 'aks-algebra-${uniqueString(resourceGroup().id)}'
var dnsPrefix = 'aks-algebra-${uniqueString(resourceGroup().id)}'

resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-10-01' = {
  name: aksName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Base'
    tier: 'Standard'
  }
  properties: {
    kubernetesVersion: kubernetesVersion
    dnsPrefix: dnsPrefix

    agentPoolProfiles: [
      {
        name: 'systempool'
        count: nodeCount
        vmSize: nodeVmSize
        osType: 'Linux'
        osSKU: 'Ubuntu'
        mode: 'System'
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: aksSubnetId
        enableAutoScaling: false
        maxPods: 30
      }
    ]

    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'
      serviceCidr: '10.30.0.0/16'
      dnsServiceIP: '10.30.0.10'
      outboundType: 'loadBalancer'
      loadBalancerSku: 'standard'
    }

    addonProfiles: {
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalyticsWorkspaceResourceId
        }
      }
    }

    oidcIssuerProfile: {
      enabled: true
    }

    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }

    autoUpgradeProfile: {
      upgradeChannel: 'patch'
      nodeOSUpgradeChannel: 'NodeImage'
    }

    apiServerAccessProfile: {
      enablePrivateCluster: false
    }
  }
}

output aksName string = aksCluster.name
output aksId string = aksCluster.id
output aksPrincipalId string = aksCluster.identity.principalId
output aksKubeletObjectId string = aksCluster.properties.identityProfile.kubeletidentity.objectId

