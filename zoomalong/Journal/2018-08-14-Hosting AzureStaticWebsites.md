---
layout: post
title: Hosting Azure Static Websites

categories: [Azure, Hosting, Static Websites]
author: "Gary Newport"
date: "2018-08-14"
---

Microsoft announced that you can now enable static websites on a storage account. This will generate a new URL  for your site, and enable read access to any static html files within the blob storage.
There's a link to Microsoft's preview announcement here.
https://azure.microsoft.com/en-us/blog/azure-storage-static-web-hosting-public-preview/

At the moment I prefer the approach made by Anthony Chu in his blog post
https://anthonychu.ca/post/azure-functions-static-file-server/

He hosts a index.html file within a Azure function Http Trigger request. Although this only returns a static file, it does allow you to create a on demand website.
The Html file you serve up can should only contain links to CDN resources or to readable JS or other files within your storage account blob storage.
By proxying the azure function then everything could be accessed via the same URL.

```c#
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Azure.WebJobs.Host;
using MimeTypes;

namespace Counterflip
{
    public static class WebSite
    {
        [FunctionName("WebSite")]
        public static async Task<HttpResponseMessage> Run([HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = null)]HttpRequestMessage req, TraceWriter log)
        {
            log.Info("C# HTTP trigger function processed a request.");

            try
            {
                var response = new HttpResponseMessage(HttpStatusCode.OK);
                var stream = new FileStream(@"www\index.html", FileMode.Open);
                response.Content = new StreamContent(stream);
                response.Content.Headers.ContentType =
                    new MediaTypeHeaderValue(GetMimeType(@"www\index.html"));
                return response;
            }
            catch
            {
                return new HttpResponseMessage(HttpStatusCode.NotFound);
            }
        }

        private static string GetMimeType(string filePath)
        {
            var fileInfo = new FileInfo(filePath);
            return MimeTypeMap.GetMimeType(fileInfo.Extension);
        }
    }
}
```
