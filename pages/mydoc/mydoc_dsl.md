---
title:  Load DSL
series: "ACME series"
weight: 4
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_dsl.html
folder: mydoc
toc: false
---


In contrast to blocking thread model in which threads will be created in Threadpools and run load tests, Rhino offers reactive-mode in which test methods become specifications, that describe how a load test is to be executed in a declarative way rather than implementing what to run. With reactive approach and the DSL, the test developers do not necessarily need to deal with concurrency or HTTP client configuration. The framework materializes the DSL into reactive components and takes care of thread and connection management.

Similar to Java's stream framework, the load DSLs will be defined as chained method calls. The DSL method returns a Load DSL instance:

```java
@Simulation(name = "Reactive Test", durationInMins = 5)
@UserRepository(factory = OAuthUserRepositoryFactory.class)
public class ReactiveBasicHttpGetSimulation {

  @UserProvider
  private OAuthUserProvider userProvider;

  @Dsl(name = "Discovery")
  public LoadDsl singleTestDsl() {
    return Start.dsl() ❶
        .run( ❷
            http("Discovery") ❸
            .header(c -> from(X_REQUEST_ID, "Rhino-" + userProvider.take()))
            .header(X_API_KEY, SimulationConfig.getApiKey())
            .auth()
            .endpoint(DISCOVERY_ENDPOINT)
            .get()
            .saveTo("result"));
  }
}

```

The specification can be created by using Rhino Load DSL which will be materialized by the framework.  DSL methods starts with DSL builder ❶ which is followed by runners, the methods run the Specs ❷. Runners accept load testing specifications like HttpSpec ❸ which will be materialized as reactive components in the load testing pipeline.

## Writing your first DSL

Every DSL begins with `Start.dsl()` builder, that is followed by runner methods. Runner methods are such that used to describe how to run spec instances which are passed to them as parameters. Runners can be chained together to build more complex DSL structures:

```java
Start.dsl()
    .run(/*<some-spec>*/)
    .runIf(/*<some-spec>*/)
    .forEach(/*<some-spec>*/); /* more runners */
```

Rhino provides two spec types to test web services, the HttpSpec, that is used to describe the HTTP calls against services, and the SomeSpec, that allows developers to execute arbitrary code snippets, Runners. Furthermore, you can extend the Rhino spec framework by adding custom specs which fit to your testing use cases. Before we take a deeper look at Runner methods, let us first start with Specs:

## Specs

Specs are instances describing the operation to be run by runners e.g [HttpSpec](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/dsl/specs/HttpSpec.html) specifies how a specific HTTP request would look like:

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

### SomeSpec

SomeSpec can be used to run arbitrary code in runners. SomeSpec is handy if you want to test something within the reactive pipeline, but you need to pay attention to that your code is not blocking so the pipeline does not get blocked. 

```java
@Dsl(name = "Random in memory file")
public LoadDsl testRandomFiles() {
  return Start.dsl()
      .run(some("test").as(s -> {
        return "OK";
      }));
  }
```

SomeSpec's `as()` DSL takes a lambda function which contains the code which is to be executed and returns a String object which describes the status of code execution, that will be used in reporting. 

## Runners  

Runners accept [Spec](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/dsl/specs/Spec.html) instances like [HttpSpec](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/dsl/specs/HttpSpec.html) describing an HTTP request and materialises them into reactive components. They define how to run Spec instances which are passed to them. Runners are used in chained method calls and they are run subsequently. Simple runners take only spec instances as parameters whereas more complex ones may take spec builders, that are helpers to build runner instances. Let us take a closer look at the runners, first:

### run

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

The runner above executes [HttpSpec](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/dsl/specs/HttpSpec.html) discovery and stores the result of the HTTP request in the session context with the key "result".

### runIf

The `runIf` is a conditional runner as the run() DSL runs the spec with a conditional. If the conditional meets, then the Spec which is passed to the runner will be executed right away, otherwise it will be omitted:

