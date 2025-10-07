---
title: Adaptive Cards
Published: 2020/11/14
Tags: AdaptiveCard
---

Adaptive Cards is a Json structure which describes how to display information in various Microsoft Applications.
Currently the standard is at version 1.2, and the definition can be seen here https://AdaptiveCards.io

```json
{
    "$schema":"http://adaptivecards.io/schemas/adaptive-card.json",
    "type":"AdaptiveCard",
    "version":"1.2",
    "body":[
        {
        "type": "TextBlock",
        "text": "For Samples and Templates, see https://adaptivecards.io/samples](https://adaptivecards.io/samples)",
        }
    ]
}
```

# Microsoft Teams Webhooks
In order to send Adaptive Card structures to Teams webhooks, you need to surround the json with MessageCard structure.

```json
{
   "type":"message",
   "attachments":[
      {
         "contentType":"application/vnd.microsoft.card.adaptive",
         "contentUrl":null,
         "content":{
```Adaptive Card goes here
         }
      }
   ]
}
```

# Reference
* [Adaptive Cards](https://adaptivecards.io/)
* [Microsoft Teams WebHook](https://docs.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/connectors-using#send-adaptive-cards-using-an-incoming-webhook)
* [Adative Cards for Blazor](https://www.adaptivecardsblazor.com/gettingstarted.html)

# Useful Example

## Result

![Teams-AdaptiveCard](/images/teamsadaptivecard.png)



## Json
```Json
{
	"type": "message",
	"attachments": [
		{
			"contentType": "application/vnd.microsoft.card.adaptive",
			"contentUrl": null,
			"content": {
				"$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
				"type": "AdaptiveCard",
				"version": "1.2",
                "body": [
                    {
                        "type": "TextBlock",
                        "size": "Medium",
                        "weight": "Bolder",
                        "text": "Image WaterMark Exception"
                    },
                    {
                        "type": "ColumnSet",
                        "columns": [
                            {
                                "type": "Column",
                                "items": [
                                    {
                                        "type": "Image",
                                        "style": "Default",
                                        "url": "https://www.knightfrank.com/library/v3.0/images/knightfranklogo.png",
                                        "size": "Large"
                                    }
                                ],
                                "width": "auto"
                            },
                            {
                                "type": "Column",
                                "items": [
                                    {
                                        "type": "TextBlock",
                                        "weight": "Bolder",
                                        "text": "WaterMark Validator",
                                        "wrap": true
                                    },
                                    {
                                        "type": "TextBlock",
                                        "spacing": "None",
                                        "text": "Created {{DATE(2017-02-14T06:08:39Z,SHORT)}}",
                                        "isSubtle": true,
                                        "wrap": true
                                    }
                                ],
                                "width": "stretch"
                            }
                        ]
                    },
                    {
                        "type": "ColumnSet",
                        "columns": [
                            {
                                "type": "Column",
                                "items": [
                                    {
                                        "type": "Image",
                                        "style": "Default",
                                        "url": "https://content.knightfrank.com/property/cbm190150/images/b2bee1c5-3dfa-4bbd-9d13-94cde2044822-0.jpg?cio=true&w=730",
                                        "size": "Large"
                                    }
                                ],
                                "width": "auto"
                            },
                            {
                                "type": "Column",
                                "items": [
                                    {
                                        "type": "TextBlock",
                                        "text": "A Watermark has been detected in this image",
                                        "wrap": true
                                    }
                                ],
                                "width": "stretch"
                            }
                        ]
                    }
                ],
                "actions": [
                    {
                        "type": "Action.OpenUrl",
                        "title": "View",
                        "url": "https://hub.knightfrank.com/#/app/activity/view/60c1d8fb-1bd7-ea11-a95a-000d3ab2efee?tabname=Marketing"

                    }
                ]
			}
		}
	]
}
```