---
title:  Providers
series: "ACME series"
weight: 4
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_providers.html
folder: mydoc
---

Providers are used to feed data into test entities. Rhino framework is capable inject provider instances into injection points, that are class fields annotated with @Provider annotations. Provider interface's take() method newly created objects which can be used in DSLs. There are standard providers provided by the framework, like UUIDProvider and UserProvider, which can be used to feed user information into the tests.

The provider instances are injected to class fields annotated with `@Provider` annotation, except the user providers which have their own annotation `@UserProvider`:

```java
@Simulation(name = "Server-Status Simulation")
public class PerformanceTestingExample {

  @UserProvider
  private OAuthUserProvider userProvider;

  @Provider(factory = UUIDProvider.class)
  private UUIDProvider uuidProvider;
}
```
Now, you can use the providers to create new objects:

```java
  @Dsl(name = "Upload File")
  public LoadDsl testUploadAndGetFile() {
    return Start
        .dsl()
        .session("2. User", () -> userProvider.take())
        .run(http("PUT text.txt")
            .header(session -> from(X_REQUEST_ID, "Rhino-" + uuidProvider.take()))
            .header(X_API_KEY, SimulationConfig.getApiKey())
            .auth()
            .endpoint(session -> FILES_ENDPOINT)
            .upload(() -> file("classpath:///test.txt"))
            .put());
  }
```

In addition to standard providers, the developers may wish to create their custom providers by implementing the interface `Provider<T>`:

```java
public class UUIDProvider implements Provider<String> {

  @Override
  public String take() {
    return UUID.randomUUID().toString();
  }
}
```

In the `com.adobe.rhino.sdk.providers` package, you will find some useful provider implementations, that you can use in your projects. 

