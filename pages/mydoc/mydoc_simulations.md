---
title:  Simulations
series: "Rhnio Documentation"
weight: 4
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_simulations.html
folder: mydoc
toc: false
---

Simulations are annotated test entities which will be materialized into reactive components and run by the reactive pipeline to generate synthetic load depending on the implementation against an instance under test. So as to create a new simulation entity, create a plain Java object with [@Simulation](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/annotations/Simulation.html) annotation. The simulation class does nothing unless the test developer add **DSL** instances to it. A **Simulation** entity starts with [@Simulation](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/annotations/Simulation.html) annotation with a name attribute, that identifies the simulation in reporting. The name should be unique:

```java
@Simulation(name = "Reactive Monitor Test")
public class MonitorWaitSimulation {

  private static final String FILES_ENDPOINT = getEndpoint("files");
  private static final String MONITOR_ENDPOINT = getEndpoint("monitor");
  private static final String X_REQUEST_ID = "X-Request-Id";
  private static final String X_API_KEY = "X-Api-Key";

  @UserProvider(region = "US") ❶
  private OAuthUserProvider userProvider;

  @Provider(clazz = UUIDProvider.class) ❷
  private UUIDProvider uuidProvider;

  @Dsl(name = "Upload File") ❸ 
  public LoadDsl uploadAndWaitLoadTest() {
    return Start.dsl() 
        .run(http("Upload") ❹
            .header(session -> from(X_REQUEST_ID, "Rhino-" + uuidProvider.take()))
            .header(X_API_KEY, SimulationConfig.getApiKey())
            .auth()
            .upload(() -> file("classpath:///test.txt"))
            .endpoint(session -> FILES_ENDPOINT)
            .put()
            .saveTo("result"))❺
        .run(http("Monitor")
            .header(session -> from(X_REQUEST_ID, "Rhino-" + uuidProvider.take()))
            .header(X_API_KEY, SimulationConfig.getApiKey())
            .auth()
            .endpoint(session -> MONITOR_ENDPOINT)
            .get()
            .saveTo("result")
            .retryIf(response -> response.getStatusCode() != 200, 2)
            .cumulative());
  }
}
```

❶ Injects a UserProvider instance into the injection point. Simulation classes may contain provider injection points to inject built-in or custom providers. Providers are factory instances to create objects which are to be used in load test implementations like UUIDs ❷ created by UUIDProvider. ❸ DSL methods which are annotated with `@Dsl` annotation, will be materialised into reactive components, so you will not need to control the parallelization level since the reactive framework will take care about it for you. More about [Load DSL](https://github.com/ryos-io/Rhino/wiki/Reactive-Tests-and-Load-DSL).  ❹ DSL methods consist of chained method calls to create LoadDSL instances. The first call `Start.dsl()` returns a `Runnable`. Runnable interface provides with runner methods run load execution specs like Http request spec.  ❺ After a spec execution the result can be stored in the session context.

### Simulation life-cycle

The framework streams [UserSession](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/data/UserSession.html) instances as tokens through the load generation loop. It creates a new [UserSession](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/data/UserSession.html) for each user and let them loop through the load generation cycle. Load generation cycle consists of materialized reactive components through which the [UserSession](https://github.com/ryos-io/Rhino/wiki/Sessions) flow. Once all reactive components are run in the load generation cycle, the framework starts from the beginning with a clean user session. 

User sessions are contextual objects which can be used to store data to share between reactive components. After a load generation loop completes, the user session will be discarded and for the next cycle a new session instance will be created. 

<p align="center">
  <img src="http://ryos.io/static/load_loop.jpg" />
</p>

The preparation and clean-up steps will run for each user before a simulation starts and after it completes. These steps are handy if you want to set up simulations by creating new resources and clean up the allocated resources after the simulation completes.

Please note that, if your simulation does not require any users, the framework creates synthetic users under the hood anyway to make the load generation loop run. Users, and user session instances respectively, are used as tokens.


### Preparing and Cleaning up with @Before/@After

You can take advantage of adding an initialisation step by providing a set-up method which is annotated with `@Before` annotation and it is run before every Simulation. It is handy to have a method with `@Before` to allocate resources you need in your simulation. Like `@Before` the framework does provide an `@After` annotation which is used to clean-up resources allocated during the simulation. `@After` method is run after Simulation completes. `@Before`/`@After` methods like DSL methods return a Load DSL instance:

```java
@Before ❶
public LoadDsl setUp() { ❷
  return Start.dsl()
    .run(http("Prepare by PUT text.txt") ❸
      .header(session -> from(X_REQUEST_ID, "Rhino-" + userProvider.take()))
      .header(X_API_KEY, SimulationConfig.getApiKey())
      .auth()
      .endpoint(session -> FILES_ENDPOINT)
      .upload(() -> file("classpath:///test.txt"))
      .put().saveTo("Prepare by PUT text.txt", Scope.SIMULATION)) ❹
    .session("files", ReactiveMultiUserCollabSimulation::getFiles) 
    .forEach("test for each", in(session("files")) ❺
    .doRun(file -> http("PUT in Loop") 
      .header(X_API_KEY, SimulationConfig.getApiKey())
      .auth()
      .endpoint(session -> FILES_ENDPOINT + "/" + file)
      .upload(() -> file("classpath:///test.txt"))
      .put()).saveTo("uploads", Scope.SIMULATION));
}
```

Let us have a look at the example above. ❶ The preparation method starts with `@Before` annotation. You can call the method what you want. The `@Before` method must return ❷ a LoadDsl instance which is created by chained DSL calls starting with ❸. The output of HTTP specs can be stored in sessions  ❹ and they can be accessed in following HTTP calls by access the objects with their session keys ❺. 