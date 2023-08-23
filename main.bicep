@description('Location for all resources')
param location string = resourceGroup().location

@description('Name of the Azure OpenAI account')
param openAiAccountName string = 'oai-private-demo'

@description('Custom subdomain name for the Azure OpenAI account')
param oaiCustomSubDomainName string = 'oai-${uniqueString(resourceGroup().id)}'

@description('SKU for the Azure OpenAI account')
param oaiSku string = 'S0'

@description('Name of the Azure OpenAI Primary Key Secret for the Key Vault')
param oaiPrimaryKeySecretName string = 'OpenAIPrimaryKey'

@description('Tokens per Minute Rate Limit (thousands)')
param embeddingsDeploymentCapacity int = 1

@description('Name of the Embeddings Model to deploy')
param embeddingsModelName string = 'text-embedding-ada-002'

@description('Tokens per Minute Rate Limit (thousands)')
param gptDeploymentCapacity int = 1

@description('Name of the GPT Model to deploy')
param chatGptModelName string = 'gpt-35-turbo'

@description('The pricing tier of the API Management service')
@allowed([
  'Developer'
  'Premium'
])
param apimSku string = 'Developer'

@description('Number of instances of the API Management service to deploy')
param apimCapacity int = 1

@description('Name of the API Management service')
param apimName string = 'apim-${uniqueString(resourceGroup().id)}'

@description('The email address of the owner of the API Management service')
@minLength(1)
param apimPublisherEmail string

@description('The name of the owner of the API Management service')
@minLength(1)
param apimPublisherName string

@description('The pricing tier of the API Management service')
@allowed([
  'Internal'
  'External'
])
param apimVNetMode string = 'Internal'

@description('Name of the API Management Private DNS Zone')
param apimPrivateDnsZoneName string = 'azure-api.net'

@description('Name of the Azure Virtual Network')
param virtualNetworkName string = 'vnet-oai-demo'

@description('Name of the Azure OpenaAI Private DNS Zone')
param oaiPrivateDnsZoneName string = 'privatelink.openai.azure.com'

@description('Name of the Azure OpenaAI Private Endpoint')
param oaiPrivateEndpointName string = 'oaiDemoPrivateEndpoint'

@description('The name of the Azure Bastion host')
param bastionHostName string = 'bastion-oai-demo'

@description('Admin Username for the Virtual Machine.')
param vmAdminUsername string

@description('Admin Password for the Virtual Machine.')
@minLength(12)
@secure()
param vmAdminPassword string

@description('The Windows version for the VM')
@allowed([
  'win11-22h2-pro'
  'win11-22h2-pron'
  'win11-22h2-pro-zh-cn'
  'win11-22h2-ent'
])
param OSVersion string = 'win11-22h2-ent'

@description('Size of the virtual machine.')
param vmSize string = 'Standard_D2s_v5'

@description('Name of the virtual machine.')
param vmName string = 'vm-oai-demo'

@description('Specifies the name of the key vault.')
param keyVaultName string = 'kv-${uniqueString(resourceGroup().id)}'

@description('Name of the Key Vault Private DNS Zone')
param kvPrivateDnsZoneName string = 'privatelink.vaultcore.azure.net'

@description('Name of the Key Vault Private Endpoint')
param kvPrivateEndpointName string = 'kvPrivateEndpoint'

@description('Azure Active Directory tenant ID that should be used for authenticating requests to the key vault')
param tenantId string = subscription().tenantId

@description('SKU of the key vault.')
param keyVaultSku string = 'standard'

@description('Name of the Log Analytics account')
param logAnalyticsWorkspaceName string = 'la-${uniqueString(resourceGroup().id)}'

@description('Name of the Log Analytics account')
param applicationInsightsName string = 'appi-oai-demo'

