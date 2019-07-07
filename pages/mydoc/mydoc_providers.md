---
title:  Providers
summary: "A Brief Introduction to Rhino Providers"
series: "ACME series"
weight: 4
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_providers.html
folder: mydoc
---

Providers are used to feed information into test entities at injection points. There are standard providers provided by the framework, like UUIDProvider and UserProvider, which can be used to feed user information into the tests.

The provider instances are injected to class fields annotated with `@Provider` annotation:

```java
@Simulation(name = "Server-Status Simulation")
public class PerformanceTestingExample {

  @UserProvider
  private OAuthUserProvider userProvider;

  @Provider(factory = UUIDProvider.class)
  private UUIDProvider uuidProvider;
}
```

In addition to standard providers, the developers may wish to add their custom providers. In this case, the `@Provider` annotation expects a provider class:

```java
@Simulation(name = "Reactive Sleep Test")
@Runner(clazz = ReactiveHttpSimulationRunner.class)
@RampUp(startRps = 1, targetRps = 10)
public class ReactiveSleepTestSimulation {

  @Provider(factory = UUIDProvider.class)
  private UUIDProvider provider;

}
```

and the provider itself:

```java
public class UUIDProvider implements Provider<String> {

  @Override
  public String take() {
    return UUID.randomUUID().toString();
  }
}


```

In the `com.adobe.rhino.sdk.providers` package, you will find some useful feeder implementations e.g UUIDProvider, that you can use in your projects. 

