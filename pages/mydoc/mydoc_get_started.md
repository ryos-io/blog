---
title:  Getting Started
summary: "How to create a new project with Rhino."
series: "Rhnio Documentation"
weight: 4
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_get_started.html
folder: mydoc
toc: false
---

The goal of this document is provide a comprehensive guide for test developers who want to write load and performance tests by using Rhino testing framework.

### Prerequisites


Before you get started:

* Rhino framework is compiled with JDK 11. So, the dependencies attached to your project must be compatible with JDK 11. 

* Rhino projects are built as Docker containers, so you will need Docker installed on your computer to be able to test your simulations.

### What is Rhino ?

Rhino Load and Performance Testing Framework is a sub-project of the Rhino umbrella project and an SDK which 
enables developers to write load and performance tests in JUnit style. With annotation 
based development model, the load test developers can provide the framework with metadata required for running tests. The Rhino is developed under Apache 2.0. 


### Creating your first project

You can create Rhino projects by using Rhino Archetype. The Maven Archetype project allows 
developers to create new Rhino performance testing projects from the scratch:

```bash
$ mvn archetype:generate \
  -DarchetypeGroupId=io.ryos.rhino \
  -DarchetypeArtifactId=rhino-archetype \
  -DarchetypeVersion=1.8.2 \
  -DgroupId=com.acme \
  -DartifactId=my-foo-load-tests
```

For the groupId, you need to set your project's groupId, that is specific to your project and organization e.g `com.yourcompany.testing` and the 
artifactId is some artifact id used to identify your project e.g `my-test-project`. 
After entering the mvn command above, the project will be created by Maven which can be imported into IDE. 

You may choose to create a Rhino project without using the Rhino archetype. In this case, you can add the Rhino core dependency into your Maven project:

```xml
<dependency>
  <groupId>io.ryos.rhino</groupId>
  <artifactId>rhino-core</artifactId>
  <version>1.8.2</version>
</dependency>
```

[rhino-hello-world](https://github.com/ryos-io/Rhino/tree/master/rhino-hello-world) located in the project's root, might be a good starting point if you want to play around. 

### Writing your first Simulation with Scenarios

Rhino projects do consist of a main-method to run simulations and simulation 
entities which are annotated with Rhino annotations. An example application might look as follows: 

```java
import io.ryos.rhino.sdk.Simulation;

public class Rhino {

    private static final String PROPS = "classpath:///rhino.properties";
    private static final String SIM_NAME = "Server-Status Simulation";

    public static void main(String ... args) {
        Simulation.create(PROPS, SIM_NAME).start();
    }
}
```

`Simulation` is the load testing controller instance which requires a configuration file in the classpath ( therefore `classpath://<absolute path to configuration file>` prefix is important) and the name of the simulation to be run. You can also put the properties file outside of the classpath in the file system: "file///home/user/rhino.properties"


The name of the simulation must match the name, set in Simulation annotation:

```java
@Simulation(name = "Server-Status Simulation")
public class RhinoEntity {

  private static final String TARGET = "http://localhost:8089/api/status";
  private static final String X_REQUEST_ID = "X-Request-Id";
  
  private Client client = ClientBuilder.newClient();

  @Provider(factory = UUIDProvider.class)
  private UUIDProvider uuidProvider;

  @Scenario(name = "Health")
  public void performHealth(Measurement measurement) {
    var response = client
            .target(TARGET)
            .request()
            .header(X_REQUEST_ID, "Rhino-" + uuidProvider.take())
            .get();

    measurement.measure("Health API Call", String.valueOf(response.getStatus()));
  }
}
```

alternatively you may choose the reactive style and implements a [Load DSL](http://ryos.io/mydoc_dsl.html):

```java
@Simulation(name = "Reactive Sleep Test")
@Runner(clazz = ReactiveHttpSimulationRunner.class)
public class ReactiveSleepTestSimulation {

  @Dsl(name = "Health")
  public LoadDsl performHealth() {
    return Start
        .dsl()
        .run(http("Health API Call")
            .header(c -> from(X_REQUEST_ID, "Rhino-" + UUID.randomUUID().toString()))
            .endpoint(TARGET)
            .get()
            .saveTo("result"));
  }
}
```

The properties file does contain application configuration like, in which package the framework should search for Simulation entities. A simple **rhino.properties** might look as follows:

```properties
# Where to find simulations
packageToScan=io.ryos.rhino.sdk.simulations

# Number of threads will be used to run scenarios.
runner.parallelisim=1

# Http client configurations
http.maxConnections=10
http.readTimeout=15000

# node name
node=docker-dev
```

Please refer to [Configuration](http://ryos.io/mydoc_configuration.html) for detailed list of available configuration options. 

Once the your simulation entity is created, you can run the simulation by running the main() - method.

### What is next?

* [Simulations](https://ryos.io/mydoc_simulations.html) - The annotated load testing entities.
* [Providers](https://ryos.io/mydoc_providers.html) - Data feeders used at injection points in Simulations.
* [Configuration](https://ryos.io/mydoc_configuration.html) - Configure your load testing project.
* [Test Users in Simulations](https://ryos.io/mydoc_users.html) - Users in Simulations.
* [Service Tokens and Service-to-Service Authentication](https://ryos.io/mydoc_s2s.html) - How to enable S2S authentication (OAuth 2.0)
* [Reporting](https://ryos.io/mydoc_reporting.html) - Reporting the load metrics.
* [Measurements](https://ryos.io/mydoc_measurements.html) - Record measurement. 

### Integrations
* [Influx DB Integration](https://ryos.io/mydoc_integration_influx.html) - Push the metrics into Influx DB. 
* [Grafana Integration](http://ryos.io/mydoc_integration_grafana.html) - Show the metrics on Grafana. 
* [Gatling Integration](https://ryos.io/mydoc_integration_gatling.html) - To create Gatling simulation reports.