```java
return Start.dsl()
.run(http("Upload text.txt")
    .header(session -> from(X_REQUEST_ID, "Rhino-" + userProvider.take()))
    .header(X_API_KEY, SimulationConfig.getApiKey())
    .auth()
    .endpoint(session -> UPLOAD_TARGET)
    .upload(() -> file("classpath:///test.txt"))
    .put()
    .saveTo("result"))
.runIf(session -> 
    session.<Response>get("result").map(r -> r.getStatusCode() == 200).orElse(false),
        http("Read File")
        .header(session -> from(X_REQUEST_ID, "Rhino-" + userProvider.take()))
        .header(X_API_KEY, SimulationConfig.getApiKey())
        .auth()
        .endpoint(session -> UPLOAD_TARGET)
        .get());
```

In the DSL above, the second runner will then be executed, if the first runner returns an HTTP 200. The first parameter to the runner is a predicate, a lambda which expects a parameter of UserSession (more about sessions, please refer to [Sessions](https://github.com/ryos-io/Rhino/wiki/Sessions)). The predicate above reads the status code out of session and if the result is HTTP 200 OK, then the "Read File" spec will be run. 

### wait

Wait runner holds the pipeline for the duration given:
```java
Start.dsl().wait(Duration.ofSeconds(1))
```


### map

Map runner together with map builder is used to transform one runner's result into another object which might be used in the next runners. The builder expects a builder, first, to read the result object out of the session and then to map the result object into the new type:

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

In the example, we are mapping the HttpResponse object into Integer by calling getStatusCode()- method.

### forEach

forEach DSL is used to iterate over `Iterable<T>` instances, that are put in the user session by the preceding runners. Let us take a look at the following in example in which we first make an HTTP request of which response will be mapped into a list of URIs and then we output those with a SomeSpec instance:

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
    .forEach("test for each", in(session("files")).doRun(uri -> 
      some("output").as(outputSpec(uri))));
}

private Function<UserSession, String> outputSpec(Object uri) {
return session -> {
  System.out.println(uri);
  return "OK";
};
} 
```

forEach DSL takes a name parameter which is used in reporting, and a builder which is used to create the runner instance itself. The builder is created as follows:

```java
in(session("object's key")).doRun(obj -> spec());
```

Which translates into, look up an object with the key "object's key" in the session, and do run for each object the spec, passed in the lambda of doRun. The object in the sessions must be a java.lang.Iterable.

### runUntil

runUntil is a loop DSL which runs a [Spec](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/dsl/specs/Spec.html) instance until the prediction holds:
```java
@Dsl(name = "Upload File")
public LoadDsl singleTestDsl() {
return Start.dsl()
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
      .get().saveTo("result2"));
}

private Predicate<UserSession> ifStatusCode(int statusCode) {
  return session -> session.<Response> get("result")
    .map(Response::getStatusCode).orElse(-1) == statusCode;
}
```

### runAsLongAs

runAsLongAs-runner runs a [Spec](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/dsl/specs/Spec.html) instance  as long as the prediction holds:
```java
@Dsl(name = "Upload File")
public LoadDsl singleTestDsl() {
  return Start.dsl()
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

The first parameter to the DSL is the predicate which needs to hold 

### repeat

The runner repeats the execution of [Spec](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/dsl/specs/Spec.html) infinitely:
```java
@Dsl(name = "Upload File")
public LoadDsl singleTestDsl() {
  return Start.dsl()
      .repeat(http("GET on Files")
        .header(c -> from(X_REQUEST_ID, "Rhino-" + UUID.randomUUID().toString()))
        .header(X_API_KEY, SimulationConfig.getApiKey())
        .auth()
        .endpoint(FILES_ENDPOINT)
        .get()
        .saveTo("result"));
  }
```

### ensure

The runner ensures the output of preceding runner by predicate. If the ensure does not succeed, the simulation will be terminated immediately:

```java
@Dsl(name = "Upload File")
public LoadDsl singleTestDsl() {
  return Start.dsl()
      .run(http("GET on Files")
        .header(X_API_KEY, SimulationConfig.getApiKey())
        .auth()
        .endpoint(FILES_ENDPOINT)
        .get()
        .saveTo("result2"))
        .ensure(s -> s.get("result").isPresent(), "No result object in session!");
  }
```
