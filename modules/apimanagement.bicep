param location string
param apimName string
param apimSku string
param apimCapacity int
param apimPublisherEmail string
param apimPublisherName string
param apimPrivateDnsZoneName string
param applicationInsightsName string
param applicationInsightsId string
param managedIdentityId string
param virtualNetworkId string
param apimSubentResourceId string

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: applicationInsightsName
}

resource apim 'Microsoft.ApiManagement/service@2023-03-01-preview' = {
  name: apimName
  location: location
  sku: {
    name: apimSku
    capacity: apimCapacity
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${managedIdentityId}': {}
    }
  }
  properties: {
    publisherEmail: apimPublisherEmail
    publisherName: apimPublisherName
    virtualNetworkType: 'Internal'
    virtualNetworkConfiguration: {
      subnetResourceId: apimSubentResourceId
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
    resourceId: applicationInsightsId
    credentials: {
      instrumentationKey: applicationInsights.properties.InstrumentationKey
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
}

resource apimPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: apimPrivateDnsZone
  name: '${apimPrivateDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}

resource apimPortalDnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = if (true) {
  parent: apimPrivateDnsZone
  name: '${apimName}.portal'
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
  properties: {
    ttl: 36000
    aRecords: [
      {
        ipv4Address: apim.properties.privateIPAddresses[0]
      }
    ]
  }
}

output apiManagementId string = apim.id
output apiMangementPrincipalId string = apim.identity.principalId
