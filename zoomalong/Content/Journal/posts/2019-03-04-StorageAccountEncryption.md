---
layout: post
title: Storage Account Encryption
categories: [Azure, Storage Accounts]
image: /images/Storage-Accounts.png
author: "Gary Newport"
date: "2019-03-04"
---

By default storage accounts are encrypted, and Microsoft holds the keys.
The encryption that is used is AES 256 bit, as it is one of the strongest ciphers currently available.

* Azure storage services:
  * Azure Managed Disks
  * Azure Blob storage
  * Azure Files
  * Azure Queue storage
  * Azure Table storage. 
  * Both performance tiers (Standard and Premium). 
  * Both deployment models (Azure Resource Manager and classic).

The one big issue with this is that Microsoft owns the encryption key and potentially has unrestricted access to the users data.
They have included the facility for the user to specify an encryption key, so you can meet your individual company security or regulatory compliance needs.
To use your own key, you will need.
* A Key Vault 
  * Needs to be in the same region as the storage
  * Does not need to be in the same subscription
* Storage needs permissions to access your Key Vault.
    * Need to grant wrapKey, unwrapKey privileges

## Data Encryption
A key point to understand, the data itself is not encrypted with the key. Microsoft employs a two stage encryption process which involves a DEK (Data Encryption Key) and a KEK (Key Encryption Key). 
The DEK is generated when the storage account is created, and is used to encrypt the data. The DEK is it self is encrypted with a key that Microsoft holds (KEK), Its this Microsoft key that can be replaced with the users own key. 

## Key Rotation
 This is currently under development by Microsoft.
 Key rotation is a process where the KEK (see Data Encryption above) is rotated every 90 days, this involves decrypting the existing key and re-encrypting it with a newly generated key. 

## References
* https://docs.microsoft.com/en-us/azure/storage/common/storage-service-encryption
