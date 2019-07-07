---
title:  Test Users in Simulations
summary: "A Guide to Tests Users in Simulations"
series: "ACME series"
weight: 4
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_users.html
folder: mydoc
---

Each Rhino Simulation will be run by a single user which is the consumer of the API. The test users might be subject to authorization to perform operations provided by the web service, therefore the framework does 
provide developers with `OAuthUserRepository` implementation to log in users against an 
authorization server. In this case, the access token can be send as 
Bearer token in Authorization header in load tests scenarios. To enable users for your simulation, simulation entities must have `@UserRepostory` annotation and declare a factory for repository implementations:

```java
@UserRepository(factory = OAuthUserRepositoryFactory.class)
```

You can run load and performance tests without users though. In this case, you just need to omit 
`@UserRepostory` annotation. Testing without users is handy if you want to 
generate loads for API endpoints like healthcheck which does not require any authentication. 
However, the web services which take on the role as resource server require authenticated users to 
process the requests.

Every simulation is run by some user regardless of having a user repository. If the developer does not need users, the framework generates synthetic ones to be able to run the load test. 

### Users in Simulations

If you are testing web services, the workflows are triggered by users or other client services, that are authorized to do so. In an enterprise services landscape, the most common framework to authorize clients, is OAuth 2.0. Rhino load testing framework is capable to manage load testing users, and make them logged in against an authorization server under the hood. The OAuth users are 
stored in user repositories from which the framework asks for so many users as it is configured 
in `@Simulation` annotation:

```java
@Simulation(name = "Sample-Simulation", maxNumberOfUsers=10)
@UserRepository(factory = OAuthUserRepositoryFactory.class)
public class PerformanceTestingExample {

}
```

UserRepository annotation defines a factory attribute, that you can provide with a factory for user 
repositories. If it is omitted, then the default factory implementation, that creates a new instance of 
DefaultUserRepositoryImpl, generates dummy users for test run:

```java
@Simulation(name = "Sample-Simulation")
public class PerformanceTestingExample {
}
```

### Files as User Sources

The user sources are provided in the properties file depending on the environment (dev, stage, 
prod):

```properties
stage.auth.userSource=classpath:///test_users.csv
```

The classpath user source contains a list of users with username, password and scope:

```
user;password;scope;region
```

| Variable  | Description  |
|---|---|
|  user | Username  |
|  pass |  Password |
|  scope | Scope of the user.  |
|  region | US  |

an example of user's csv file:
```
testuser_us1@ryos.io;password123;openid;US
testuser_us2@ryos.io;password123;openid;US
testuser_us3@ryos.io;password123;openid;US
testuser_us4@ryos.io;password123;openid;US
testuser_us5@ryos.io;password123;openid;US
testuser_us6@ryos.io;password123;openid;US
testuser_eu1@ryos.io;password123;openid;EU
testuser_eu2@ryos.io;password123;openid;EU
testuser_eu3@ryos.io;password123;openid;EU

```

### Accessing Users in Tests

A user session is a context object shared by scenario instances within a simulation. The framework will then pass context between scenarios as sessions objects, so the scenario has access to the objects put into the context by a former scenario:

```java
@Simulation(name = "Server-Status Simulation")
@UserRepository(factory = OAuthUserRepositoryFactory.class)
public class BlockingJerseyClientLoadTestSimulation {

  @UserProvider(region = "EU")
  private OAuthUserProvider userProviderEU;

  @Provider(factory = UUIDProvider.class)
  private String uuid;

  @Prepare
  public void prepare() {
    System.out.println("Preparation in progress.");
  }

  @Before
  public void setUp(UserSession us) {
    System.out.println("Before the test with user:" + us.getUser().getUsername());
  }

  @Scenario(name = "Health")
  public void performHealth(Measurement measurement, UserSession userSession) {

    var client = ClientBuilder.newClient();
    final Response response = client
        .target("http://localhost:8089/api/files")
        .request()
        .header("X-Request-Id", "Rhino-" + uuid)
        .get();

    measurement.measure("Health API Call", String.valueOf(response.getStatus()));
  }

  @CleanUp
  public void cleanUp() {
    System.out.println("Clean-up in progress.");
  }

  @After
  public void after(UserSession us) {
    System.out.println("Clean up the test with user:" + us.getUser().getUsername());
  }
}

```

Except the users provided by the framework as method arguments in scenario methods, in multi-user tests scenarios you might want to have additional users. In this case, use can use the @UserProvider annotation and user provider injection: 

```java
  @UserProvider(region = "EU")
  private OAuthUserProvider userProviderEU;
```

The user provider accepts a region filter by its attribute in annotation. It provides then only the users from that region. Please note that, if there is no user exists from the region in user source, the provider's take() method will then return null.

### Please note that:

* Do not use a header line in your CSV file.
* The file should contain the number of users required by the load test. The number of test users is to be set in **@UserFeeder** annotation in your simulations. 

The default user provider searches for CSV file in your project's classpath. You still need to configure the path in rhino.properties:

```properties
{env}.auth.userSource=classpath:///test_users.csv
```