---
title : Event Notificiation
Published: 2023/01/20
Tags: Web
Category: Architecture
---

# Description

Azure Event Grid with Topics is a enterprise grade notification engine which mimics Azure Service Bus in many ways, 
Where it differes from Service Bus is that it is a serverless component, and has no physical storage of messages, so cannot, in the event of a incident, gaurentee delivery.
What id does however offer in a normal operating environment is a fast, low latency delivery of messages that can be consumed easily.

The following description shows a particular implementation of event grid messaging, which is used in conjunction with Azure SignalR so that a web GUI can receive notifications.


<img src="https://raw.github.com/newportg/newportg.github.io/master/assets/EventGridSignalR.png" alt="Web Notifications" width="400"/>

* The Web page gets the SignalR connection from the Azure Function.
* The Event Source publishes a message to a Event Grid Topic.
* The Azure Function subscribes to a particular topic, the Event Grid can have many topics.
* The Azure Function publishes the message to SignalR 
* The Web page receive the message from the signalR WebSocket.


# Appendix
## Azure Function
```
    public static class CloudEventSubscription
    {
        // Azure Function for handling negotation protocol for SignalR. It returns a connection info
        // that will be used by Client applications to connect to the SignalR service.
        // It is recommended to authenticate this Function in production environments.
        [FunctionName("negotiate")]
        public static SignalRConnectionInfo GetSignalRInfo(
            [HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req,
            [SignalRConnectionInfo(HubName = "cloudEventSchemaHub")] SignalRConnectionInfo connectionInfo,
            ILogger log)
        {
            log.LogInformation("negotiate");
            return connectionInfo;
        }

        // Azure Function for handling Event Grid events using CloudEventSchema v1.0 
        // (see CloudEvents Specification: https://github.com/cloudevents/spec)
        [FunctionName("EventSubscription")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "POST", "OPTIONS", Route = null)] HttpRequest req,
            [SignalR(HubName = "cloudEventSchemaHub")] IAsyncCollector<SignalRMessage> signalRMessages,
            ILogger log)
        {
            log.LogInformation("CloudEventSubscription");

            // Handle EventGrid subscription validation for CloudEventSchema v1.0.
            // It sets the header response `Webhook-Allowed-Origin` with the value from 
            // the header request `Webhook-Request-Origin` 
            // (see: https://docs.microsoft.com/en-us/azure/event-grid/cloudevents-schema#use-with-azure-functions)
            if (HttpMethods.IsOptions(req.Method))
            {
                log.LogInformation("CloudEventSubscription - Options");
                if (req.Headers.TryGetValue("Webhook-Request-Origin", out var headerValues))
                {
                    log.LogInformation("CloudEventSubscription - Webhook-Request-Origin");
                    var originValue = headerValues.FirstOrDefault();
                    if(!string.IsNullOrEmpty(originValue))
                    {
                        req.HttpContext.Response.Headers.Add("Webhook-Allowed-Origin", originValue);
                        return new OkResult();
                    }
                    log.LogInformation("CloudEventSubscription - Missing Webhook-Request-Origin");
                    return new BadRequestObjectResult("Missing 'Webhook-Request-Origin' header when validating");
                }
            }
            
            // Handle an event received from EventGrid. It reads the event from the request payload and send 
            // it to the SignalR serverless service using the Azure Function output binding
            if(HttpMethods.IsPost(req.Method)) 
            {
                string @event = await new StreamReader(req.Body).ReadToEndAsync();
                await signalRMessages.AddAsync(new SignalRMessage
                {
                    Target = "newEvent",
                    Arguments = new[] { @event }
                });
            }

            log.LogInformation("CloudEventSubscription - SignalR Post");
            return new OkResult();
        }
    }
```

## Angular
```Angular
import { Component } from '@angular/core';
import * as SignalR from '@microsoft/signalr';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.css']
})
export class AppComponent {

  title = 'viewer-app';
  events: string[] = [];

  private hubConnection: SignalR.HubConnection;

  constructor() {
    // Create connection
    this.hubConnection = new SignalR.HubConnectionBuilder()
      .withUrl("https://func-pocegsr-vse-ne.azurewebsites.net/api/")
      .build();

    // Start connection. This will call negotiate endpoint
    this.hubConnection
      .start();

    // Handle incoming events for the specific target
    this.hubConnection.on("newEvent", (event) => {
      this.events.push(event);
    });
  }
}
```

## Arm Template
```JSON
    {
      "type": "Microsoft.SignalRService/SignalR",
      "apiVersion": "2022-02-01",
      "name": "[variables('var_sr_name')]",
      "location": "[resourceGroup().location]",
      "sku": {
        "name": "Standard_S1",
        "tier": "Standard",
        "size": "S1",
        "capacity": 1
      },
      "kind": "SignalR",
      "properties": {
        "tls": {
          "clientCertEnabled": false
        },
        "features": [
          {
            "flag": "ServiceMode",
            "value": "Serverless",
            "properties": {}
          },
          {
            "flag": "EnableConnectivityLogs",
            "value": "True",
            "properties": {}
          }
        ],
        "cors": {
          "allowedOrigins": [
            "*"
          ]
        },
        "upstream": {},
        "networkACLs": {
          "defaultAction": "Deny",
          "publicNetwork": {
            "allow": [
              "ServerConnection",
              "ClientConnection",
              "RESTAPI",
              "Trace"
            ]
          },
          "privateEndpoints": []
        },
        "publicNetworkAccess": "Enabled",
        "disableLocalAuth": false,
        "disableAadAuth": false
      },
      "tags": {
        "displayName": "SignalR"
      }
    },
    {
      "type": "Microsoft.EventGrid/topics",
      "apiVersion": "2021-12-01",
      "name": "[variables('var_egt_name')]",
      "location": "[resourceGroup().location]",
      "identity": {
        "type": "None"
      },
      "properties": {
        "inputSchema": "CloudEventSchemaV1_0",
        "publicNetworkAccess": "Enabled",
        "inboundIpRules": [],
        "disableLocalAuth": false
      },
      "tags": {
        "displayName": "Event Grid Topic"
      }
    },
```

