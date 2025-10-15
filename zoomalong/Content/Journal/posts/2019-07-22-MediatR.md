---
layout: post
title: MediatR
categories: [C#, Patterns]
image: /images/csharp.png
author: "Gary Newport"
date: "2019-07-22"
---


```{.plantuml}
@startuml

skinparam linetype polyline
skinparam linetype ortho

title Mediator Pattern

' classes
interface INotification 
interface INotificationHandler
INotification : mediate()
INotificationHandler : NotifyText()
NotificationMessage : NotifyText()
Notifier1 : Handle()
Notifier2 : Handle()
INotifierMediatorService : NotifyText()

' Set screen position
INotification <- INotificationHandler : mediator
INotification -[hidden]-> NotificationMessage

' Relationship
NotificationMessage --|> INotification
INotificationHandler <|-- Notifier1
INotificationHandler <|-- Notifier2
NotificationMessage -> Notifier1
NotificationMessage -> Notifier2

INotifierMediatorService <|-- NotifierMediatorService
@enduml
```

# Definition
Define an object that encapsulates how a set of objects interact. Mediator promotes loose coupling by keeping objects from referring to each other explicitly, and it lets you vary their interaction independently.

## How's this work?
* INotification (Mediator)
  * Defines an interface for communicating with Colleague objects
* Notifier1, Notifier2 are 
  * Each Colleague class knows its Mediator object
  * Each colleague communicates with its mediator whenever it would have otherwise communicated with another colleague
  * Concrete implementations of the task to be performed, 
  * They need to implement the Handler method defined by the INotificationHandler interface.
* NotificationMessage
  * Implements cooperative behavior by coordinating Colleague objects
knows and maintains its colleagues
  * Instantiates the Notifier classes

## Install
Install-Package MediatR

## Reference
* [Mediatr Framework](https://github.com/jbogard/MediatR)
* [Dot Factory Pattern](https://www.dofactory.com/net/mediator-design-pattern)
* [Medium Article](https://exceptionnotfound.net/mediator-the-daily-design-pattern/)
* [Mediator Tutorial 1](https://dotnetcoretutorials.com/2019/04/30/the-mediator-pattern-in-net-core-part-1-whats-a-mediator/)
* [Mediator Tutorial 2](https://dotnetcoretutorials.com/2019/04/30/the-mediator-pattern-part-2-roll-your-own/)
* [Mediator Tutorial 3](https://dotnetcoretutorials.com/2019/04/30/the-mediator-pattern-part-3-mediatr-library/)
