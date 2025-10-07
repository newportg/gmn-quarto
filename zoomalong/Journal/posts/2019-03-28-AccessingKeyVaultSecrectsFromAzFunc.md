---
layout: post
title: Getting Secrets from KeyVault in Azure Functions
---

KeyVault is a central resource where you should be storing all of your applications secrets/connection strings and config.
The reason for using KeyVault rather than using a local config file, is really quite simple. config files dont exist for most azure artefacts, and if they did, it would encourage the sort of key management that has plagued .NET since day one.
By using the KeyVault in this way means that the application code doesn't need to know anything about the environment or its configuration. The build process should inject any secrets into the parameters file, which the ARM Template deployment consumes and deploys.

* The Azure Functions AppSettings values are set to point to the keys in the KeyVault. 
* The AppSetting gets its value from the KeyVault when the app is instantiated.
  * Getting the AppSettings in this way enables the application to be ignorant of the settings value.

So How do we do it, in ARM Templates

## ARM Template Definition

* Create a Azure Function
  * Identity should be 'System Assigned'
  * WEBSITE_ENABLE_SYNC_UPDATE_SITE
    * N.B There is a reason for this, but I cant find it right now.
  * Add KeyVault Key names to App Settings
    * The KeyVault key is not a secret.
    * This creates a Appsetting which can be seen in the code, and assigns to it a KeyVault secret. 

``` JSON
"name": "appsettings",
    "properties": {
        "applicationuser": "[concat('@Microsoft.KeyVault(SecretUri=', reference('applicationuser').secretUriWithVersion, ')')]"
    }

```
* Define a KeyVault
  * Set access policy 
    * Tennant Id
    * System Assigned Object Id
  * Load secrets etc into KeyVault

* Future
  * Assign keys to App Settings via a array copy structure
    * This would move the definition to the parameters file.
      * The issue with this approach is that the copy construct cannot operate on child resources (See Below).

``` JSON
"resources": [
  {
    "type": "{provider-namespace-and-type}",
    "name": "parentResource",
    "copy": {  
      /* yes, copy can be applied here */
    },
    "properties": {
      "exampleProperty": {
        /* no, copy cannot be applied here */
      }
    },
    "resources": [
      {
        "type": "{provider-type}",
        "name": "childResource",
        /* copy can be applied if resource is promoted to top level */ 
      }
    ]
  }
] 
```
 
## Application Usage

Access as you would a config variable 
``` C#
        private static string StorageAccount = System.Environment.GetEnvironmentVariable("StorageAccount");
```

## Code snippets from integration
### Arm Parameters
``` JSON
    "para_kvSecretsObject": {
      "value": {
        "secrets": [
          {
            "secretName": "applicationuser",
            "secretValue": "OVERWRITTEN BY VSTS"
          },
          {
            "secretName": "StorageAccount",
            "secretValue": "DefaultEndpointsProtocol=https;AccountName=kfaalphaneugeneralst01;AccountKey=<ACCOUNTKEY>;EndpointSuffix=core.windows.net"
          }
        ]
      }
    }
```

