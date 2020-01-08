---
title:  User and Clients
series: "ACME series"
weight: 4
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_users.html
folder: mydoc
toc: false
---

Each Rhino Simulation is run by a single user (primary user) which is the consumer of the API, so every simulation needs users and user sources to run. A user source provides with a list of users with some attributes like login credentials, in case of that they need to log in before they are able to make a request, region, etc. Depending on the type of the user source, users might be stored in a Database, Vault, or flat file which is distributed with the Docker container along with the load testing executable.



<p align="center">
<img src="images/uml_users.jpg" width="480"/>
</p>



Users are provided by user sources and managed by user repositories. User repositories controls the life cycle of users i.e they decide when a user is to be returned upon a request from Simulations. Every Simulation instance requires a user repository regardless of test scenarios that might not need any user to generate load. If you omit the user repository, the framework creates a default repository instance to generate pseudo users which make the load generation pipeline work.

The test users might be subject to authorization to perform operations provided by the web service, therefore the framework does provide developers with `OAuthUserRepository` implementation to log in users against an authorization server. In this case, user's access token is to be sent as `Bearer` token in Authorization header in load tests scenarios. To enable authorised users for your simulation, simulation entities must have `@UserRepostory` annotation and declare the `OAuthUserRepositoryFactory.class` factory for repository implementation:

```java
@UserRepository(factory = OAuthUserRepositoryFactory.class)
```

You can run load and performance tests without users though. In this case, you just need to omit 
`@UserRepostory` annotation. Testing without users is handy if you want to generate loads for API endpoints like healthcheck which does not require any authentication.  In this case, the framework will generate dummy users to make the pipeline work. 

## Enable Users in Simulations

If you are testing web services, the workflows implemented in the service are triggered by users or other client services, that are authorised to do so. In an enterprise services landscape, OAuth is a broadly used framework to authorise users and clients which want to perform some actions on server resources. Rhino load testing framework is capable to manage load testing users, and make them logged in against an authorization server under the hood. OAuth users are stored managed in user repository from which the framework queries so many users as configured in `@Simulation` annotation:

```java
@Simulation(name = "Reactive Test", maxNumberOfUsers=10, userRegion="US") ❶
@UserRepository(factory = BasicUserRepositoryFactoryImpl.class) ❷
public class ReactiveBasicHttpGetSimulation {

  private static final String FILES_ENDPOINT = getEndpoint("files");
  private static final String X_REQUEST_ID = "X-Request-Id";
  private static final String X_API_KEY = "X-Api-Key";

  @Dsl(name = "Load DSL Request")
  public LoadDsl singleTestDsl() {
    return Start.dsl()
        .run(http("Files Request")
            .header(session -> from(X_REQUEST_ID, "Rhino-" + UUID.randomUUID().toString()))
            .header(X_API_KEY, SimulationConfig.getApiKey())
            .auth() ❸
            .endpoint(FILES_ENDPOINT)
            .get()
            .saveTo("result"));
  }
}
```

❶ [@Simulation](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/annotations/Simulation.html) annotation accepts **maxNumberOfUsers** attribute which defines how many users the simulation requires and **userRegion** that is the region of the primary user injected to the DSL (or carried in the user session throughout the load generation loop). 
❷ UserRepository annotation defines a factory attribute, that you can provide with a factory for user repositories. If the annotation is omitted, then the default factory implementation which creates a new instance of DefaultUserRepositoryImpl, generates pseudo users to get test run:

```java
@Simulation(name = "Sample-Simulation")
public class PerformanceTestingExample {
}
```

❸ auth() DSL in HttpSpec indicates that the primary user is required for the request, and by adding the auth() DSL, the user credentials will be transmitted to the server in HTTP headers. 

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

| Variable | Description                |
| -------- | -------------------------- |
| user     | Username                   |
| pass     | Password                   |
| scope    | OAuth scope of the user.   |
| region   | Region id e.g US, EU, etc. |

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

> **_WARNING:_** Do not use a header line in your CSV file


The file should contain the number of users required by the load test, that is set in `@UserFeeder` annotation in your simulations. 

The default user provider searches for CSV file in your project's classpath. You still need to configure the path in rhino.properties:

```properties
{env}.auth.userSource=classpath:///test_users.csv
```

## Working with multiple Users

In such test scenarios where multiple users are required, for instance, two users are collaborating with each other, you may want to add a second user into the Simulation by injecting a UserProvider:

```java
@Simulation(name = "Reactive Multi-User Test")
@UserRepository(factory = OAuthUserRepositoryFactoryImpl.class)
public class ReactiveMultiUserCollabSimulation {

  @UserProvider
  private OAuthUserProvider userProvider;

  @Dsl(name = "Upload and Get")
  public LoadDsl loadTestPutAndGetFile() {
    return Start.dsl()
        .forEach("get all files",
            in(global("uploads", "#this['PUT in Loop']")).doRun(file -> http("GET in Loop")
            .header(X_API_KEY, SimulationConfig.getApiKey())
            .auth(() -> userProvider.take())
            .endpoint(session -> FILES_ENDPOINT)
            .get()));
  }
}

```
In the HttpSpec in the DSL method, we use the userProvider to employ a second user and pass it to the HttpSpec's auth(). 
If cross-region tests are required, the user provider annotation takes a region filter attribute. It provides the users from that particular region given. Please note that, if there is no user exists from the region in user source, the provider's take() method will then return null. You might need to handle null values in this case. 


## Services as Test Clients

In web services environment, it is a common practice that the client services send a service token along with the user' access tokens to APIs which is being tested. In this case, one of the tokens is used in `Authorization` header as `Bearer` token whereas the second token is sent in a custom header to the backend, e.g `X-Service-Token`. Other option is to send the service token with Authorization header and to use a custom one for user's access token. The test developer can set the type of the **Bearer** which is sent in Authorization header with the configuration: `dev.oauth.bearer` whereas the `dev.oauth.headerName` defines the name of the non-bearer token. The following example demonstrates the service token being as bearer, whereas the `X-User-Token` is being used for the user token:

```
dev.oauth.service.authentication=true
dev.oauth.service.clientId=TestService
dev.oauth.service.clientSecret=123-secret
dev.oauth.service.grantType=authorization_code
dev.oauth.service.clientCode=eyJ4NXUiO12345=
dev.oauth.bearer=service
dev.oauth.headerName=X-User-Token
```

The first line enables the service-to-service authentication. The service will be authenticated with clientId, clientSecret, grantType and the clientCode against authorisation server. As of 1.6.0, the only accepted grant type value is the `authorization_code`. The service token will be sent as bearer while the user token is sent in `X-User-Token`.

> **_WARNING:_** As of 1.6.0, the only accepted grant type value for service-to-service authentication is the `authorization_code`

`dev.oauth.bearer` can take either `service` or `user` pre-defined values. The `service` string literal stands for service token as the `user` is for user token. To enable service-to-service authentication together with user token, use auth() directive on DSL:

```java
Start.dsl()
      .run(http("API Request")
        .header(session -> from(X_REQUEST_ID, "Rhino-" + UUID.randomUUID().toString()))
        .header(X_API_KEY, SimulationConfig.getApiKey())
        .auth()
        .endpoint(FILES_ENDPOINT)
        .get()
        .saveTo("result"))
```
