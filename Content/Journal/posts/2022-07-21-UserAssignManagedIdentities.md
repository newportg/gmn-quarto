---
title : User Assigned Managed Identities
categories: [Identity]
image: /images/mi.png
author: "Gary Newport"
date: "2022-07-21"
---

# What
A Managed Identity is a Azure resource which comprises two components.
* A resource. A resource will create a Identity in Azure AD
* An Azure Role 

Therefore by giving a AD registered App the Managed Identity Role, when the app trys to connect Ad will give permission without the need for any auth flow credentials to be passed.


Managed identities eradicate the need to manage credentials within your code. A components identity is lodged within Active Directory, and makes available a AD Token for other componets to consume.
The AD token gives the consuming compoent access rights to the original resource.

There are two types of Mangaged Identities, System assigned and User assigned.
System assigned identities are tied to the resource that creates them, so when the resource is deleted, so is the identity, whereas user assigned identities exist idependantly whithin AD and can be assign to several resources.

e.g As in the example below. A User Assigned managed identity is created and both a Azure Function and Azure Sql Server share the identity.

# ARM Script

## Variables
```json
    "var_id_name": "[concat(variables('namingConvention').prefixes.Identity, '-', variables('var_application_name_delim'),  parameters('para_acronym_region'))]",
    "var_uaid_name": "[concat('/subscriptions/',variables('var_sub_id'),'/resourcegroups/', resourceGroup().Name, '/providers/Microsoft.ManagedIdentity/userAssignedIdentities/', tolower(variables('var_id_name')))]"

```

## Ctrate Resources
The following ARM snippets show how you define and assign a User Assigned Identity to a Azure Function and Azure Sql Server, this will allow the Azure function to access the server.

### Create a User Assigned Managed Identity
```json
    {
      "type": "Microsoft.ManagedIdentity/userAssignedIdentities",
      "apiVersion": "2018-11-30",
      "name": "[variables('var_id_name')]",
      "location": "[resourceGroup().location]",
      "tags": {
        "displayName": "Managed Identity"
      }
    },
```

### Create a Azure Function, with both a System and User Assigned Identity
```json
    {
      "apiVersion": "2021-02-01",
      "dependsOn": [
        "[concat('Microsoft.Web/serverfarms/', variables('var_svcpln_name'))]"
      ],
      "identity": {
        "type": "SystemAssigned, UserAssigned",
        "userAssignedIdentities": {
          "[variables('var_uaid_name')]": {}
        }
      },
      "kind": "functionapp",
      "location": "[resourceGroup().location]",
      "name": "[variables('var_azf_name')]",
      "properties": {
        "state": "[parameters('para_funcState')]",
        "name": "[variables('var_azf_name')]",
        "siteConfig": {
          "alwaysOn": "[parameters('para_alwaysOn')]"
        },
        "clientAffinityEnabled": false,
        "serverFarmId": "[variables('var_svcpln_name')]",
        "hostNameSslStates": [],
        "httpsOnly": true
      },
      "resources": [
      ],
      "tags": {
        "displayName": "Az Function"
      },
      "type": "Microsoft.Web/sites"
    },
```

### Create a Azure Sql Server with User Assigned Identity
```json
    {
      "type": "Microsoft.Sql/servers",
      "apiVersion": "2021-02-01-preview",
      "dependsOn": [
        "[resourceId('Microsoft.KeyVault/vaults/', variables('var_kv_name'))]"
      ],
      "name": "[variables('var_sql_name')]",
      "location": "eastus",
      "kind": "v12.0",
      "identity": {
        "type": "UserAssigned",
        "userAssignedIdentities": {
          "[variables('var_uaid_name')]": {}
        }
      },
      "properties": {
        "administratorLogin": "[parameters('para_dbUsr')]",
        "administratorLoginPassword": "[parameters('para_dbPwd')]",
        "version": "12.0",
        "minimalTlsVersion": "1.2",
        "publicNetworkAccess": "Enabled",
        "primaryUserAssignedIdentityId": "[variables('var_uaid_name')]",
        "administrators": {
          "administratorType": "ActiveDirectory",
          "principalType": "Group",
          "login": "Hub-Sec-DB-Grp",
          "sid": "1b2a41cc-232c-4d73-9b30-9159697bec2d",
          "tenantId": "55a71488-bbff-4451-a18d-a1bfa479293b"
        },
        "restrictOutboundNetworkAccess": "Disabled"
      },
      "tags": {
        "displayName": "Sql Server"
      }
    },
```

## Azure Function
The following snippet shows how you can access the Azure Sql Server from a Azure Function. notice how the connection string indicated that authentication is handled by the managed identity.

So on a connection being made Sql with take a Identity token pased by the function and validate it with identity in AD.

```c#
public static class Function1
{
    private static SqlConnection connection = new SqlConnection();

    [FunctionName("Function1")]
    public static async Task<IActionResult> Run(
        [HttpTrigger(AuthorizationLevel.Function, "get", "post", Route = null)] HttpRequest req,
        ILogger log)
    {
        try
        {
            connection.ConnectionString = "Server=sql-mifunctest-vse-ne.database.windows.net; Authentication=Active Directory Managed Identity; Database=MiFuncTest";
            await connection.OpenAsync();
            var cmd = connection.CreateCommand();
            cmd.CommandText = "select * from [dbo].[WebEnquiry]";

            var response = await cmd.ExecuteReaderAsync();

            var result = "";
            while (response.Read())
            { 
                Console.WriteLine(response["Id"].ToString());
                result += response["Id"].ToString() + "\n";
            }
            response.Close();

            return new OkObjectResult($"The database connection is: {connection.State}  Result {result}");
        }
        catch (SqlException sqlex)
        {
            return new OkObjectResult($"The following SqlException happened: {sqlex.Message}");
        }
        catch (Exception ex)
        {
            return new OkObjectResult($"The following Exception happened: {ex.Message}");
        }
    }
}

```