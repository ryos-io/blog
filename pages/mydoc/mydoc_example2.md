---
title:  "Example: Multi-User collaboration"
series: "Examples"
weight: 4
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_example2.html
folder: mydoc
toc: false
---

In the following example, the simulation first uploads the files returned by getFiles() method with the primary user and then it uses a secondary user to download it by iterating over for each files in the session: 

```java
@Simulation(name = "Reactive Multi-User Test")
@UserRepository(factory = OAuthUserRepositoryFactoryImpl.class)
public class ReactiveMultiUserCollabSimulation {

  private static final String X_REQUEST_ID = "X-Request-Id";
  private static final String X_API_KEY = "X-Api-Key";
  private static final String FILES_ENDPOINT = getEndpoint("files");

  @UserProvider
  private OAuthUserProvider userProvider;

  static List<String> getFiles() {
    return ImmutableList.of("file1", "file2");
  }

  @Before
  public LoadDsl setUp() {
    return Start.dsl()
        .session("files", ReactiveMultiUserCollabSimulation::getFiles)
        .forEach("test for each", in(session("files")).doRun(file -> http("PUT in Loop")
            .header(X_API_KEY, SimulationConfig.getApiKey())
            .auth()
            .endpoint(session -> FILES_ENDPOINT + "/" + file)
            .upload(() -> file("classpath:///test.txt"))
            .put()).saveTo("uploads", Scope.SIMULATION));
  }

  @Dsl(name = "Get with userB")
  public LoadDsl loadTestPutAndGetFile() {
    return Start.dsl()
        .session("userB", () -> userProvider.take())
        .forEach("get all files",
            in(global("uploads", "#this['PUT in Loop']")).doRun(file -> http("GET in Loop")
            .header(X_API_KEY, SimulationConfig.getApiKey())
            .auth(session("userB"))
            .endpoint(session -> FILES_ENDPOINT)
            .get()));
  }
}
```

