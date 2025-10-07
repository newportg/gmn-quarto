---
layout: post
title: ARM Template Parameter/Variable Setup

categories: [Azure, Arm Templates]
author: "Gary Newport"
date: 2018-10-15
---

For something so simple, arm templates can become complex things, so I prefer to try to set some ground rules before I go to deep.
N.B this works for me, and may not suit everyone 😉

* You should employee a naming convention for your artefacts.
* Every Resource should be tagged.
* There should be a clear naming convention between the parameters and variables.
* Parameters should be either primitives or unique values
* Variables should build up your resource names from the parameter primitives.

## Parameters
I prefer to inject any unique values via a VSTS/VSO or if your prefer Azure DevOps deployment process.

In the first part of the file I spell out the acronyms which form part of the naming convention for the resources, you could use nested templates for this, but I feel they add unnecessary complications, as the nested template must be available via a URL.
The second part involves parameters that are specific to this application, such as the tenant id, application name etc.

```json
{
	"$schema": "https://schema.management.azure.com/schemas/2015-01-01/deploymentParameters.json#",
	"contentVersion": "1.0.0.0",
	"parameters": {
		"para_acronym_region": { "value": "we" },
		"para_acronym_resgrp": { "value": "resgrp" },
		"para_acronym_appsvc": { "value": "appsvc" },
		"para_acronym_svcpln": { "value": "svcpln" },
		"para_acronym_stract": { "value": "str" },
		"para_acronym_kv": { "value": "kv" },
		"para_acronym_azfunc": { "value": "fn" },
		"para_acronym_appin": { "value": "appins" },
		"para_acronym_webapp": { "value": "webapp" },
		"para_ad_tenantid": { "value": " OVERWRITTEN BY VSTS " },
		"para_application_name": { "value": " OVERWRITTEN BY VSTS " },
		"para_vanity_name": { "value": " OVERWRITTEN BY VSTS " },
		"para_target_env": { "value": "dev" },
		"para_kvSecretsObject": {
			"value": {
				"secrets": [
						{
						"secretName": "applicationuser",
						"secretValue": "OVERWRITTEN BY VSTS"
						},
						{
							"secretName": "AnotherSecrect",
							"secretValue": "OVERWRITTEN BY VSTS"
						}
					]
				}
			}
		}
	}
}
```

## Variables
As you can see from the variables, I build up my resource names from the parameters.
I also pull in values for the hostingplan and component identities, so they can be used easily with the resource definitions.

```json
"variables": {
	"var_env_region": "[concat(parameters('para_target_env'), '-', parameters('para_acronym_region'))]",
	"var_public_url": "[concat(parameters('para_target_env'), '.', parameters('para_application_name'), '.', parameters('para_vanity_name'))]",
	"var_str_name": "[concat(parameters('para_application_name'), parameters('para_acronym_stract'), parameters('para_target_env'), parameters('para_acronym_region'))]",
	"var_str_resId": "[resourceId(resourceGroup().Name,'Microsoft.Storage/storageAccounts', variables('var_str_name'))]",
	"var_kv_name": "[concat(parameters('para_application_name'), '-', parameters('para_acronym_kv'), '-', variables('var_env_region'))]",
	"var_azf_name": "[concat(parameters('para_application_name'), '-', parameters('para_acronym_azfunc'),'-', variables('var_env_region'))]",
	"var_appin_name": "[concat(parameters('para_application_name'), '-', parameters('para_acronym_appin'),'-', variables('var_env_region'))]",
	"var_hstpln_group": "[concat(parameters('para_application_name'), '-', parameters('para_acronym_resgrp'), '-', variables('var_env_region'))]",
	"var_hstpln_env": "[concat(parameters('para_application_name'), '-', parameters('para_acronym_appsvc'), '-', variables('var_env_region'))]",
	"var_hstpln_name": "[concat(parameters('para_application_name'), '-', parameters('para_acronym_svcpln'), '-', variables('var_env_region'))]",
	"var_webapp_name": "[concat(parameters('para_application_name'), '-' ,parameters('para_acronym_webapp'),'-', variables('var_env_region'))]",
	"var_webapp_hstpln": "[concat('/subscriptions/', subscription().subscriptionId, '/resourceGroups/', variables('var_hstpln_group'), '/providers/Microsoft.Web/serverfarms/', variables('var_hstpln_name'))]",
	"var_msi_azf": "[concat(resourceId('Microsoft.Web/sites', variables('var_azf_name')),'/providers/Microsoft.ManagedIdentity/Identities/default')]"
},
```

