---
title:  Reactive Simulations and DSL
summary: "A Brief Introduction to Rhino Reactive Simulations and Load DSL"
series: "ACME series"
weight: 4
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_dsl.html
folder: mydoc
toc: false
---


> **_NOTE_**: The reactive runner and the Load DSL is still in Beta. 

In addition to blocking approach in which the threads will be created in simulation's Threadpool and runs the test for a single users,  Rhino does offer reactive mode in which the Scenarios become Specifications which describe how a load test is to be executed in a declarative way rather, not what to run. The specification can be created by using the Rhino DSL which will be materialized by the framework. 

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
        .run(some("Output").as(userSession -> {
          userSession.<Response>get("result").ifPresent(r -> System.out.println(r.getStatusCode()));
          return "OK";
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

### How to Enable Reactive Pipeline?

To enable reactive pipeline, you need to select [ReactiveHttpSimulationRunner](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/runners/ReactiveHttpSimulationRunner.html) runner in the simulation:

```java
@Runner(clazz = ReactiveHttpSimulationRunner.class)
```

If [ReactiveHttpSimulationRunner](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/runners/ReactiveHttpSimulationRunner.html) is not selected explicitly by adding the Runner annotation, then the [DefaultSimulationRunner](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/runners/DefaultSimulationRunner.html) will be used in simulations which looks for scenario methods.  

### Writing your first DSL

Each DSL begins with `Start.dsl()` followed by runners. Runners are methods to run the spec instances defined in them. Runners can be chained together, they will then run by the same thread sequentially.

```
Start.dsl()
    .run(<some-spec>)
    .runIf(<some-spec>)
    .forEach(<some-spec>)...
``` 

## Specs

Specs are instances to be run by runners so like an [HttpSpec](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/dsl/specs/HttpSpec.html) describing how a Http request might look like:

```java
return Start.dsl()
    .run(http("Files Request")
          .header(c -> from(X_REQUEST_ID, "Rhino-" + UUID.randomUUID().toString()))
          .header(X_API_KEY, SimulationConfig.getApiKey())
          .auth()
          .endpoint(FILES_ENDPOINT)
          .get()
          .saveTo("result"))
``` 

### HttpSpec

[HttpSpec](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/dsl/specs/HttpSpec.html) describes how a Http request looks like. The spec begins with `http(< measurement point >)` and followed by chained builder methods. Measurement point is the identifier and used in reporting. It is the measurement name under which the measurement is recorded.   

```java
http("Files Request")
    .header(c -> from(X_REQUEST_ID, "Rhino-" + UUID.randomUUID().toString()))
    .header(X_API_KEY, SimulationConfig.getApiKey())
    .auth()
    .endpoint(FILES_ENDPOINT)
    .get()
    .saveTo("result")
```

The **header()** method sets the request headers of the spec. There are two forms of header()-methods. The first one takes two parameters, the name of the header and the value of it. It is handy if you work with values. However, sometimes you need to access user session to read some object out of the context, so the second form which takes a lambda with user session might be helpful in this case. Another reason why you might choose to use the lambda-form is whenever you need to access a provider instance:

```java
http("Upload")
    .header(c -> from(X_REQUEST_ID, "Rhino-" + uuidProvider.take()))
    .header(X_API_KEY, SimulationConfig.getApiKey())
    .auth()
    .upload(() -> file("classpath:///test.txt"))
    .endpoint((c) -> FILES_ENDPOINT)
    .put()
    .saveTo("result")
```

Since the DSL-methods will be called only once at the beginning, if you need to use some objects from the providers and every time a new instance of that instance, you must use a lambda form in **header()** and **endpoint()** methods. 

**auth()** call enables authorization headers to be sent in the Http request which requires a repository of authorised users e.g `@UserRepository(factory = OAuthUserRepositoryFactory.class)` on the simulation, so the authorised users can be employed in the simulation. **saveTo("result")** call stores the response object in the context with the key "result" for the next specs in the chain.

## Runners  

The runners accept [Spec](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/dsl/specs/Spec.html) instances like [HttpSpec](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/dsl/specs/HttpSpec.html) describing an HTTP request. As of 1.6.0 there are two runners in the DSL, `run()` and `runIf()` for conditional executions. 

### run

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

The runner above executes [HttpSpec](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/dsl/specs/HttpSpec.html) discovery. 

### runIf

The `runIf` is a conditional runner. You might want to execute some specs if a conditional holds, e.g:

```java
return Start.dsl()
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

In the DSL above, the second run will be executed, if the first run returns an HTTP 200. The predicate expects a parameter of UserSession. More about sessions, please refer to [Sessions](http://ryos.io/mydoc_sessions.html).

### wait

Wait runner holds the pipeline for the duration given:
```java
Start.dsl()
    .wait(Duration.ofSeconds(1))
``` 


### map

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

### forEach

forEach runner is used to iterate over `Iterable<T>` instances stored in the user session:

```java
  @Dsl(name = "Load DSL Request")
  public LoadDsl singleTestDsl() {
    return Start.dsl()
        .run(http("Files Request")
            .header(c -> from(X_REQUEST_ID, "Rhino-" + UUID.randomUUID().toString()))
            .header(X_API_KEY, SimulationConfig.getApiKey())
            .auth()
            .endpoint(FILES_ENDPOINT)
            .get()
            .saveTo("result"))
        .map(MapperBuilder.<Response, List<Integer>> from("result")
            .doMap(response -> getURIs(response)))
        .forEach(in("result").apply(uri -> some("measurement")
            .as((session) -> {
              System.out.println(uri);
              return "OK";
            }))
            .saveTo("result"));
  }
```

The first run of [HttpSpec](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/dsl/specs/HttpSpec.html) returns a list of URIs which are extracted by the method `getURIs(response)` and passed as list of URIs to the forEach runner. forEach runner looks Iterable instances up in the context with the key `in(<key>)` and applies subsequently the spec passed as parameter. 