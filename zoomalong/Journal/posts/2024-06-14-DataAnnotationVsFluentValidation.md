---
title: Data Annotation Vs FluentValidation
categories: [C#, Rules, Patterns]
image: /images/csharp.png
author: "Gary Newport"
date: "2024-09-20"
---

# Data Annotation 

* For 
  * Is SOLID
    * Validations are placed in the model, next to the defintions
  * Part of standard library
* Against
  * Validations are not Rules, and cannot span members
  * Only represents simple validations in the openapi schema


# Fluent Validation

* For
  * Rules can span multiple methods
* Against
    * Not SOLID
      * Validations and Rules are specified in a separate file 
    * Only represents simple validations in the openapi schema
    * Additonal setup


# Conclusion
I've changed my mind, which is not uncommon. 
Where your class is interfacing with a different system such as being used in a API interface, then you need to convey to the user the maximum amount of information, about what is or isnt valid, so the validation details have to be encoded in the model.
Where Data Annotations is lacking, E.g. OneOf, AnyOf, then you should build a custom validator to fill the gap.

Fluent Validation should be used internally, as it not only can apply general validations, it can also encode groups of validations into rules and apply them under different conditions.

# Ref 
This is a interesting read on validators, and also the implementation of custom validators.
https://weblogs.asp.net/ricardoperes/net-8-data-annotations-validation
