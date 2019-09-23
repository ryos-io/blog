---
title:  Simulations
summary: "A Brief Introduction to Rhino Simulations"
series: "Rhnio Documentation"
weight: 4
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_simulations.html
folder: mydoc
toc: false
---

Simulations are annotated test entities which will be executed by test runners and generate synthetic load depending on their 
implementation (or specification, if Load DSL is used) against an instance under test e.g a web service. 
So as to create a new simulation entity, create a plain Java object with [@Simulation](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/annotations/Simulation.html) annotation: 

```java
@Simulation(name = "Example Simulation")
public class PerformanceTestingExample {
}
```

The simulation above does nothing unless test developer add some *Scenarios* or *DSLs* into it. A scenario is a method annotated with [@Scenario](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/annotations/Scenario.html) annotation and contains the actual load generator implementation whereas a DSL is the definition of a test i.e describing how to run tests. Scenario methods is run by the framework threads sequentially. Number of threads in scenario mode can be configured in framework's configuration file: 

```properties
# Number of threads will be employed to run scenarios.
runner.parallelisim=10
```

A **Simulation** entity starts with [@Simulation](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/annotations/Simulation.html) annotation with a name attribute, that indicates which test to run, and at the same time identifies the simulation in reporting. The name must be unique. The [@Simulation](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/annotations/Simulation.html) annotation is followed by [@UserRepository](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/annotations/UserRepository.html):

```java
@Simulation(name = "Server-Status Simulation")
@UserRepository(factory = OAuthUserRepositoryFactory.class)
public class RhinoEntity {

  private final Client client = ClientBuilder.newClient();

  @Scenario(name = "Health")
  public void performHealth(Measurement measurement, UserSession userSession) {
    var simUser = (OAuthUser) userSession.getUser();
    var response = client
            .target(TARGET)
            .request()
            .header(AUTHORIZATION, "Bearer " + simUser.getToken())
            .get();

    measurement.measure("Health API Call", String.valueOf(response.getStatus()));
  }
}
```

The name of the simulation is important. In a performance and load testing project, probably 
you would create multiple simulations so Rhino does need to know once it starts which simulation is to be run by the simulation name provided, so they must be unique. 

If you prefer to use DSLs, then the DSL methods which are annotated with `@Dsl` annotation, will be materialised into reactive components, so you will not need to control the parallelization level since the reactive framework will take care about it for you:

