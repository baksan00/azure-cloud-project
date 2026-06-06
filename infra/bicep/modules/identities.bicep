targetScope = 'resourceGroup'

@description('Azure region.')
param location string

@description('Common tags.')
param tags object

resource aksWorkloadIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-aks-workload'
  location: location
  tags: tags
}

resource appGatewayIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-appgw-kv'
  location: location
  tags: tags
}

resource functionIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-function-app'
  location: location
  tags: tags
}

output aksWorkloadIdentityId string = aksWorkloadIdentity.id
output aksWorkloadPrincipalId string = aksWorkloadIdentity.properties.principalId
output aksWorkloadClientId string = aksWorkloadIdentity.properties.clientId
output appGatewayIdentityId string = appGatewayIdentity.id
output appGatewayPrincipalId string = appGatewayIdentity.properties.principalId
output appGatewayClientId string = appGatewayIdentity.properties.clientId
output functionIdentityId string = functionIdentity.id
output functionPrincipalId string = functionIdentity.properties.principalId
output functionClientId string = functionIdentity.properties.clientId
output appGatewayIdentityPrincipalId string = appGatewayIdentity.properties.principalId
