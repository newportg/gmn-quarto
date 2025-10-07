---
layout: post
title: Azure Application Hosting

categories: [Azure, Hosting]
author: "Gary Newport"
date: "2018-08-14"
---

Each component is a separately deploy-able artefact, but we need a coherent single URL to link them all.
The normal method would be to deploy out each individual component to Azure and each would get its own 'aurewebsites.com' URL. This approach would lead to confusion, as it would mean you would need to keep lists of URL's
By using the proxy feature of Azure Functions we can define routes to each of the installed artefacts while preserving a single URL for the application.
So:-

|Route | Result|
|------|-------|
|zoomalong.co.uk | Website|
|zoomalong.co.uk/api | Azure functions|
|zoomalong.co.uk/static | Azure Storage Account|

Used to store any files or images etc.
Because both the API and Web Application exist on the same URL then we won't run into any CORS issues.
Remember to bind the DNS Cname to the Azure function proxy and not the website.

![aah1](/images/aah1.png)


How ?
In your Azure Functions Project
Create a files called proxies.json and insert the following code

```
proxies.json
{
  "$schema": "http://json.schemastore.org/proxies",
    "proxies": {
      "api": {
        "matchCondition": {
          "route": "/api/{*url}"
        },
        "backendUri": "Set With Build Variable/{url}"
      },
      "app": {
        "matchCondition": {
          "route": "{*url}",
          "methods": [ "GET", "HEAD", "OPTIONS" ]
        },
        "backendUri": "Set With Build Variable/{url}"
      },
      "appResources": {
        "matchCondition": {
          "route": "/static/{*url}",
          "methods": [ "GET", "HEAD", "OPTIONS" ]
        },
        "backendUri": "Set With Build Variable/{url}"
      }
    }
  }
```

Change in the build.
* Build should include Azure App Service Deploy V3 or greater
* Update this section with the file to be changed.
  * ![aah2](/images/aah2.png)
* Add your substitutions to the Variables section
	* As Path to variable to be replace element.element.element
	* Value to be replaced.
	* as below

|Proxy|URL|
|-----|---|
|proxies.api.backendUri | https://azure website url|
|proxies.app.backendUri | https://azure function url|
|proxies.appResources.backendUri | https:// azure storage account blob strorage|

* Repeat in the release.



