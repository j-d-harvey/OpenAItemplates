param location string
param openAiAccountName string
param oaiCustomSubDomainName string
param oaiSku string
param deployments array = []
param logAnalyticsWorkspaceId string
param virtualNetworkId string
param oaiPrivateDnsZoneName string
param oaiPrivateEndpointName string
param keyVaultName string
param oaiPrimaryKeySecretName string


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
}

resource oaiPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: oaiPrivateDnsZone
  name: '${oaiPrivateDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkId
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
      id: '${virtualNetworkId}/subnets/OpenAI'
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

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyVaultName
  
  resource secret 'secrets' = {
    name: oaiPrimaryKeySecretName
    properties: {
      value: oaiAccount.listKeys().key1
    }
  }
}

output oaiAccountId string = oaiAccount.id 
output openAiEndpoint string = '${oaiAccount.properties.endpoint}/openai'
