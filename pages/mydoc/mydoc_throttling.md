---
title:  Ramp-up and Throttling
summary: "A Guide to Tests Users in Simulations"
series: "ACME series"
weight: 4
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_users.html
folder: mydoc
---

The number of requests the framework is to make, can be limited with `@Throttle` annotation on entity classes. 
The `@RampUp` annotation is used to control the request volume while load testing starts. 

Ramp up requires three attributes, start RPS, that is the request-per-second at start, and a target RPS and the duration, in which the ramp up is applied:

```java
@Simulation(name = "Reactive Test", durationInMins = 5)
@Runner(clazz = ReactiveHttpSimulationRunner.class)
@UserRepository(factory = OAuthUserRepositoryFactory.class)
@RampUp(startRps = 10, targetRps = 2000, duration = 1)
public class RhinoEntity {
}
```

and the throttling is similar to ramp-up setup: 

```java
@Simulation(name = "Reactive Test", durationInMins = 5)
@Runner(clazz = ReactiveHttpSimulationRunner.class)
@UserRepository(factory = OAuthUserRepositoryFactory.class)
@Throttle(numberOfRequests = 1000, durationInMins = 1)
public class RhinoEntity {
}
```

at this time, the number of request, that the framework is to make, is limited by numberOfRequests value till the durationInMins expires.
