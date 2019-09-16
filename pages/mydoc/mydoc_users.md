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

Each Rhino Simulation is run by a single user (primary user) which is the consumer of the API, so every simulation needs user sources to run. A user source provides with a list of users with some attributes like login credentials, in case of that they need to log in before they are able to make a request, region, etc. Depending on the type of the user source, users might be stored in a Database, Vault, or flat file which is distributed with the Docker container along with the load testing executable.

<p align="center">
<img src="http://ryos.io/static/uml_users.jpg" width="480"/>
</p>

Users are provided by user sources and managed by user repositories. User repositories controls the life cycle of users i.e they decide when a user is to be returned upon a request from Simulations. Every Simulation instance requires a user repository regardless of test scenarios that might not need any user to generate load. If you omit the user repository, the framework creates a default repository instance to generate pseudo users which make the load generation pipeline work.

The test users might be subject to authorization to perform operations provided by the web service, therefore the framework does 
provide developers with `OAuthUserRepository` implementation to log in users against an 
authorization server. In this case, user's access token is to be sent as 
`Bearer` token in Authorization header in load tests scenarios. To enable authorised users for your simulation, simulation entities must have `@UserRepostory` annotation and declare the `OAuthUserRepositoryFactory.class` factory for repository implementation:

```java
@UserRepository(factory = OAuthUserRepositoryFactory.class)
```

You can run load and performance tests without users though. In this case, you just need to omit 
`@UserRepostory` annotation. Testing without users is handy if you want to 
generate loads for API endpoints like healthcheck which does not require any authentication.  

### Enable Users in Simulations

If you are testing web services, the workflows implemented in the service are triggered by users or other client services, that are authorised to do so. In an enterprise services landscape, OAuth is a broadly used framework to authorise users and clients which want to perform some actions on server resources. Rhino load testing framework is capable to manage load testing users, and make them logged in against an authorization server under the hood. OAuth users are stored managed in user repository from which the framework queries so many users as configured 
in `@Simulation` annotation:

```java
@Simulation(name = "Sample-Simulation", maxNumberOfUsers=10)
@UserRepository(factory = OAuthUserRepositoryFactory.class)
public class PerformanceTestingExample {

}
```

[@Simulation](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/annotations/Simulation.html) annotation accepts **maxNumberOfUsers** attribute which defines how many users the simulation requires and **userRegion** that is the region of the primary user injected to the scenario-methods (or carried in the user session throughout the load generation loop). 

UserRepository annotation defines a factory attribute, that you can provide with a factory for user 
repositories. If the annotation is omitted, then the default factory implementation which creates a new instance of 
DefaultUserRepositoryImpl, generates pseudo users to get test run:

```java
@Simulation(name = "Sample-Simulation")
public class PerformanceTestingExample {
}
```

## User Sources

A user source is an instance e.g database, flat file, etc. where users can be loaded into user repositories where their life cycle will be managed. The type of user source and the location of it are configured in the properties file depending on the environment (dev, stage, prod):

```properties
stage.users.source=file
stage.auth.userSource=classpath:///test_users.csv

stage.users.source=file
prod.auth.userSource=files:///usr/local/myrhino/test_users.csv
```

**stage.users.source=file** indicates that the user source type is file based so the users can be located in the file set by **stage.auth.userSource**. 

### CSV files as User Source

CSV user source does contain a list of users with username, password, scope and region:

```
user;password;scope;region
```

| Variable  | Description  |
|---|---|
|  user | Username  |
|  pass |  Password |
|  scope | OAuth scope of the user.  |
|  region | Region id e.g US, EU, etc.  |

an example of user's csv file might look like as follows:
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
}

```

In addition to the users provided by the framework as method arguments in scenario methods and carried in user sessions, in multi-user tests scenarios you might want to have additional users. In this case, use can use the @UserProvider annotation and user provider injection: 

```java
  @UserProvider(region = "EU")
  private OAuthUserProvider userProviderEU;
```

The user provider accepts a region filter by its attribute in annotation. It provides then only the users from that region. Please note that, if there is no user exists from the region in user source, the provider's take() method will then return null.

> **_WARNING:_** Do not use a header line in your CSV file


The file should contain the number of users required by the load test, that is set in `@UserFeeder` annotation in your simulations. 

The default user provider searches for CSV file in your project's classpath. You still need to configure the path in rhino.properties:

```properties
{env}.auth.userSource=classpath:///test_users.csv
```