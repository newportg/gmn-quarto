---
title : Service Application Development
Published: 2022/11/10
Tags: Identity
Category: Architecture
---

# Description

For to long there has been little thought about the consequences of changing code that is not strictly associated with the task assigned, this has been made possible by the solution containing all the code for the entire application.  This had been the practice years ago but has been widely dismissed due the revolution of agile design and coding.
Moving forward with a service-oriented application design, the code should be split along functional lines, where each function becomes a self-contained package which can be reused.
Packaging up functionality has been common practice for several years as it promotes 
*	Specialisation, forcing the components to do ‘one thing and one thing only’. 
*	Simpler testing.
*	Versioning
*   Ease of upgrade


<img src="https://raw.github.com/newportg/newportg.github.io/master/assets//ServiceApplicationMonolith.png" alt="Service Application Monolith" width="400"/>


# Consequences

This break up of the monolith is not without its drawbacks, at least in the begining.
The usual complaints are :- 
* Code is being duplicated.
  * Yes, it will be, until all the relervant functionality has been encapsulated.
* Paying again, for no additional functionality.
  * Yes, we will be, For historical reasons of a lack of control on our part.
  * Or a philosophy of keep the hopper full and pushing ever forward with business functionality, and forgetting any technical requirements.

