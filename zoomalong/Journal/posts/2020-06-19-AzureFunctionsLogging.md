---
layout: post
title: Azure Functions Logging
categories: [C#, Azure Functions]
image: /images/function-apps.png
author: "Gary Newport"
date: "2020-06-19"
---

Azure Functions include a built in ILogger so you can fulfill all your logging needs,
There is one issue, if you try to use the Ilogger in any of you subsequent classes the ILogger seems to be null.

# Example

```c#
namespace MyFunctionApp
{
    public class MyFunctionClass
    {
        private readonly ILogger logger;

        // DOESN'T WORK!
        public MyFunctionClass(ILogger logger)
        {
              this.logger = logger;
        }

        [FunctionName("MyFunctionName")]
        public async Task<IActionResult> MyFunctionMethod(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = null)]
            HttpRequest req,
            ILogger log) // WORKS!
       {
           ...
       }
    }
}
```

# Solution 
The solution is simple but a little annoying :(
Instead of using the ILogger use ILogger<> instead putting the class name as the type.
       
```c#
public class MyFunctionClass
    {
        private readonly ILogger logger;

        // WORKS!
        public MyFunctionClass(ILogger<MyFunctionClass> logger)
        {
              this.logger = logger;
        }
        ...
    }
```
There is an additional gotcha, which has been raised to Microsoft as a bug, and that is you need to specify your <b>NameSpaces</b> that uses the ILogger in the hosts.json file

```json
{
    "version": "2.0",
    "logging": {
        "logLevel": {
            "MyFunctionApp": "Trace"
            }
        }
    }
}
```


