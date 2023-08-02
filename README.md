---
description: This template deploys a sample environment that aligns with the guidance in the Aure OpenAI Landing Zone reference architecture. 
page_type: sample
products:
- azure
- azure-resource-manager
urlFragment: openai-private-endpoint
languages:
- json
- bicep
---
# Deploy a sample environment that aligns with the guidance in the Aure OpenAI Landing Zone reference architecture

## Prerequisites
- [Azure Subscription](https://azure.microsoft.com/en-us/get-started/)
- [Azure OpenAI Application](https://aka.ms/oai/access)

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fj-d-harvey%2FOpenAItemplates%2Fmain%2Fazuredeploy.json)

This template deploys a sample environment that aligns with the guidance in the Aure OpenAI Landing Zone reference architecture. An OpenAI resource with embeddings and GPT model deployments is deployed, and private network access is ensured through a private endpoint. Diagnostic logging is enabled and configured to send data to a Log Analytics workspace. A Key Vault with private endpoint and a secret is created containing the OpenAI Access Key. An API Management service to publish the OpenAI APIs is deployed with Internal VNET integration, and an Application Insights logger is configured to capture telemetry. A virtual machine and a Bastion host are deployed for for internal endpoint connectivity testing. Private DNS Zones are linked to the VNET to facilitate name resolution. 

## Reference Architecture
![img](/azure-openai-architecture.png)

Below are the parameters which can be user configured in the parameters file:

- **embeddingsDeploymentCapacity:** Enter the Tokens per Minute Rate Limit (thousands) for the embeddings model deployment.
- **embeddingsModelName:** Enter the name of the embeddings model to deploy.
- **gptDeploymentCapacity:** Enter the Tokens per Minute Rate Limit (thousands) for the gpt model deployment.
- **chatGptModelName:** Enter the name of the gpt model to deploy.
- **vmAdminUsername:** Enter the name of the amin account for virtual machine login.

`Tags: Azure OpenAI, Azure API Management, API Management, Private Endpoint, Microsoft.Network/virtualNetworks, Microsoft.ApiManagement/service, SystemAssigned, Microsoft.Network/privateEndpoints, Microsoft.Network/privateDnsZones, Microsoft.Network/privateDnsZones/virtualNetworkLinks, Microsoft.Network/privateEndpoints/privateDnsZoneGroups`