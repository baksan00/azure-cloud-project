targetScope = 'resourceGroup'

@description('Azure region.')
param location string

@description('Common tags.')
param tags object

@description('Your public IP address allowed for RDP. Example: 93.142.10.20/32')
param allowedRdpSourceIp string

var managementVnetName = 'vnet-mgmt-weu'
var applicationVnetName = 'vnet-app-weu'

var jumpSubnetName = 'snet-jump'
var appGatewaySubnetName = 'snet-appgw'
var aksSubnetName = 'snet-aks'
var functionSubnetName = 'snet-function'
var postgresqlSubnetName = 'snet-postgresql'
var privateEndpointsSubnetName = 'snet-private-endpoints'

var jumpNsgName = 'nsg-jump'

resource jumpNsg 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: jumpNsgName
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-RDP-From-Allowed-IP'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: allowedRdpSourceIp
          destinationAddressPrefix: '*'
          description: 'Allow RDP only from allowed public IP address.'
        }
      }
    ]
  }
}

resource managementVnet 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: managementVnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.0.0/16'
      ]
    }
    subnets: [
      {
        name: jumpSubnetName
        properties: {
          addressPrefix: '10.10.1.0/24'
          networkSecurityGroup: {
            id: jumpNsg.id
          }
        }
      }
    ]
  }
}

resource applicationVnet 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: applicationVnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.20.0.0/16'
      ]
    }
    subnets: [
      {
        name: appGatewaySubnetName
        properties: {
          addressPrefix: '10.20.1.0/24'
        }
      }
      {
        name: aksSubnetName
        properties: {
          addressPrefix: '10.20.2.0/23'
        }
      }
      {
        name: functionSubnetName
        properties: {
          addressPrefix: '10.20.4.0/24'
          delegations: [
            {
              name: 'delegation-app-service'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: postgresqlSubnetName
        properties: {
          addressPrefix: '10.20.5.0/24'
          delegations: [
            {
              name: 'delegation-postgresql'
              properties: {
                serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
              }
            }
          ]
        }
      }
      {
        name: privateEndpointsSubnetName
        properties: {
          addressPrefix: '10.20.6.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

resource mgmtToAppPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-07-01' = {
  name: '${managementVnetName}/peer-to-app'
  properties: {
    remoteVirtualNetwork: {
      id: applicationVnet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

resource appToMgmtPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-07-01' = {
  name: '${applicationVnetName}/peer-to-mgmt'
  properties: {
    remoteVirtualNetwork: {
      id: managementVnet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

output managementVnetName string = managementVnet.name
output applicationVnetName string = applicationVnet.name

output managementVnetId string = managementVnet.id
output applicationVnetId string = applicationVnet.id

output jumpSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', managementVnetName, jumpSubnetName)
output appGatewaySubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', applicationVnetName, appGatewaySubnetName)
output aksSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', applicationVnetName, aksSubnetName)
output functionSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', applicationVnetName, functionSubnetName)
output postgresqlSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', applicationVnetName, postgresqlSubnetName)
output privateEndpointsSubnetId string = resourceId('Microsoft.Network/virtualNetworks/subnets', applicationVnetName, privateEndpointsSubnetName)

output jumpNsgId string = jumpNsg.id