### ARM Template
``` JSON
    {
      "apiVersion": "2016-08-01",
      "dependsOn": [
        "[concat('Microsoft.Storage/storageAccounts/', variables('var_str_name'))]"
      ],
      "identity": {
        "type": "SystemAssigned"
      },
      "kind": "functionapp",
      "location": "[resourceGroup().location]",
      "name": "[variables('var_azf_name')]",
      "properties": {
        "name": "[variables('var_azf_name')]",
        "siteConfig": {
          "appSettings": [
            {
              "name": "AzureWebJobsDashboard",
              "value": "[concat('DefaultEndpointsProtocol=https;AccountName=',variables('var_str_name'),';AccountKey=',listKeys(variables('var_str_resId'),'2015-05-01-preview').key1) ]"
            },
            {
              "name": "AzureWebJobsStorage",
              "value": "[concat('DefaultEndpointsProtocol=https;AccountName=',variables('var_str_name'),';AccountKey=',listKeys(variables('var_str_resId'),'2015-05-01-preview').key1) ]"
            },
            {
              "name": "APPINSIGHTS_INSTRUMENTATIONKEY",
              "value": "[reference(concat('microsoft.insights/components/', variables('var_appin_name'))).InstrumentationKey]"
            },
            {
              "WEBSITE_ENABLE_SYNC_UPDATE_SITE": "true"
            }
          ],
          "alwaysOn": false
        },
        "clientAffinityEnabled": false,
        "serverFarmId": "[variables('var_hstpln_name')]",
        "hostingEnvironment": "[variables('var_hstpln_env')]",
        "hostNameSslStates": [
        ]
      },
      "resources": [
        {
          "apiVersion": "2015-08-01",
          "dependsOn": [
            "[resourceId('Microsoft.Web/sites', variables('var_azf_name'))]",
            "[resourceId('Microsoft.KeyVault/vaults/', variables('var_kv_name'))]",
            "secretsCopy"
          ],
          "name": "appsettings",
          "properties": {
            "applicationuser": "[concat('@Microsoft.KeyVault(SecretUri=', reference('applicationuser').secretUriWithVersion, ')')]",
            "StorageAccount": "[concat( '@Microsoft.KeyVault(SecretUri=', reference('StorageAccount').secretUriWithVersion, ')')]"
          },
          "tags": {
            "displayName": "AppSettings"
          },
          "type": "config"
        }
      ],
      "tags": {
        "displayName": "Az Function"
      },
      "type": "Microsoft.Web/sites"
    },
    {
      "apiVersion": "2016-10-01",
      "dependsOn": [
        "[concat('Microsoft.Web/sites/', variables('var_azf_name'))]"
      ],
      "location": "[resourceGroup().location]",
      "name": "[variables('var_kv_name')]",
      "properties": {
        "sku": {
          "family": "A",
          "name": "Standard"
        },
        "tenantId": "[variables('var_ten_id')]",
        "accessPolicies": [
          {
            "tenantId": "[variables('var_ten_id')]",
            "objectId": "[reference(variables('var_svc_prin'), '2015-08-31-PREVIEW').principalId]",
            "permissions": {
              "keys": [
                "Get",
                "List",
                "Update",
                "Create",
                "Import",
                "Delete",
                "Recover",
                "Backup",
                "Restore",
                "Decrypt",
                "Encrypt",
                "UnwrapKey",
                "WrapKey",
                "Verify",
                "Sign",
                "Purge"
              ],
              "secrets": [
                "Get",
                "List",
                "Set",
                "Delete",
                "Recover",
                "Backup",
                "Restore",
                "Purge"
              ],
              "certificates": [
                "Get",
                "List",
                "Update",
                "Create",
                "Import",
                "Delete",
                "Recover",
                "Backup",
                "Restore",
                "ManageContacts",
                "ManageIssuers",
                "GetIssuers",
                "ListIssuers",
                "SetIssuers",
                "DeleteIssuers",
                "Purge"
              ]
            }
          }
        ],
            "enabledForDeployment": false,
            "enabledForDiskEncryption": false,
            "enabledForTemplateDeployment": false
      },
      "scale": null,
      "tags": {
        "displayName": "Key Vault"
      },
      "type": "Microsoft.KeyVault/vaults"
    },
    {
      "apiVersion": "2015-06-01",
      "copy": {
        "name": "secretsCopy",
        "count": "[length(parameters('para_kvSecretsObject').secrets)]"
      },
      "dependsOn": [
        "[concat('Microsoft.KeyVault/vaults/', variables('var_kv_name'))]"
      ],
      "name": "[concat(variables('var_kv_name'), '/', parameters('para_kvSecretsObject').secrets[copyIndex()].secretName)]",
      "properties": {
        "value": "[parameters('para_kvSecretsObject').secrets[copyIndex()].secretValue]"
      },
      "tags": {
        "displayName": "Key Vault Secrets"
      },
      "type": "Microsoft.KeyVault/vaults/secrets"
    }
```
