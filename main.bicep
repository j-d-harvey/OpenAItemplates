param location string = resourceGroup().location
param openAiAccountName string = 'oaitst'
param customSubDomainName string = openAiAccountName
param sku string = 'S0'
param gptDeploymentName string = 'ada'
param gptDeploymentCapacity int = 1
param gptModelName string = 'text-embedding-ada-002'
param chatGptDeploymentName string = 'chat'
param chatGptDeploymentCapacity int = 1
param chatGptModelName string = 'gpt-4'
param virtualNetworkName string = 'vnet'
param oaiPrivateDnsZoneName string = 'privatelink.openai.azure.com'
param kvPrivateDnsZoneName string = 'privatelink.vaultcore.azure.net'
param oaiPrivateEndpointName string = 'oaiPrivateEndpoint'
param kvPrivateEndpointName string = 'kvPrivateEndpoint'
@description('Specifies the name of the key vault.')
param keyVaultName string = 'kv${uniqueString(resourceGroup().id)}'

@description('Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. Get it by using Get-AzSubscription cmdlet.')
param tenantId string = subscription().tenantId

@description('Specifies the SKU for the key vault.')
param kvSkuName string = 'standard'

var oaiSubnetId = virtualNetwork.properties.subnets[0].id
var kvSubnetId = virtualNetwork.properties.subnets[4].id
var gptDeployment = empty(gptDeploymentName) ? 'davinci' : gptDeploymentName
var chatGptDeployment = empty(chatGptDeploymentName) ? 'chat' : chatGptDeploymentName
var deployments = [
  {
    name: gptDeployment
    model: {
      format: 'OpenAI'
      name: gptModelName
    }
    sku: {
      name: 'Standard'
      capacity: gptDeploymentCapacity
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
      capacity: chatGptDeploymentCapacity
    }
  }
]

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/24'
      ]
    }
    subnets: [
      {
        name: 'OpenAI'
        properties: {
          addressPrefix: '10.0.0.0/27'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      {
        name: 'VMs'
        properties: {
          addressPrefix: '10.0.0.32/28'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.0.192/26'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
    ]
    virtualNetworkPeerings: []
  }
}

resource oaiAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openAiAccountName
  location: location
  kind: 'OpenAI'
  properties: {
    customSubDomainName: customSubDomainName
    publicNetworkAccess: 'Enabled'
  }
  sku: {
    name: sku
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
  name: oaiPrivateDnsZoneName
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
      id: virtualNetwork.id
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
      id: oaiSubnetId
    }
  }
}

resource pvtEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
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