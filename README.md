---
description: This template deploys an Azure OpenAI resource with embeddings and GPT model deployments. It ensures private network access through a private endpoint and private DNS zone linked to a VNET, while also deploying a virtual machine and a Bastion host for for internal endpoint connectivity testing.
page_type: sample
products:
- azure
- azure-resource-manager
urlFragment: openai-private-endpoint
languages:
- json
- bicep
---
# Create an Azure OpenAI resource with a private endpoint

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fj-d-harvey%2FOpenAItemplates%2Fmain%2Fazuredeploy.json)

[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fj-d-harvey%2FOpenAItemplates%2Fmain%2Fazuredeploy.json)

This template deploys an Azure OpenAI resource with embeddings and GPT model deployments. It ensures private network access through a private endpoint and private DNS zone linked to a VNET. A Key Vault with private endpoint and private DNS zone are deployed, and a secret is created containing the OpenAI Access Key. An API Management service is deployed with Internal VNET integration, and a virtual machine and a Bastion host are deployed for for internal endpoint connectivity testing.

## Reference Architecture
![img](/azure-openai-architecture.png)

Below are the parameters which can be user configured in the parameters file:

- **embeddingsDeploymentCapacity:** Enter the Tokens per Minute Rate Limit (thousands) for the embeddings model deployment.
- **embeddingsModelName:** Enter the name of the embeddings model to deploy.
- **gptDeploymentCapacity:** Enter the Tokens per Minute Rate Limit (thousands) for the gpt model deployment.
- **chatGptModelName:** Enter the name of the gpt model to deploy.
- **vmAdminUsername:** Enter the name of the amin account for virtual machine login.

`Tags: Azure OpenAI, Azure API Management, API Management, Private Endpoint, Microsoft.Network/virtualNetworks, Microsoft.ApiManagement/service, SystemAssigned, Microsoft.Network/privateEndpoints, Microsoft.Network/privateDnsZones, Microsoft.Network/privateDnsZones/virtualNetworkLinks, Microsoft.Network/privateEndpoints/privateDnsZoneGroups`