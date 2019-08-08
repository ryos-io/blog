---
title:  Reactive Simulations and DSL
summary: "A Brief Introduction to Rhino Reactive Simulations and Load DSL"
series: "ACME series"
weight: 4
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_dsl.html
folder: mydoc
---


> **_NOTE_**: The reactive runner and the Load DSL is still in Beta. 

In addition to blocking approach in which the threads will be created in simulation's Threadpool and runs the test for a single users,  Rhino does offer reactive mode in which the Scenarios become Specifications which describe how a load test is to be executed in a declarative way, not what to run. The specification can be created by using the Rhino DSL which will be materialized by the framework. 

```java
@Simulation(name = "Reactive Test", durationInMins = 5)
@Runner(clazz = ReactiveHttpSimulationRunner.class)
@UserRepository(factory = OAuthUserRepositoryFactory.class)
public class ReactiveBasicHttpGetSimulation {

  @Dsl(name = "Discovery")
  public LoadDsl singleTestDsl() {
    return Start.dsl()
        .run(http("Discovery")
            .header(c -> from(X_REQUEST_ID, "Rhino-" + userProvider.take()))
            .header(X_API_KEY, SimulationConfig.getApiKey())
            .auth()
            .endpoint(DISCOVERY_ENDPOINT)
            .get()
            .saveTo("result"))
        .run(some("Output").as((userSession, measurement) -> {
          userSession.<Response>get("result").ifPresent(r -> System.out.println(r.getStatusCode()));
          return userSession;
        }));
  }

  @Prepare
  public static void prepare() {
    System.out.println("Preparation in progress.");
  }

  @CleanUp
  public static void cleanUp() {
    System.out.println("Clean-up in progress.");
  }
}

```

### How to Enable Reactive Pipeline

To enable reactive pipeline, you need to select [ReactiveHttpSimulationRunner](http://ryos.io/javadocs/apidocs/io/ryos/rhino/sdk/runners/ReactiveHttpSimulationRunner.html) runner in the simulation:

```java
@Runner(clazz = ReactiveHttpSimulationRunner.class)
```

If [ReactiveHttpSimulationRunner](http://ryos.io/javadocs/apidocs/io/ryos/rhino/sdk/runners/ReactiveHttpSimulationRunner.html) is not selected explicitly by adding the Runner annotation, then the [DefaultSimulationRunner](http://ryos.io/javadocs/apidocs/io/ryos/rhino/sdk/runners/DefaultSimulationRunner.html) will be used in simulations which looks for scenario methods.  

### Writing your first DSL

Each DSL begins with `Start.dsl()` followed by runners. Runners are methods to run the spec instances defined in them. Runners can be chained together, they will then run by the same thread sequentially.

```
Start.dsl()
        .run(<some-spec>)
        .run(<some-spec>)
        .run(<some-spec>)...
``` 

### Runners  

The runners accept `Spec` instances like `HttpSpec` describing an HTTP request. As of 1.6.0 there are two runners in the DSL, `run()` and `runIf()` for conditional executions. 

#### run(<Spec>)

Most times, you will work with this runner. It accepts `Spec` instances as parameter: 

```java
run(http("Discovery")
            .header(c -> from(X_REQUEST_ID, "Rhino-" + userProvider.take()))
            .header(X_API_KEY, SimulationConfig.getApiKey())
            .auth()
            .endpoint(DISCOVERY_ENDPOINT)
            .get()
            .saveTo("result"))
``` 

The runner above executes `HttpSpec` discovery. 

#### runIf(<Spec>)

The `runIf` is a conditional runner. You might want to execute some specs if a conditional holds, e.g:

```java
    return Start
        .dsl()
        .run(http("Upload text.txt")
            .header(c -> from(X_REQUEST_ID, "Rhino-" + userProvider.take()))
            .header(X_API_KEY, SimulationConfig.getApiKey())
            .auth()
            .endpoint((c) -> UPLOAD_TARGET)
            .upload(() -> file("classpath:///test.txt"))
            .put()
            .saveTo("result"))
        .runIf((session) -> session.<Response>get("result").map(r -> r.getStatusCode() == 200).orElse(false),
            http("Read File")
                .header(c -> from(X_REQUEST_ID, "Rhino-" + userProvider.take()))
                .header(X_API_KEY, SimulationConfig.getApiKey())
                .auth()
                .endpoint((c) -> UPLOAD_TARGET)
                .get());
```

In the DSL above, the second run will be executed, if the first run returns an HTTP 200. The predicate expects a parameter of UserSession. More about sessions, please refer to [Sessions](https://github.com/ryos-io/Rhino/wiki/Sessions).

#### map(<Spec>)

Map runner together with map builder is used to transform one runner's result into another object.

```java
   Start.dsl()
        .run(http("Files Request")
            .header(c -> from(X_REQUEST_ID, "Rhino-" + UUID.randomUUID().toString()))
            .header(X_API_KEY, SimulationConfig.getApiKey())
            .auth()
            .endpoint(FILES_ENDPOINT)
            .get()
            .saveTo("result"))
        .map(MapperBuilder.<Response, Integer>
             from("result").doMap(response -> response.getStatusCode()))

```

In the example, we are mapping the HttpResponse type into Integer by calling getStatusCode()- method on it.