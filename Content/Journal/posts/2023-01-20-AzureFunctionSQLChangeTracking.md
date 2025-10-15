---
title : SQL Change Tracking
categories: [SQL]
image: /images/sql.png
author: "Gary Newport"
date: "2023-01-20"
---

# Description

As of novemebr 2022, Azure Functions have aquired a new trigger, SQL. 
With some minor changes to a sql database configuration, a Azure Function can capture sql trigger events and report on them.
A useful implementation of this would be to feed data into stream analytics and have a constantly updated dashboard.

```SQL

ALTER DATABASE [Hub.Dev]
SET CHANGE_TRACKING = ON
(CHANGE_RETENTION = 2 DAYS, AUTO_CLEANUP = ON);

ALTER TABLE [dbo].[WebEnquiry]
ENABLE CHANGE_TRACKING;
```

## Sql Table Class
```c#
    public class WebEnquiry
    {
        public string ReferenceId { get; set; }
        public string FirstName { get; set; }
        public string LastName { get; set; }
        public string Type { get; set; }
        public string Source { get; set; }
        public string AdvertPostCode { get; set; }
        public string PropertyBedrooms { get; set; }
        public string OfficeId { get; set; }
        public string PropertyReferenceNumber { get; set; }
        public Guid AssetId { get; set; }
    }
```

## Azure Function SQL Trigger
```c#

    public static class ToDoTrigger
    {
        [FunctionName("WebEnquiry")]
        public static void Run(
            [SqlTrigger("[Hub.Dev].[dbo].[WebEnquiry]", ConnectionStringSetting = "SqlConnectionString")]
            IReadOnlyList<SqlChange<WebEnquiry>> enquires,
            ILogger logger)
        {
            foreach (SqlChange<WebEnquiry> enquiry in enquires)
            {
                WebEnquiry item = enquiry.Item;
                logger.LogInformation($"ReferenceId: {item.ReferenceId}, Source: {item.Source}, AdvertPostCode: {item.AdvertPostCode}, PropertyReferenceNumber: {item.PropertyReferenceNumber}");
            }
        }
    }
```