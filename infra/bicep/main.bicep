targetScope = 'subscription'

@description('Azure region.')
param location string = 'westeurope'

@description('Main resource group name.')
param resourceGroupName string = 'rg-algebra-cloud-project'

@description('Your public IP address allowed for RDP.')
param allowedRdpSourceIp string

@description('Deploy Windows Jump VM.')
param deployJumpVm bool = true

@description('Deploy Key Vault.')
param deployKeyVault bool = true

@description('Deploy Storage Account, Blob container and Azure Files share.')
param deployStorage bool = true

@description('Local admin username for Jump VM.')
param jumpVmAdminUsername string = 'azureadmin'

@description('Deploy Azure Container Registry.')
param deployAcr bool = false

@description('Deploy Azure Database for PostgreSQL Flexible Server.')
param deployPostgreSql bool = false

@description('Deploy AKS cluster.')
param deployAks bool = false

@description('AKS Kubernetes version.')
param aksKubernetesVersion string = '1.34.7'

@description('AKS node VM size.')
param aksNodeVmSize string = 'Standard_B2s'

@description('AKS node count.')
param aksNodeCount int = 1

@description('Deploy Function App.')
param deployFunctionApp bool = false

@description('Deploy Application Gateway.')
param deployApplicationGateway bool = false

@description('Key Vault certificate secret ID for Application Gateway SSL.')
param appGatewaySslCertificateSecretId string = ''

@description('Private IP address of AKS internal Load Balancer service.')
param aksBackendIp string = '10.20.2.100'

@description('Function App default host name.')
param functionAppHostName string = 'func-algebra-zlaw4gihnefg6.azurewebsites.net'

@description('Deploy RBAC role assignments.')
param deployRoleAssignments bool = true

@description('Deploy diagnostic settings.')
param deployDiagnostics bool = false

@secure()
@description('Local admin password for Jump VM.')
param jumpVmAdminPassword string

@secure()
@description('PostgreSQL admin password stored in Key Vault as secret.')
param postgresAdminPassword string

var tags = {
  university: 'Fakultet'
  student: 'student@fakultet.hr'
  environment: 'dev'
  project: 'administering-cloud-solutions'
}

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module networking 'modules/networking.bicep' = {
  name: 'networking'
  scope: rg
  params: {
    location: location
    tags: tags
    allowedRdpSourceIp: allowedRdpSourceIp
  }
}

module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  scope: rg
  params: {
    location: location
    tags: tags
  }
}

module identities 'modules/identities.bicep' = {
  name: 'identities'
  scope: rg
  params: {
    location: location
    tags: tags
  }
}

module keyvault 'modules/keyvault.bicep' = if (deployKeyVault) {
  name: 'keyvault'
  scope: rg
  params: {
    location: location
    tags: tags
    postgresAdminPassword: postgresAdminPassword
  }
}

module jumpVm 'modules/jump-vm.bicep' = if (deployJumpVm) {
  name: 'jump-vm'
  scope: rg
  params: {
    location: location
    tags: tags
    jumpSubnetId: networking.outputs.jumpSubnetId
    adminUsername: jumpVmAdminUsername
    adminPassword: jumpVmAdminPassword
  }
}

module storage 'modules/storage.bicep' = if (deployStorage) {
  name: 'storage'
  scope: rg
  params: {
    location: location
    tags: tags
    privateEndpointsSubnetId: networking.outputs.privateEndpointsSubnetId
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
  }
}

module acr 'modules/acr.bicep' = if (deployAcr) {
  name: 'acr'
  scope: rg
  params: {
    location: location
    tags: tags
  }
}

module postgresql 'modules/postgresql.bicep' = if (deployPostgreSql) {
  name: 'postgresql'
  scope: rg
  params: {
    location: location
    tags: tags
    postgresqlSubnetId: networking.outputs.postgresqlSubnetId
    applicationVnetId: networking.outputs.applicationVnetId
    managementVnetId: networking.outputs.managementVnetId
    postgresAdminPassword: postgresAdminPassword
  }
}

module aks 'modules/aks.bicep' = if (deployAks) {
  name: 'aks'
  scope: rg
  params: {
    location: location
    tags: tags
    aksSubnetId: networking.outputs.aksSubnetId
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
    kubernetesVersion: aksKubernetesVersion
    nodeVmSize: aksNodeVmSize
    nodeCount: aksNodeCount
  }
}

module roleAssignments 'modules/role-assignments.bicep' = if (deployRoleAssignments && deployAks && deployAcr && deployKeyVault) {
  name: 'role-assignments'
  scope: rg
  params: {
    acrId: acr.outputs.acrId
    aksKubeletObjectId: aks.outputs.aksKubeletObjectId
    aksPrincipalId: aks.outputs.aksPrincipalId
    applicationVnetId: networking.outputs.applicationVnetId
    keyVaultId: keyvault.outputs.keyVaultId
    appGatewayIdentityPrincipalId: identities.outputs.appGatewayIdentityPrincipalId
  }
}

module functionApp 'modules/function-app.bicep' = if (deployFunctionApp) {
  name: 'function-app'
  scope: rg
  params: {
    location: location
    tags: tags
    functionSubnetId: networking.outputs.functionSubnetId
  }
}

module appGateway 'modules/app-gateway.bicep' = if (deployApplicationGateway) {
  name: 'app-gateway'
  scope: rg
  params: {
    location: location
    tags: tags
    appGatewaySubnetId: networking.outputs.appGatewaySubnetId
    appGatewayIdentityId: identities.outputs.appGatewayIdentityId
    sslCertificateSecretId: appGatewaySslCertificateSecretId
    aksBackendIp: aksBackendIp
    functionAppHostName: functionAppHostName
  }
}

module diagnostics 'modules/diagnostics.bicep' = if (deployDiagnostics && deployApplicationGateway && deployKeyVault) {
  name: 'diagnostics'
  scope: rg
  params: {
    logAnalyticsWorkspaceResourceId: monitoring.outputs.logAnalyticsWorkspaceResourceId
    appGatewayName: appGateway!.outputs.appGatewayName
    keyVaultName: keyvault.outputs.keyVaultName
  }
}

output resourceGroupName string = rg.name
output managementVnetName string = networking.outputs.managementVnetName
output applicationVnetName string = networking.outputs.applicationVnetName
output logAnalyticsWorkspaceName string = monitoring.outputs.logAnalyticsWorkspaceName
output aksWorkloadIdentityName string = identities.outputs.aksWorkloadIdentityId
output storageAccountName string = deployStorage ? storage.outputs.storageAccountName : ''