var keyVaultRoleDefinitionId = '4633458b-17de-408a-b874-0445c86b69e6'
var embeddingsDeployment = empty(embeddingsModelName) ? 'ada' : embeddingsModelName
var chatGptDeployment = empty(chatGptModelName) ? 'chat' : chatGptModelName
var deployments = [
  {
    name: embeddingsDeployment
    model: {
      format: 'OpenAI'
      name: embeddingsModelName
    }
    sku: {
      name: 'Standard'
      capacity: embeddingsDeploymentCapacity
    }
  }
  {
    name: chatGptDeployment
    model: {
      format: 'OpenAI'
      name: chatGptModelName
    }
    sku: {
      name: 'Standard'
      capacity: gptDeploymentCapacity
    }
  }
]

module virtualNetwork './modules/virtualnetwork.bicep' = {
  name: 'virtualNetwork'
  params: {
    location: location
    virtualNetworkName: virtualNetworkName
    bastionHostName: bastionHostName
  }
}

module keyVault './modules/keyvault.bicep' = {
  name: 'keyVault'
  params: {
    location: location
    keyVaultName: keyVaultName
    kvPrivateDnsZoneName: kvPrivateDnsZoneName
    kvPrivateEndpointName: kvPrivateEndpointName
    tenantId: tenantId
    keyVaultSku: keyVaultSku
    keyVaultRoleDefinitionId: keyVaultRoleDefinitionId
    apimName: apimName
    virtualNetworkId: virtualNetwork.outputs.virtualNetworkId
    subnetId: virtualNetwork.outputs.privateEndpointsSubnetId
  }
  dependsOn: [
    virtualNetwork
  ]
}

module loggingResources './modules/logging.bicep' = {
  name: 'loggingResources'
  params: {
    location: location
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    applicationInsightsName: applicationInsightsName
  }
  dependsOn: [
    keyVault, virtualNetwork
  ]
}

module oaiAccount './modules/openai.bicep' = {
  name: 'oaiAccount'
  params: {
    location: location
    openAiAccountName: openAiAccountName
    oaiCustomSubDomainName: oaiCustomSubDomainName
    oaiSku: oaiSku
    deployments: deployments
    logAnalyticsWorkspaceId: loggingResources.outputs.logAnalyticsWorkspaceId
    oaiPrivateDnsZoneName: oaiPrivateDnsZoneName
    oaiPrivateEndpointName: oaiPrivateEndpointName
    virtualNetworkId: virtualNetwork.outputs.virtualNetworkId
    keyVaultName: keyVaultName
    oaiPrimaryKeySecretName: oaiPrimaryKeySecretName
  }
  dependsOn: [
    virtualNetwork
  ]
}

module apiManagement './modules/apimanagement/apimanagement.bicep' = {
  name: 'apiManagement'
  params: {
    location: location
    apimName: apimName
    apimSku: apimSku
    apimCapacity: apimCapacity
    apimPublisherEmail: apimPublisherEmail
    apimPublisherName: apimPublisherName
    openAiEndpoint: oaiAccount.outputs.openAiEndpoint
    apimPrivateDnsZoneName: apimPrivateDnsZoneName
    applicationInsightsName: applicationInsightsName
    applicationInsightsId: loggingResources.outputs.applicationInsightsId
    managedIdentityId: keyVault.outputs.managedIdentityId
    managedIdentityClientId: keyVault.outputs.managedIdentityClientId
    keyVaultUri: keyVault.outputs.keyVaultUri
    openaiKeyVaultSecretName: oaiPrimaryKeySecretName
    apimVNetMode: apimVNetMode
    virtualNetworkId: virtualNetwork.outputs.virtualNetworkId
    apimSubentResourceId: virtualNetwork.outputs.apimSubnetId
  }
}

module virtualMachine 'modules/virtualmachine.bicep' = {
  name: 'virtualMachine'
  params: {
    location: location
    OSVersion: OSVersion
    vmAdminPassword: vmAdminPassword
    vmAdminUsername: vmAdminUsername
    vmName: vmName
    vmSize: vmSize
    virtualMachinesSubnetId: virtualNetwork.outputs.virtualMachinesSubnetId
  }
}

module bastionHost 'modules/bastion.bicep' = {
  name: 'bastionHost'
  params: {
    location: location
    bastionHostName: bastionHostName
    bastionSubnetId: virtualNetwork.outputs.bastionSubnetId
  }
}
