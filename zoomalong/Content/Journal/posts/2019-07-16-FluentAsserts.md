---
layout: post
title: Fluent Assertions
categories: [C#, Fluent Assertions]
image: /images/csharp.png
author: "Gary Newport"
date: "2019-07-16"
---

Fluent Assertions is a helper library for testing that tries to add better context to your assertions.

E.g.
* Where you would have used 
  * Assert.AreEqual(HttpStatusCode.OK, response.StatusCode);
* or should it have been 
  * Assert.AreEqual(response.StatusCode, HttpStatusCode.OK);

* You can now do this :-
  * response.StatusCode.Should().Be(HttpStatusCode.OK);

  Other than making the calling more explicit, it also gives a a clearer error message on failure.

  Message: Expected response.StatusCode to be NotFound, but found OK.

 ## Reference: 
  * https://fluentassertions.com/
