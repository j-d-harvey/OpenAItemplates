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
# Deploy a sample environment that aligns with guidance in Aure OpenAI reference architectures

## Prerequisites
- [Azure Subscription](https://azure.microsoft.com/en-us/get-started/)
- [Azure OpenAI Application](https://aka.ms/oai/access)

**Important:** for deployment to be successful, the resource group selected or created in the wizard and deployment models specified must be in a supported region. Please be sure to check the [Model summary table and region availability](https://learn.microsoft.com/en-us/azure/ai-services/openai/concepts/models#model-summary-table-and-region-availability) for the latest status.

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fj-d-harvey%2FOpenAItemplates%2Fmain%2Fazuredeploy.json)

This template deploys a sample environment that demonstrates much of the guidance in the [Implement logging and monitoring for Azure OpenAI models reference architecture](https://learn.microsoft.com/en-us/azure/architecture/example-scenario/ai/log-monitor-azure-openai)

and the [Aure OpenAI Landing Zone reference architecture](https://techcommunity.microsoft.com/t5/azure-architecture-blog/azure-openai-landing-zone-reference-architecture/ba-p/3882102).

## What will be deployed?

- A virtual network
 - Network Security Groups linked to each subnet
- An Azure Bastion Host
- A Virtual Machine for testing internal connectivity
- A Log Analytics Workspace
- An OpenAI resource with an embeddings model and GPT model deployments
  - Model names and tokens per minute request limits can be specified as parameters
  - Diagnostic settings configured to send data to the Log Analytics workspace
  - A Private Endpoint linked to the appropriate subnet of the Virtual Network
  - A Private DNS Zone linked to the Virtual Network to enable internal name resolution and connectivity
- An Application Insights resource
- An API Management resource for accessing back-end Azure OpenAI endpoints
  - System Assigned Manged Identity enabled
  - An Application Insights logger configured for All APIs to capture advanced logging and telemetry for OpenAI API calls
  - Internal Virtual Network Mode enabled
  - A Private DNS Zone linked to the Virtual Network to enable internal name resolution and connectivity
- A Key Vault configured for Azure role-based access control
  - A Role Based Access Control assignment for the API Managment managed identity
  - A Key Vault Secrect containing the primary Azure OpenAI Access Key
  - A Private Endpoint linked to the appropriate subnet of the Virtual Network
  - A Private DNS Zone linked to the Virtual Network to enable internal name resolution and connectivity

In summary:
An OpenAI resource with embeddings and GPT model deployments is deployed, and private network access is ensured through a private endpoint. Diagnostic logging is enabled and configured to send data to a Log Analytics workspace. A Key Vault with private endpoint and a secret is created containing a secrect for the OpenAI Access Key. An API Management service to publish the OpenAI APIs is deployed with Internal VNET integration, and an Application Insights logger is configured to capture telemetry. A virtual machine and a Bastion host are deployed for for internal endpoint connectivity testing. Private DNS Zones are linked to the VNET to facilitate name resolution. 

## Architecture Diagram
![img](/azure-openai-architecture.png)

After deployment you can publish the OpenAI enpoint in API management following the API Management Config steps in the [openai-python-enterprise-logging respository](https://github.com/Azure-Samples/openai-python-enterprise-logging#api-management-config).

`Tags: Azure OpenAI, Azure API Management, API Management, Private Endpoint, Microsoft.Network/virtualNetworks, Microsoft.ApiManagement/service, SystemAssigned, Microsoft.Network/privateEndpoints, Microsoft.Network/privateDnsZones, Microsoft.Network/privateDnsZones/virtualNetworkLinks, Microsoft.Network/privateEndpoints/privateDnsZoneGroups`