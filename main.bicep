@description('Location for all resources')
param location string = resourceGroup().location

@description('Name of the Azure OpenAI account')
param openAiAccountName string = 'oai-private-demo'

@description('Custom subdomain name for the Azure OpenAI account')
param oaiCustomSubDomainName string = 'oai-${uniqueString(resourceGroup().id)}'

@description('SKU for the Azure OpenAI account')
param oaiSku string = 'S0'

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

@description('Name of the Key Vault Private DNS Zone')
param kvPrivateDnsZoneName string = 'privatelink.vaultcore.azure.net'

@description('Name of the Key Vault Private Endpoint')
param kvPrivateEndpointName string = 'kvPrivateEndpoint'

@description('Specifies the name of the key vault.')
param keyVaultName string = 'kv-${uniqueString(resourceGroup().id)}'

@description('Azure Active Directory tenant ID that should be used for authenticating requests to the key vault')
param tenantId string = subscription().tenantId

@description('SKU of the key vault.')
param kvSkuName string = 'standard'

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

module loggingResources './modules/logging.bicep' = {
  name: 'loggingResources'
  params: {
    location: location
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    applicationInsightsName: applicationInsightsName
  }
}

// OpenAI Account resources
resource oaiAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openAiAccountName
  location: location
  kind: 'OpenAI'
  properties: {
    customSubDomainName: oaiCustomSubDomainName
    publicNetworkAccess: 'Disabled'
  }
  sku: {
    name: oaiSku
  }
  dependsOn: [
    virtualNetwork
  ]
}

@batchSize(1)
resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = [for deployment in deployments: {
  parent: oaiAccount
  name: deployment.name
  properties: {
    model: deployment.model
    raiPolicyName: contains(deployment, 'raiPolicyName') ? deployment.raiPolicyName : null
  }
  sku: contains(deployment, 'sku') ? deployment.sku : {
    name: 'Standard'
    capacity: 20
  }
}]

resource oaiPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.openai.azure.com'
  location: 'global'
  properties: {}
  dependsOn: [
    virtualNetwork
  ]
}

resource oaiPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: oaiPrivateDnsZone
  name: '${oaiPrivateDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.outputs.virtualNetworkId
    }
  }
}

resource oaiPrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-11-01' = {
  name: oaiPrivateEndpointName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${oaiPrivateEndpointName}-connection'
        properties: {
          privateLinkServiceId: oaiAccount.id
          groupIds: [
            'account'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    customNetworkInterfaceName: '${oaiPrivateEndpointName}-nic'
    subnet: {
      id: '${virtualNetwork.outputs.virtualNetworkId}/subnets/OpenAI'
    }
  }
}

resource oaiPvtEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  parent: oaiPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: oaiPrivateDnsZone.id
        }
      }
    ]
  }
}

resource openAI_diagnosticsettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  scope: oaiAccount
  name: '${openAiAccountName}-diags'
  properties: {
    workspaceId: loggingResources.outputs.logAnalyticsWorkspaceId
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 90
        }
      }
    ]
  }
}

// Key Vault Resources
resource kv 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: tenantId
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    sku: {
      name: kvSkuName
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
  }
}

resource kvRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(apimRoleDefinitionId, apim.id, kv.id)
  scope: kv
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: apim.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource oaiAccountKeySecret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  parent: kv
  name: 'oaiAccountKey'
  properties: {
    value: oaiAccount.listKeys().key1
  }
}

resource kvPrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-11-01' = {
  name: kvPrivateEndpointName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: '${kvPrivateEndpointName}-connection'
        properties: {
          privateLinkServiceId: kv.id
          groupIds: [
            'vault'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Approved'
            actionsRequired: 'None'
          }
        }
      }
    ]
    customNetworkInterfaceName: '${kvPrivateEndpointName}-nic'
    subnet: {
      id: '${virtualNetwork.outputs.virtualNetworkId}/subnets/PrivateEndpoints'
    }
  }
}

resource kvPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: kvPrivateDnsZoneName
  location: 'global'
  properties: {}
  dependsOn: [
    virtualNetwork
  ]
}