```java
  @Dsl(name = "Upload File")
  public LoadDsl singleTestDsl() {
  }
```
More about [Load DSL](https://github.com/ryos-io/Rhino/wiki/Reactive-Tests-and-Load-DSL).

### Users in Simulations

The framework streams [UserSession](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/data/UserSession.html) instances as tokens through the load generation loop. It creates a new [UserSession](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/data/UserSession.html) for each user and let them loop through the load generation cycle. Load generation cycle consists of user created scenarios which are executed with the [UserSession](https://github.com/ryos-io/Rhino/wiki/Sessions). Once all scenarios are executed in the load generation cycle, the framework starts from the beginning with a new user session. 

User sessions are also contextual object which can be used to store data to share among scenarios. After a loop completes, the user session will be discarded and for the next loop a fresh instance will be created. 

<p align="center">
  <img src="http://ryos.io/static/load_loop.jpg" />
</p>

The prepare and clean-up steps will be run for each user right before the simulation starts, and after the simulation completes. Prepare and clean-up steps are handy if you want to set up simulations and clean up resources after the simulation.

Your test scenarios might not require any users, in this case the framework creates synthetic users under the hood to make the load generation loop run. 

### Scenarios vs. DSL

> **_NOTE_**: The Scenario-mode is the default one unless you explicitly set the reactive runner `ReactiveHttpSimulationRunner`. In order to use the DSL mode, you need to add the `@Runner` annotation with the runner instance `ReactiveHttpSimulationRunner` to your Simulation class. 

Scenarios are default load testing instances in Rhino load testing framework. In addition to Scenarios, load tests can be written in terms of a domain-specific language which is Load DSL.  DSLs describe how the load will be generated against an instance under test. DSL methods are annotated with `@Dsl` whereas the scenarios with `@Scenario` annotation. The main difference is that the DSL methods are called just once to evaluate the DSL described in the method, the framework will then materialize the DSL into reactive components. However, `@Scenario` methods will be run every time the framework needs to generate load. 

```java
  @Scenario(name = "Foo")
  public void runFooTest(Measurement measurement, UserSession userSession) {
   /*
    your code generating load.
    */
    measurement.measure("My API Call", "200");
  }
```

A scenario method is structured in two parts, load generating lines and a measurement line, so that the scenario is able to report how long the load generating part took. If you want not to report, so you can omit the measurement part. 

A DSL method looks a bit different: 

```java
  @Dsl(name = "Upload File")
  public LoadDsl singleTestDsl() {
    return Start
        .dsl()
        .run(http("Upload")
            .header(c -> from(X_REQUEST_ID, "Rhino-" + uuidProvider.take()))
            .header(X_API_KEY, SimulationConfig.getApiKey())
            .auth()
            .upload(() -> file("classpath:///test.txt"))
            .endpoint((c) -> FILES_ENDPOINT)
            .put()
            .saveTo("result"))
        .run(http("Monitor")
            .header(c -> from(X_REQUEST_ID, "Rhino-" + uuidProvider.take()))
            .header(X_API_KEY, SimulationConfig.getApiKey())
            .auth()
            .endpoint((c) -> MONITOR_ENDPOINT)
            .get()
            .saveTo("result")
            .retryIf((httpResponse) -> httpResponse.getStatusCode() != 200, 2));
  }
```

The method returns a [LoadDsl](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/dsl/LoadDsl.html) instance describing how load will be generated. To enable DSL mode you need to add the `@Runner` annotation with the runner instance `ReactiveHttpSimulationRunner`: 

```java
@Simulation(name = "Reactive Test", durationInMins = 1)
@Runner(clazz = ReactiveHttpSimulationRunner.class)
public class ReactiveBasicHttpGetSimulation {
    // your simulation implementation
}
```

If you omit the `Runner` annotation then the default mode is the Scenario-mode. 

> **_NOTE_**: The reactive runner and the Load DSL is still in Beta. Mehr information on [LoadDSL](https://github.com/ryos-io/Rhino/wiki/Reactive-Tests-and-Load-DSL).

### Preparing and Cleaning up

You can also add an initialisation step by providing a set-up method which is annotated with `@Before` annotation that is run before every scenario in every loop. It is handy to have a `@Before` method to allocate some resources, that your scenario might depend upon. Like `@Before` the Rhino framework also provides an `@After` annotation is used to clean-up resources. `@After` method is run after every scenario method. 

```java
  @Before
  public void setUp(UserSession session) {
    userSession.add("number", 1);
  }

  @Scenario(name="Increment")
  public void scenario(UserSession session) {
    var newNumber = userSession. <Integer> get("number").map(n -> n+1).orElse(0);
    userSession.add("number", newNumber);
  }

  @After
  public void tearDown(UserSession session) {
    userSession. <Integer> get("number").ifPresent(n -> System.out.println(n));
  }
```

You can also use [UserSession](https://github.com/ryos-io/Rhino/wiki/Sessions) object to pass information to the scenarios/or DSLs. In the example above, we use the before method to initialise an Integer-object which we increment in scenario and update the value in UserSession, and then we finally recall the value in after()-method.

In addition to `@Before` and `@After` the framework also provides `@Prepare` and `@CleanUp` static methods to prepare the simulation and clean up resources after simulation:

```java
  @Prepare
  public static void prepare(UserSession userSession) {
    var webTarget = client.target("http://localhost:8080/my-resource");
    var invocationBuilder = webTarget.request(MediaType.APPLICATION_JSON);
    Response response = invocationBuilder.post(Entity.entity(employee, MediaType.APPLICATION_JSON));
  }

  @CleanUp
  public static void cleanUp(UserSession userSession) {
    var webTarget = client.target("http://localhost:8080/my-resource");
    var invocationBuilder = webTarget.request(MediaType.APPLICATION_JSON);
    Response response = invocationBuilder.delete();
  }
```

with **DSL** :

```java
  @Prepare
  public static LoadDsl prepare(UserSession userSession) {
    return Start.dsl()
        .run(http("Create Resource")
            .header(c -> from(X_REQUEST_ID, "Rhino-" + UUID.randomUUID().toString()))
            .auth()
            .endpoint("http://myservice/foo.txt")
            .upload(() -> file("file:///home/me/foo.txt"))
            .put()
            .saveTo("result", Scope.SIMULATION));
  }

  @CleanUp
  public static LoadDsl cleanUp(UserSession userSession) {
    return Start.dsl()
        .run(http("Clean-up Resource")
            .header(c -> from(X_REQUEST_ID, "Rhino-" + UUID.randomUUID().toString()))
            .auth()
            .endpoint("http://myservice/foo.txt")
            .delete();
  }
```
 
Please pay attention to that the prepare and clean-up methods are static ones. They will be executed once in simulation and for every user. Therefore, the information added into [UserSession](https://github.com/ryos-io/Rhino/wiki/Sessions) can not be used in generation loop i.e in scenario method since after every load generation cycle the user session will be cleaned up. If you have data to be initialised in Prepare-method and to make it available during the simulation, you need to use the global session, that is [SimulationSession](https://github.com/ryos-io/Rhino/wiki/Sessions) which is available during the Simulation. 
