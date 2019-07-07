---
title:  Simulations
summary: "A Brief Introduction to Rhino Simulations"
series: "ACME series"
weight: 4
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_simulations.html
folder: mydoc
---

Simulations are annotated test entities which will be executed by test runners and generate load according to their 
implementation (or specification depending on which runner is selected) against an instance under test, iut, e.g a web service. 
So as to create a new simulation entity, create a plain Java object with `@Simulation` annotation: 

```java
@Simulation(name = "Example Simulation")
public class PerformanceTestingExample {
}
```

The simulation above does nothing unless test developer add some scenarios to it. A scenario is a method 
annotated with `@Scenario` and contains the actual implementation of load generator. A simulation 
might have multiple scenarios defined which are run during testing, independently and parallel (with the 1.2.0 this behavior is going to change):

```java
@Simulation(name = "Server-Status Simulation")
@UserRepository(factory = OAuthUserRepositoryFactory.class)
public class RhinoEntity {

  private static final String TARGET = "http://localhost:8089/api/status";
  private static final String X_REQUEST_ID = "X-Request-Id";
  private static final String AUTHORIZATION = "Authorization";

  private final Client client = ClientBuilder.newClient();

  @Provider(factory = UUIDProvider.class)
  private String uuid;

  @Before
  public void setUp(UserSession userSession) {
    var simUser = (OAuthUser) userSession.getUser();
    var response = client
            .target(TARGET)
            .request()
            .header(AUTHORIZATION, "Bearer " + simUser.getToken())
            .header(X_REQUEST_ID, "Rhino-" + uuid)
            .put();
  }


  @Scenario(name = "Health")
  public void performHealth(Measurement measurement, UserSession userSession) {
    var simUser = (OAuthUser) userSession.getUser();
    var response = client
            .target(TARGET)
            .request()
            .header(AUTHORIZATION, "Bearer " + simUser.getToken())
            .header(X_REQUEST_ID, "Rhino-" + uuid)
            .get();

    measurement.measure("Health API Call", String.valueOf(response.getStatus()));
  }

  @After
  public void cleanUp(UserSession userSession) {
    var simUser = (OAuthUser) userSession.getUser();
    var response = client
            .target(TARGET)
            .request()
            .header(AUTHORIZATION, "Bearer " + simUser.getToken())
            .header(X_REQUEST_ID, "Rhino-" + uuid)
            .delete();
  }
}
```

The name of the simulation is important. In a performance testing project, it is very likely that 
you will have multiple simulations. Rhino does know which simulation is to be run by the 
simulation name, so they must be unique. 

You can also add an initialisation step by providing a set-up method which is annotated with `@Before` annotation that is run before every single scenario. It is handy to have a `@Before` method to allocate some resources, that your scenario might depend upon. As `@Before`, Rhino also provides an `@After` annotation, to create clean-up method in which method the resources might be cleaned up. 