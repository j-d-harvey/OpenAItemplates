using './main.bicep'

param openAiAccountName = 'oiatestacct'
param customSubDomainName = openAiAccountName
param sku = 'S0'
param gptDeploymentName = 'ada'
param gptDeploymentCapacity = 1
param gptModelName = 'text-embedding-ada-002'
param chatGptDeploymentName = 'chat'
param chatGptDeploymentCapacity = 1
param chatGptModelName = 'gpt-35-turbo'
param virtualNetworkName = 'vnet'
param oaiPrivateDnsZoneName = 'privatelink.openai.azure.com'
param oaiPrivateEndpointName = 'oaiPrivateEndpoint'
