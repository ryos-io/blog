---
title:  Sessions
summary: "Working with contextual objects."
series: "Rhnio Documentation"
weight: 4
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_sessions.html
folder: mydoc
toc: false
---

Sessions are contextual objects to keep state during scenario and simulation executions. Sessions are used to share data between scenarios/or DSLs if ReactiveSimulationRunner is used. There are two implementations of sessions:

## User Sessions

The framework streams [User](http://ryos.io/javadocs/apidocs/io/ryos/rhino/sdk/users/data/User.html) instances as tokens through the load generation loop. It creates a token in the loop for each user and having the user representation itself, we call that token UserSession, and let the tokens loop through the load generation pipeline. Load generation loop consists of user defined scenarios which are executed with the UserSession. Once all scenarios are executed, the framework starts from the beginning with a fresh token. 

User sessions are also contextual object which can be used to store data to share among scenarios. After a loop completes, the user session will be discarded and for the next loop a fresh instance will be created. In non-reactive mode, a simulation might contain multiple scenarios in its scope. The scenario methods will then be executed sequentially by the framework while accepting the session instances as method arguments. This will give test developers the opportunity to add some object into the sessions context where the next scenarios are able to pick up from:

```java
  @Scenario(name = "Scenario 1")
  public void performScenario1(Measurement measurement, UserSession session) {
      session.add("variable", 1);
  }

  @Scenario(name = "Scenario 2")
  public void performScenario2(Measurement measurement, UserSession session) {
      session.get("variable").ifPresent(var -> out.println(var));
  }

```

A new session instance will be created every time a testing cycle is started. Once all scenarios executed, the session and its state will be discarded. For the next turn, a newly created sessions instances will be instantiated. If you want to keep a state during the whole simulation execution, simulation session is the right place to retain the data. 

Sessions contain also information about the user:

```java
  userSession.getUser();
```

## Simulation Sessions

Simulation sessions are contextual objects to store information during the simulation execution. The data stored in simulation session is available during the testing session. Simulation session is accessible through user session instances which are injected into scenario methods: 

```java
   userSession.getSimulationSession()
```

Simulation session is handy if you want to prepare the simulation with `@Prepare` methods. The prepare steps are executed exactly once for each user. It gives developers the opportunity to prepare user's test workflow, e.g upload a file into user's storage: 

```java
  @Prepare
  public static LoadDsl prepare() {
    return Start.dsl()
        .run(http("Prepare")
            .header(c -> from(X_REQUEST_ID, "Rhino-" + UUID.randomUUID().toString()))
            .header(X_API_KEY, SimulationConfig.getApiKey())
            .auth()
            .endpoint(FILES_ENDPOINT)
            .upload(() -> file("classpath:///image.png"))
            .put()
            .saveTo("result", Scope.SIMULATION));
  }
```

The prepare will be called for every user requested from the user repository. Once user workflows are initialized after `prepare` execution, the information which you might require in your tests, e.g the URI of the uploaded  file, can be stored into the Simulation context, by telling the spec in `saveTo("result", Scope.SIMULATION)` explicitly. 

In Load DSL you can access the Simulation session over user sessions: 

```java
  @Dsl(name = "Shop Benchmarks")
  public LoadDsl singleTestDsl() {
    return Start.dsl()
        .run(http("Files Request")
            .header(X_API_KEY, SimulationConfig.getApiKey())
            .header(session -> from(X_REQUEST_ID, "Rhino-" + UUID.randomUUID().toString()))
            .auth()
            .endpoint(session -> session.getSimulationSession().<HttpResponse> get("result")
                .map(r -> r.getResponse().getUri())
                .map(Uri::toString)
                .orElseThrow())
            .get()
            .saveTo("result"));
  }
```

The endpoint will take the value from the simulation session. 

> **_WARNING_** While calling `saveTo()` if there is no scope is defined the default one is the user scope. 
