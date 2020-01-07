---
title:  "Example: Upload file"
summary: "How to write load tests for uploading files?"
series: "Examples"
weight: 4
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_example1.html
folder: mydoc
toc: false
---

In the following example, the simulation first uploads the file test.xml with the primary user and then uses a secondary user to download it: 

```java
@Simulation(name = "Upload file")
@UserRepository(factory = OAuthUserRepositoryFactoryImpl.class)
public class UploadLoadSimulation {

  private static final String FILES_ENDPOINT = getEndpoint("files");
  private static final String X_REQUEST_ID = "X-Request-Id";
  private static final String X_API_KEY = "X-Api-Key";

  @UserProvider
  private OAuthUserProvider userProvider;

  @Provider(clazz = UUIDProvider.class)
  private UUIDProvider uuidProvider;

  @Dsl(name = "Upload File")
  public LoadDsl testUploadAndGetFile() {
    return Start
        .dsl()
        .session("2. User", () -> userProvider.take())
        .run(http("PUT text.txt")
            .header(session -> from(X_REQUEST_ID, "Rhino-" + uuidProvider.take()))
            .header(X_API_KEY, SimulationConfig.getApiKey())
            .auth()
            .endpoint(session -> FILES_ENDPOINT)
            .upload(() -> file("classpath:///test.txt"))
            .put()
            .saveTo("result"))
        .run(http("GET text.txt")
            .header(session -> from(X_REQUEST_ID, "Rhino-" + uuidProvider.take()))
            .header(X_API_KEY, SimulationConfig.getApiKey())
            .auth((session("2. User")))
            .endpoint(session -> FILES_ENDPOINT)
            .get());
  }
}
```
