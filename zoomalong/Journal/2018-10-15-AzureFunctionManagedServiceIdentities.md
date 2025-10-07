---
layout: post
title: Azure Function Managed Service Identities
description: Azure Function Managed Service Identities
categories: [Azure, Security, Managed Service Identities]
author: "Gary Newport"
date: 2018-10-15
---

# Bootstrapping
The trouble with many security policies is that at least some element needs to know the password in order to instigate access to resources. That used to mean putting credentials into a configuration file or inserting them during a deployment process. The Manage Service Identities (MSI) facility has got around this by allowing all your resources to register a service principal with Active Directory, and then each resource grants the desired level of access to that service principal. By doing the security in this way, each of the resources never need to know credentials, they only request access and deal with the response. So, by removing credentials from the equation then there is no need to have to rotate passwords or update certs on a timely basis as they simply don�t exist between the resources.

# So how do we accomplish this.
Within the azure function arm template declaration insert the following, this will register the function with your active directory.

```json
"identity": {"type": "SystemAssigned"},
```

In the variables section of the Arm Template, get the identity of the Azure Function. (replace 'var_azf_name' with the name of your function)

```json
"var_msi_azf": "[concat(resourceId('Microsoft.Web/sites', variables('var_azf_name')),'/providers/Microsoft.ManagedIdentity/Identities/default')]"
```

Within your Key Vault template your will need to add the functions access policy

```json
"accessPolicies": [{"tenantId": "[reference(variables('var_msi_azf'), '2015-08-31-PREVIEW').tenantId]","objectId": "[reference(variables('var_msi_azf'), '2015-08-31-PREVIEW').principalId]","permissions": {"certificates": ["get"],"keys": ["get"],"secrets": ["get"]}}}]
```
