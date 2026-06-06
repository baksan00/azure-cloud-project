targetScope = 'resourceGroup'

@description('ACR resource ID.')
param acrId string

@description('AKS kubelet identity object ID. Used for pulling images from ACR.')
param aksKubeletObjectId string

@description('AKS managed identity principal ID. Used for Azure networking operations.')
param aksPrincipalId string

@description('Application VNET ID.')
param applicationVnetId string

@description('Key Vault resource ID.')
param keyVaultId string

@description('Application Gateway user assigned identity principal ID.')
param appGatewayIdentityPrincipalId string

var acrPullRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '7f951dda-4ed3-4680-a7ca-43fe172d538d'
)

var networkContributorRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '4d97b98b-1d4f-4787-a291-c67834d212e7'
)

var keyVaultSecretsUserRoleDefinitionId = subscriptionResourceId(
  'Microsoft.Authorization/roleDefinitions',
  '4633458b-17de-408a-b874-0445c86b69e6'
)

resource acrResource 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = {
  name: last(split(acrId, '/'))
}

resource applicationVnet 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  name: last(split(applicationVnetId, '/'))
}

resource keyVaultResource 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: last(split(keyVaultId, '/'))
}

resource aksAcrPullAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(acrId, aksKubeletObjectId, acrPullRoleDefinitionId)
  scope: acrResource
  properties: {
    roleDefinitionId: acrPullRoleDefinitionId
    principalId: aksKubeletObjectId
    principalType: 'ServicePrincipal'
  }
}

resource aksNetworkContributorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(applicationVnetId, aksPrincipalId, networkContributorRoleDefinitionId)
  scope: applicationVnet
  properties: {
    roleDefinitionId: networkContributorRoleDefinitionId
    principalId: aksPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource appGatewayKeyVaultSecretsUserAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVaultId, appGatewayIdentityPrincipalId, keyVaultSecretsUserRoleDefinitionId)
  scope: keyVaultResource
  properties: {
    roleDefinitionId: keyVaultSecretsUserRoleDefinitionId
    principalId: appGatewayIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}