resource kvPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: kvPrivateDnsZone
  name: '${kvPrivateDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.outputs.virtualNetworkId
    }
  }
}

resource kvPvtEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  parent: kvPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: kvPrivateDnsZone.id
        }
      }
    ]
  }
}

// API Management Resources
resource apim 'Microsoft.ApiManagement/service@2023-03-01-preview' = {
  name: apimName
  location: location
  sku: {
    name: apimSku
    capacity: apimCapacity
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: apimPublisherEmail
    publisherName: apimPublisherName
    virtualNetworkType: 'Internal'
    virtualNetworkConfiguration: {
      subnetResourceId: '${virtualNetwork.outputs.virtualNetworkId}/subnets/APIM'
    }
  }
}

resource apimNSG 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: 'nsg-apim-oai-demo'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowManagementEndpointInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'ApiManagement'
          destinationPortRange: '3443'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource apimLogger 'Microsoft.ApiManagement/service/loggers@2023-03-01-preview' = {
  parent: apim
  name: 'appInsightsLogger'
  properties: {
    loggerType: 'applicationInsights'
    resourceId: loggingResources.outputs.applicationInsightsId
    credentials: {
      instrumentationKey: loggingResources.outputs.applicationInsightsInstrumentationKey
    }
    isBuffered: true
  }
}

resource apimDiagnostics 'Microsoft.ApiManagement/service/diagnostics@2023-03-01-preview' = {
  parent: apim
  name: 'applicationinsights'
  properties: {
    alwaysLog: 'allErrors'
    httpCorrelationProtocol: 'W3C'
    verbosity: 'information'
    logClientIp: true
    loggerId: apimLogger.id
    sampling: {
      samplingType: 'fixed'
      percentage: 100
    }
    frontend: {
      request: {
        headers: []
        body: {
          bytes: 8192
        }
      }
      response: {
        headers: []
        body: {
          bytes: 8192
        }
      }
    }
    backend: {
      request: {
        headers: []
        body: {
          bytes: 8192
        }
      }
      response: {
        headers: []
        body: {
          bytes: 8192
        }
      }
    }
  }
}

resource apimPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: apimPrivateDnsZoneName
  location: 'global'
  properties: {}
  dependsOn: [
    virtualNetwork
  ]
}

resource apimPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: apimPrivateDnsZone
  name: '${apimPrivateDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetwork.outputs.virtualNetworkId
    }
  }
}

resource apimPortalDnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = if (true) {
  parent: apimPrivateDnsZone
  name: '${apimName}.portal'
  location: 'global'
  properties: {
    ttl: 36000
    aRecords: [
      {
        ipv4Address: apim.properties.privateIPAddresses[0]
      }
    ]
  }
}

resource apimDeveloperDnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = if (true) {
  parent: apimPrivateDnsZone
  name: '${apimName}.developer'
  location: 'global'
  properties: {
    ttl: 36000
    aRecords: [
      {
        ipv4Address: apim.properties.privateIPAddresses[0]
      }
    ]
  }
}

resource apimManagementDnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = if (true) {
  parent: apimPrivateDnsZone
  name: '${apimName}.management'
  location: 'global'
  properties: {
    ttl: 36000
    aRecords: [
      {
        ipv4Address: apim.properties.privateIPAddresses[0]
      }
    ]
  }
}

resource apimScmDnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = if (true) {
  parent: apimPrivateDnsZone
  name: '${apimName}.scm'
  location: 'global'
  properties: {
    ttl: 36000
    aRecords: [
      {
        ipv4Address: apim.properties.privateIPAddresses[0]
      }
    ]
  }
}

resource apimDnsRecord2 'Microsoft.Network/privateDnsZones/A@2020-06-01' = if (true) {
  parent: apimPrivateDnsZone
  name: apimName
  location: 'global'
  properties: {
    ttl: 36000
    aRecords: [
      {
        ipv4Address: apim.properties.privateIPAddresses[0]
      }
    ]
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
