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

In addition to blocking approach in which runner threads will be created in simulation's Threadpool and runs the scenarios for a single user,  Rhino does offer reactive-mode in which scenarios become specifications, that describe how a load test is to be executed in a declarative way rather, and not what to run. The specification can be created by using Rhino Load DSL which will be materialized by the framework. 

To enable reactive pipeline, you need to select [ReactiveHttpSimulationRunner](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/runners/ReactiveHttpSimulationRunner.html) runner in the simulation:

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

If [ReactiveHttpSimulationRunner](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/runners/ReactiveHttpSimulationRunner.html) is not selected explicitly by adding the Runner annotation, then the [DefaultSimulationRunner](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/runners/DefaultSimulationRunner.html) will be used in simulations which looks for scenario methods.  

### Writing your first DSL

Each DSL begins with `Start.dsl()` followed by runners. Runners are methods to run the spec instances defined in them. Runners can be chained together, they will then run by the same thread sequentially.

```
Start.dsl()
    .run(<some-spec>)
    .runIf(<some-spec>)
    .forEach(<some-spec>)...
``` 

Rhino provides two main specs to test web services, HttpSpec and SomeSpec. Furthermore, you can extend the Rhino spec framework by adding new specs which fit to your testing use cases. Let's first have a look at Specs which come out of box:

## Specs

Specs are instances describing the operation to be run by spec runners e.g [HttpSpec](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/dsl/specs/HttpSpec.html) specifies how a specific HTTP request would look like:

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

[HttpSpec](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/dsl/specs/HttpSpec.html) describes how Http request looks like which will be run by runners. The spec begins with `http(< measurement point >)` and followed by chained builder methods. Measurement point is the identifier and used in reporting. It is the measurement name under which the measurement is recorded.   

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

The runners accept [Spec](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/dsl/specs/Spec.html) instances like [HttpSpec](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/dsl/specs/HttpSpec.html) describing an HTTP request. Let's first have a look at runner methods:

### run(Spec)

Most times, you will work with this runner. The `run()` method basically runs a spec. It accepts `Spec` instances as parameter: 

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

### runIf(Predicate<UserSession> predicate, Spec spec)

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

In the DSL above, the second run will be executed, if the first run returns an HTTP 200. The predicate expects a parameter of UserSession. More about sessions, please refer to [Sessions](https://github.com/ryos-io/Rhino/wiki/Sessions).

### wait(Duration)

Wait runner holds the pipeline for the duration given:
```java
Start.dsl()
    .wait(Duration.ofSeconds(1))
``` 


### map(MapperBuilder<R, T> mapper)

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

### forEach(ForEachBuilder<E, R> forEachBuilder)

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

### runUntil(Predicate<UserSession>, Spec)

runUntil-runner runs a [Spec](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/dsl/specs/Spec.html) instance  until the prediction holds:
```java
  @Dsl(name = "Upload File")
  public LoadDsl singleTestDsl() {
    return Start
        .dsl()
        .runUntil(ifStatusCode(200),
            http("PUT Request")
                .header(c -> from(X_REQUEST_ID, "Rhino-" + uuidProvider.take()))
                .header(X_API_KEY, SimulationConfig.getApiKey())
                .auth()
                .upload(() -> file("classpath:///test.txt"))
                .endpoint((c) -> FILES_ENDPOINT)
                .put()
                .saveTo("result"))
        .run(http("GET on Files")
            .header(c -> from(X_REQUEST_ID, "Rhino-" + UUID.randomUUID().toString()))
            .header(X_API_KEY, SimulationConfig.getApiKey())
            .auth()
            .endpoint(FILES_ENDPOINT)
            .get()
            .saveTo("result2"));
  }

  private Predicate<UserSession> ifStatusCode(int statusCode) {
    return s -> s.<Response>get("result").map(Response::getStatusCode).orElse(-1) == statusCode;
  }
```

### runAsLongAs(Predicate<UserSession>, Spec)

runAsLongAs-runner runs a [Spec](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/dsl/specs/Spec.html) instance  as long as the prediction holds:
```java
    @Dsl(name = "Upload File")
    public LoadDsl singleTestDsl() {
        return Start
            .dsl()
            .runAsLongAs(ifStatusCode(200),
                        http("PUT Request")
                        .header(c -> from(X_REQUEST_ID, "Rhino-" + uuidProvider.take()))
                        .header(X_API_KEY, SimulationConfig.getApiKey())
                        .auth()
                        .upload(() -> file("classpath:///test.txt"))
                        .endpoint((c) -> FILES_ENDPOINT)
                        .put()
                        .saveTo("result"));
    }

  private Predicate<UserSession> ifStatusCode(int statusCode) {
    return s -> s.<Response>get("result").map(Response::getStatusCode).orElse(-1) == statusCode;
  }
```

### repeat(Spec)

The runner repeats the execution of [Spec](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/dsl/specs/Spec.html) infinitely:
```java
  @Dsl(name = "Upload File")
  public LoadDsl singleTestDsl() {
    return Start
        .dsl()
        .repeat(http("GET on Files")
            .header(c -> from(X_REQUEST_ID, "Rhino-" + UUID.randomUUID().toString()))
            .header(X_API_KEY, SimulationConfig.getApiKey())
            .auth()
            .endpoint(FILES_ENDPOINT)
            .get()
            .saveTo("result"));
  }
```

### ensure(Predicate<UserSession>, String reason)

The runner ensures the output of preceding runner by predicate. If the ensure does not succeed, the simulation will be terminated immediately:

```java
  @Dsl(name = "Upload File")
  public LoadDsl singleTestDsl() {
    return Start
        .dsl()
        .run(http("GET on Files")
            .header(X_API_KEY, SimulationConfig.getApiKey())
            .auth()
            .endpoint(FILES_ENDPOINT)
            .get()
            .saveTo("result2"))
        .ensure((s) -> s.get("result").isPresent(), "No result object in session!");
  }
```
