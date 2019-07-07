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


#### This reactive runner is in Beta

In addition to blocking approach in which the threads will be created in simulation's Threadpool and runs the test for a single users,  Rhino does offer reactive mode in which the Scenarios become Specifications which describe how a load test is to be executed in a declarative way, not what to run. The specification can be created by using the Rhino DSL which will be materialized by the framework. 

```java
@Simulation(name = "Reactive Test", durationInMins = 5)
@Runner(clazz = ReactiveHttpSimulationRunner.class)
@UserRepository(factory = OAuthUserRepositoryFactory.class)
@RampUp(startRps = 10, targetRps = 2000, duration = 1)
public class ReactiveBasicHttpGetSimulation {

  private static final String DISCOVERY_ENDPOINT = "http://localhost:8089/api/files";
  private static final String X_REQUEST_ID = "X-Request-Id";
  private static final String X_API_KEY = "X-Api-Key";

  @UserProvider
  private OAuthUserProvider userProvider;

  @Dsl(name = "Discovery")
  public LoadDsl singleTestDsl() {
    return Start.spec()
        .run(http("Discovery")
            .header(c -> from(X_REQUEST_ID, "Rhino-" + userProvider.take()))
            .header(X_API_KEY, SimulationConfig.getApiKey())
            .auth()
            .endpoint(DISCOVERY_ENDPOINT)
            .get()
            .saveTo("result"))
        .run(some("Output").as((u,m) -> {
          u.<Response>get("result").ifPresent(r -> System.out.println(r.getStatusCode()));
          return u;
        }));
  }

  @Prepare
  public void prepare() {
    System.out.println("Preparation in progress.");
  }

  @CleanUp
  public void cleanUp() {
    System.out.println("Clean-up in progress.");
  }
}

```
