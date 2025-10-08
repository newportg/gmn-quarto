---
title : Web Upload File AV Scanning
categories: [Identity]
image: /images/mi.png
author: "Gary Newport"
date: "2023-01-19"
---

# Description

Web file uploads within a company has been a neglected space for a while now, as any file the appears on a laptop or via email is scanned by the inbuild Anti Virus software, 
but with new projects opening up internal strorage to external entities via web portals we have to consider the fact that somone could upload a file containing a virus and we would be none the wiser.
For us to write a Anti Virus scanning tool is out of the question, even employing a piece of opensource software is not advisable, as we have no idea how upto date the virus templates are, or even if they are valid.

A solution would be to send any prospective file to a external third party who specialises in file scanning and verification. A possible solution is descibed below.


<img src="https://raw.github.com/newportg/newportg.github.io/master/assets//File-AV-Scanning.png" alt="File AV Scanning" width="400"/>


# A Solution
* A file is uploaded via a a Wb Upload tool.
* The web application registers its interest in file upload statuses with the SignalR handler
* The file is passed to the Document API
* The Document API passes the document to a Third Party AV scanning company.
  * Because a document could contain more than one file, It could take the Third Party a while to scan the complete document, so they normally make use of a Webhook interface so they can asynchronously send back a response.
* The Document API receives a response and posts a success or fail message to the Event Grid File Upload Topic.
* If the AV response was a success the file is written to the blob storage.

The notification pattern of EventGrid Topic/ Azure Function / Azure SignalR is a standard pattern.
There is also a pattern for securing webhooks, although webhooks are not loved by all.



