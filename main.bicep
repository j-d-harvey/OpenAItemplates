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

@description('Security Type of the Virtual Machine.')
@allowed([
  'Standard'
  'TrustedLaunch'
])
param securityType string = 'Standard'

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

var securityProfileJson = {
  uefiSettings: {
    secureBootEnabled: true
    vTpmEnabled: true
  }
  securityType: securityType
}
var extensionName = 'GuestAttestation'
var extensionPublisher = 'Microsoft.Azure.Security.WindowsAttestation'
var extensionVersion = '1.0'
var maaTenantName = 'GuestAttestation'
var maaEndpoint = substring('emptyString', 0, 0)
var apimRoleDefinitionId = '4633458b-17de-408a-b874-0445c86b69e6'
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
    apimRoleDefinitionId: apimRoleDefinitionId
    apimName: apimName
    virtualNetworkId: virtualNetwork.outputs.virtualNetworkId
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
    keyVaultName: keyVaultName
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
    openAiEndpoint: '${oaiAccount.outputs.openAiEndpoint}/openai'
    apimPrivateDnsZoneName: apimPrivateDnsZoneName
    applicationInsightsName: applicationInsightsName
    applicationInsightsId: loggingResources.outputs.applicationInsightsId
    managedIdentityId: keyVault.outputs.managedIdentityId
    managedIdentityClientId: keyVault.outputs.managedIdentityClientId
    keyVaultUri: keyVault.outputs.keyVaultUri
    openaiKeyVaultSecretName: oaiPrimaryKeySecretName
    apimVNetMode: apimVNetMode
    virtualNetworkId: virtualNetwork.outputs.virtualNetworkId
    apimSubentResourceId: '${virtualNetwork.outputs.virtualNetworkId}/subnets/APIM'
  }
}

// Virtual Machine Resources
resource vmNic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${virtualNetwork.outputs.virtualNetworkId}/subnets/VMs'
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: vmAdminUsername
      adminPassword: vmAdminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'microsoftwindowsdesktop'
        offer: 'windows-11'
        sku: OSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: []
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
    securityProfile: ((securityType == 'TrustedLaunch') ? securityProfileJson : null)
  }
}

resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = if ((securityType == 'TrustedLaunch') && ((securityProfileJson.uefiSettings.secureBootEnabled == true) && (securityProfileJson.uefiSettings.vTpmEnabled == true))) {
  parent: vm
  name: extensionName
  location: location
  properties: {
    publisher: extensionPublisher
    type: extensionName
    typeHandlerVersion: extensionVersion
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      AttestationConfig: {
        MaaSettings: {
          maaEndpoint: maaEndpoint
          maaTenantName: maaTenantName
        }
      }
    }
  }
}

//Bastion Host Resources
resource bastionPublicIP 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: 'pip-${bastionHostName}'
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
  }
}

resource bastionHost 'Microsoft.Network/bastionHosts@2022-07-01' = {
  name: bastionHostName
  location: location
  properties: {
    ipConfigurations: [
      {
        properties: {
          subnet: {
            id: '${virtualNetwork.outputs.virtualNetworkId}/subnets/AzureBastionSubnet'
          }
          publicIPAddress: {
            id: bastionPublicIP.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
        name: 'ipconfig1'
      }
    ]
  }
}
