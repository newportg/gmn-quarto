---
layout: post
title: Storage Accounts
categories: [Azure, Storage Accounts]
image: /images/Storage-Accounts.png
author: "Gary Newport"
date: "2019-02-15"
---

The blob container resource is a sub-resource of the storage account. When you create a storage account, you can now specify an array of storages resources. We are then going to specify objects of type "blobServices/containers", and make sure to use an API version of 2018-02-01 or later.
In the example below, we are creating a storage account with two containers.

```Json
{
    "type": "Microsoft.Storage/storageAccounts",
    "apiVersion": "2018-02-01",
    "name": "[parameters('StorageAccountName')]",
    "location": "[resourceGroup().location]",
    "tags": {
        "displayName": "[parameters('StorageAccountName')]"
    },
    "sku": {
        "name": "Standard_LRS"
    },
    "kind": "StorageV2",
    "properties": {},
    "resources": [
        {
            "type": "blobServices/containers",
            "apiVersion": "2018-03-01-preview",
            "name": "[concat('default/', parameters('Container1Name'))]",
            "dependsOn": [
                "[parameters('StorageAccountName')]"
            ],
            "properties": {
                "publicAccess": "Container"
            }
        },
        {
            "type": "blobServices/containers",
            "apiVersion": "2018-03-01-preview",
            "name": "[concat('default/', parameters('Container2Name'))]",
            "dependsOn": [
                "[parameters('StorageAccountName')]"
            ],
            "properties": {
                "publicAccess": "None"
            }
        }
    ]
}

```

We can then go ahead and deploy this, and see the two containers being created. You can see in the template we are setting different Public Access properties on the two containers, you have a choice of 3 values here:
None (private container)
Container (the whole container is publically accessible)
Blob (only Blobs are publically accessible)

The above example is fine, but you need to specify each of the containers as separate parameters, and remember to add the correct number of container clauses to the script.

So if we specify the containers as a array in the parameters file

```Json
    "para_storageObject": {
      "value": {
        "containers": [
          {
            "containerName": "files"
          },
          {
            "containerName": "elephants"
          },
          {
            "containerName": "bananas"
          }
        ]
      }
    },
```

Then we can use a copy clause to cycle over the array and create our containers in the deploy

```Json
    {
      "apiVersion": "2018-03-01-preview",
      "copy": {
        "name": "containersCopy",
        "count": "[length(parameters('para_storageObject').containers)]"
      },
      "dependsOn": [
        "[concat('Microsoft.Storage/storageAccounts/', variables('var_str_name'))]"
      ],
      "name": "[concat(variables('var_str_name'), '/default/', parameters('para_storageObject').containers[copyIndex()].containerName)]",
      "properties": {
        "publicAccess": "Container"
      },
      "tags": {
        "displayName": "StorageAcct/Containers"
      },
      "type": "Microsoft.Storage/storageAccounts/blobServices/containers"
    },
```

