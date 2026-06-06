targetScope = 'resourceGroup'

@description('Azure region.')
param location string

@description('Common tags.')
param tags object

@description('Application Gateway subnet ID.')
param appGatewaySubnetId string

@description('Application Gateway managed identity resource ID.')
param appGatewayIdentityId string

@description('Key Vault certificate secret ID.')
param sslCertificateSecretId string

@description('Private IP address of AKS internal Load Balancer service.')
param aksBackendIp string = '10.20.2.100'

@description('Function App default hostname.')
param functionAppHostName string

var appGatewayName = 'agw-algebra-${uniqueString(resourceGroup().id)}'
var publicIpName = 'pip-appgw'
var frontendIpConfigName = 'appGwFrontendIp'
var frontendPortHttpsName = 'port-https'
var sslCertName = 'ssl-cert-keyvault'
var listenerHttpsName = 'listener-https'
var urlPathMapName = 'path-map'
var ruleName = 'rule-path-routing'

var aksBackendPoolName = 'backend-aks'
var functionBackendPoolName = 'backend-function'

var aksHttpSettingsName = 'http-settings-aks'
var functionHttpSettingsName = 'http-settings-function'

var aksProbeName = 'probe-aks'
var functionProbeName = 'probe-function'

resource appGatewayIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: last(split(appGatewayIdentityId, '/'))
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2024-07-01' = {
  name: publicIpName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource appGateway 'Microsoft.Network/applicationGateways@2024-07-01' = {
  name: appGatewayName
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${appGatewayIdentity.id}': {}
    }
  }
  properties: {
    sku: {
      name: 'Standard_v2'
      tier: 'Standard_v2'
      capacity: 1
    }

    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: appGatewaySubnetId
          }
        }
      }
    ]

    frontendIPConfigurations: [
      {
        name: frontendIpConfigName
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]

    frontendPorts: [
      {
        name: frontendPortHttpsName
        properties: {
          port: 443
        }
      }
    ]

    sslCertificates: [
      {
        name: sslCertName
        properties: {
          keyVaultSecretId: sslCertificateSecretId
        }
      }
    ]

    backendAddressPools: [
      {
        name: aksBackendPoolName
        properties: {
          backendAddresses: [
            {
              ipAddress: aksBackendIp
            }
          ]
        }
      }
      {
        name: functionBackendPoolName
        properties: {
          backendAddresses: [
            {
              fqdn: functionAppHostName
            }
          ]
        }
      }
    ]

    probes: [
      {
        name: aksProbeName
        properties: {
          protocol: 'Http'
          host: aksBackendIp
          path: '/'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
          minServers: 0
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
      {
        name: functionProbeName
        properties: {
          protocol: 'Https'
          host: functionAppHostName
          path: '/functionap'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
          minServers: 0
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
    ]

    backendHttpSettingsCollection: [
      {
        name: aksHttpSettingsName
        properties: {
          protocol: 'Http'
          port: 80
          requestTimeout: 30
          cookieBasedAffinity: 'Disabled'
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGatewayName, aksProbeName)
          }
        }
      }
      {
        name: functionHttpSettingsName
        properties: {
          protocol: 'Https'
          port: 443
          requestTimeout: 30
          cookieBasedAffinity: 'Disabled'
          hostName: functionAppHostName
          pickHostNameFromBackendAddress: false
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGatewayName, functionProbeName)
          }
        }
      }
    ]

    httpListeners: [
      {
        name: listenerHttpsName
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGatewayName, frontendIpConfigName)
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, frontendPortHttpsName)
          }
          protocol: 'Https'
          sslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', appGatewayName, sslCertName)
          }
        }
      }
    ]

    urlPathMaps: [
      {
        name: urlPathMapName
        properties: {
          defaultBackendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName, aksBackendPoolName)
          }
          defaultBackendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGatewayName, aksHttpSettingsName)
          }
          pathRules: [
            {
              name: 'path-aks'
              properties: {
                paths: [
                  '/aks'
                  '/aks/*'
                ]
                backendAddressPool: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName, aksBackendPoolName)
                }
                backendHttpSettings: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGatewayName, aksHttpSettingsName)
                }
              }
            }
            {
              name: 'path-functionap'
              properties: {
                paths: [
                  '/functionap'
                  '/functionap/*'
                ]
                backendAddressPool: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName, functionBackendPoolName)
                }
                backendHttpSettings: {
                  id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGatewayName, functionHttpSettingsName)
                }
              }
            }
          ]
        }
      }
    ]

    requestRoutingRules: [
      {
        name: ruleName
        properties: {
          ruleType: 'PathBasedRouting'
          priority: 100
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGatewayName, listenerHttpsName)
          }
          urlPathMap: {
            id: resourceId('Microsoft.Network/applicationGateways/urlPathMaps', appGatewayName, urlPathMapName)
          }
        }
      }
    ]
  }
}

output appGatewayName string = appGateway.name
output appGatewayId string = appGateway.id
output appGatewayPublicIpName string = publicIp.name
output appGatewayPublicIpAddress string = publicIp.properties.ipAddress
