param location string
param logAnalyticsWorkspaceName string
param applicationInsightsName string
param keyVaultName string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' existing = {
  name: keyVaultName
  
  resource secret 'secrets' = {
    name: 'ApplicationInsightsInstrumentationKey'
    properties: {
      value: applicationInsights.properties.InstrumentationKey
    }
  }
}

output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
output applicationInsightsId string = applicationInsights.id
