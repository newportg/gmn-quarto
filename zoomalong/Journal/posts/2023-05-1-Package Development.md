---
title : How to build Cloud components without any Azure Experience
Published: 2023/05/11
Tags: Architecture
Category: Architecture
---

# How to build Cloud components without any Azure Experience
It is a bit of a misnomer; you need people with cloud experience.

Sorry I am not going to say anything new here, but it just might be new here.

In typical application code is the same no matter what platform you develop on, you have an interface to the world, domain/business rules, and a data interface. Only the interface to the world needs to be managed by someone with more specialised knowledge.
You could divide up the code and create two projects, one for the API, specialised to the environment it will be deployed, and one for the domain/business logic. This would enable you to simply wrap the domain/business rules in its own NuGet package and use normal developers to create them and allow them to use tradition tools to build and evaluate them.

 <img src="https://raw.github.com/newportg/newportg.github.io/master/assets/package1.png" alt="Package1" width="400"/>


The previous solution would be fine, but it still leaves scope for organically grown code, which encapsulates complex business rules.
The build test burden could be reduced further by making the projects even smaller. Reducing their complexity and increasing their automatic testability. In this case the Domain logic could be reduced to encoding process flow only, and business rules evaluation could be managed by a more suitable tool. Also if the data store interface is not specific to this application but a general interface used by many applications, then it also could make use of package management. 

 <img src="https://raw.github.com/newportg/newportg.github.io/master/assets/package2.png" alt="Package2" width="400"/>
 

The questions, I keep hearing when there is a proposed change in development strategy, such as 
•	How do we keep up with package versioning 
•	How do we make sure all applications are using the same package versions

The simple answer is developers should use good development practices.
1.	At the start of any new development, they should
a.	Run the unit tests
b.	Get the latest packages
c.	Run the unit tests
d.	Fix any issues caused by the updated packages
e.	Run the unit tests
2.	Create new code
3.	Create new tests
a.	Run the unit tests 
4.	Create a check in note
5.	Check in
The only project where package version matters is the API project, as that what is presented to the user.
