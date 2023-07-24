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

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2Fquickstarts%2Fmicrosoft.apimanagement%2Fapi-management-private-endpoint%2Fazuredeploy.json)

[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2Fquickstarts%2Fmicrosoft.apimanagement%2Fapi-management-private-endpoint%2Fazuredeploy.json)

This template deploys an Azure OpenAI resource with embeddings and GPT model deployments. It ensures private network access through a private endpoint and private DNS zone linked to a VNET, while also deploying a virtual machine and a Bastion host for for internal endpoint connectivity testing.

Below are the parameters which can be user configured in the parameters file including:

- **Location:** Select where the resource should be created (default is target resource group's location).
- **Virtual Network Name:** Enter a name for the virtual network.
- **Public Network Access:** Select whether public traffic is allowed to access the account (default is Enabled). When value is set to Disabled, public network traffic is blocked even before the private endpoint is created.
- **ApiManagementServiceName:** Enter a name for the api management service
- **PublisherName:** Enter of the publisher who is the owner of the api management service
- **PublisherEmail:** Email of the publisher to notify api management service setup
- **Private Endpoint Name:** Enter a name for the private endpoint.

`Tags: Azure API Management, API Management, Private Endpoint, Microsoft.Network/virtualNetworks, Microsoft.ApiManagement/service, SystemAssigned, Microsoft.Network/privateEndpoints, Microsoft.Network/privateDnsZones, Microsoft.Network/privateDnsZones/virtualNetworkLinks, Microsoft.Network/privateEndpoints/privateDnsZoneGroups`