---
description: This template deploys a sample environment that aligns with the guidance in the Aure OpenAI Landing Zone reference architecture. 
page_type: sample
products:
- azure
- azure-resource-manager
urlFragment: openai-reference-architecture
languages:
- json
- bicep
---
# Deploy a sample environment that aligns with the guidance in the Aure OpenAI Landing Zone reference architecture

## Prerequisites
- [Azure Subscription](https://azure.microsoft.com/en-us/get-started/)
- [Azure OpenAI Application](https://aka.ms/oai/access)

Note: for deployment to be successful, the resource group selected or created in the wizard and deployment models specified must be in a supported region. Please be sure to check the [Model summary table and region availability](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models#model-summary-table-and-region-availability) for the latest status.

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fj-d-harvey%2FOpenAItemplates%2Fmain%2Fazuredeploy.json)

This template deploys a sample environment that aligns with the guidance in the [Aure OpenAI Landing Zone reference architecture](https://techcommunity.microsoft.com/t5/azure-architecture-blog/azure-openai-landing-zone-reference-architecture/ba-p/3882102). An OpenAI resource with embeddings and GPT model deployments is deployed, and private network access is ensured through a private endpoint. Diagnostic logging is enabled and configured to send data to a Log Analytics workspace. A Key Vault with private endpoint and a secret is created containing a secrect for the OpenAI Access Key. An API Management service to publish the OpenAI APIs is deployed with Internal VNET integration, and an Application Insights logger is configured to capture telemetry. A virtual machine and a Bastion host are deployed for for internal endpoint connectivity testing. Private DNS Zones are linked to the VNET to facilitate name resolution. 

## Architecture Diagram
![img](/azure-openai-architecture.png)

After deployment you can publish the OpenAI enpoint in API management following the API Management Config steps in the [openai-python-enterprise-logging respository](https://github.com/Azure-Samples/openai-python-enterprise-logging#api-management-config).

`Tags: Azure OpenAI, Azure API Management, API Management, Private Endpoint, Microsoft.Network/virtualNetworks, Microsoft.ApiManagement/service, SystemAssigned, Microsoft.Network/privateEndpoints, Microsoft.Network/privateDnsZones, Microsoft.Network/privateDnsZones/virtualNetworkLinks, Microsoft.Network/privateEndpoints/privateDnsZoneGroups`