---
title:  Sessions
series: "Rhnio Documentation"
weight: 4
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_sessions.html
folder: mydoc
toc: false
---

Sessions are contextual objects to maintain state during load test execution and to share data between DSL components. Session objects are stored with a session key with which it can be accessed. There are two kinds of session objects for two different life-cycles:

## User Sessions

Rhino creates [UserSession](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/data/UserSession.html) instances as tokens which loop through the load generation pipeline and used to generate synthetic load on services. The framework creates a new UserSession for each user instance. It lets UserSession instances stream through the load generation loop to generate synthetic load. Load generation loop consists of user created DSL components which are part of reactive pipeline and the framework sends a new token as pipeline event, so the existing UserSession instance will be discarded after completion of load generation loop. 

```java
@Before
public LoadDsl setUp() {
  return Start.dsl()
      .run(http("Prepare by PUT text.txt")
          .header(session -> from(X_REQUEST_ID, "Rhino-" + userProvider.take()))
          .header(X_API_KEY, SimulationConfig.getApiKey())
          .auth()
          .endpoint(session -> FILES_ENDPOINT)
          .upload(() -> file("classpath:///test.txt"))
          .put().saveTo(Scope.SIMULATION)) ❶
      .session("files", ReactiveMultiUserCollabSimulation::getFiles) ❷
      .forEach("test for each", in(session("files")).doRun(file -> http("PUT in Loop")
          .header(X_API_KEY, SimulationConfig.getApiKey())
          .auth()
          .endpoint(session -> FILES_ENDPOINT + "/" + file)
          .upload(() -> file("classpath:///test.txt"))
          .put()).saveTo("uploads", Scope.SIMULATION));
}
```

A new session instance will be created every time a testing cycle is started. After all DSL components processed the user session instance in the reactive pipeline, the session object and its state, respectively, will be discarded. For the next turn, a newly created session instance will be created and passed through the reactive components. If you want to keep a state during the whole simulation execution, [simulation session](https://github.com/ryos-io/Rhino/wiki/Sessions#simulation-sessions) is the right place to retain the data throughout the simulation. 

User session instance contain also information about the user which can be accessed by calling getUser method:

```java
  userSession.getUser();
```

There are two ways to store data in session context. The first one is to tell the spec to store the result object into the session ❶ by calling the saveTo()-method. The method takes a scope argument which define in which context the result object needs to be stored. If you omit the scope, the default is the user session which will be reset after the loop generation cycle. The second way to store objects in session is to use the session DSL ❷. In the example, we store a list of files under "files" key and access the files in forEach DSL under the same key.

In the next sections, we will take a deeper look into simulation session and DSL items. 

## Simulation Sessions

Simulation session is just like user sessions a contextual object to store data during the simulation's lifetime. In contrast to the user sessions, the data stored in the simulation session is available throughout the simulation execution. There are a couple of ways to access the simulation session. If you have a reference to the user session, the simulation session is accessible through user session instances:

```java
    userSession.getSimulationSession()
```

Like user session, you can use DSL methods like saveTo() and session() to store and access objects in simulation sessions. Both methods have overloaded version which takes scope as parameter. The default scope is user session if you omit. For instance, in the previous code example, to tell your specs to store objects in the simulation session, we set the session scope to simulation session by passing the scope as parameter,  `saveTo("result", Scope.SIMULATION)` , explicitly. 

One way you can access objects in simulation session by using the handle of user sessions: 

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

Another way is to use builders which are provided by the framework and facilitate working with DSLs. In the following example, the forEach runner reads a list of objects from the global session context, that is simulation session and runs the spec for each item in the list:

```java
forEach("test for each", in(global("files")).doRun(/* spec to run */)
```

You may want to access the user session, then use session() builder method instead of global():

```java
forEach("test for each", in(session("files")).doRun(/* spec to run */)
```

> **_WARNING_** While calling `saveTo()` if there is no scope is defined the default one is the user session scope. 

Simulation session becomes handy if you plan to store objects which need to be stored throughout the simulation. For instance, you may want to initialize a resources hierarchy before the simulation execution in preparation step, that is to be accessed in the load testing scenario. 
