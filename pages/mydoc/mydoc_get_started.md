---
title:  Getting Started
series: "Rhnio Documentation"
weight: 4
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_get_started.html
folder: mydoc
toc: false
---

The goal of this document is to provide a comprehensive guide for test developers who want to write load and performance tests in Java by using Rhino Load and Performance Testing framework and to deploy them as Docker containers to the load testing environment. 

Rhino Load and Performance Testing Framework is Rhino's one of the sub-project and an SDK which enables developers to write load and performance tests in JUnit style. With the annotation-based development model, load test developers are expected to provide metadata to the framework which is required to define a load simulation. A simulation is an entity holding the information about the test, that is then materialized into a runnable load testing artifact in runtime. 

During load testing, Rhino collect load metrics and writes them into the stdout so you can follow the progress at the same time. In addition to that, with InfluxDB and Grafana support, you can store load metrics of runnings simulation in the time series database and monitor the running load testing session on Grafana, in real-time.

<p align="center">
<img src="https://ryos.io/static/integration.jpg" width="640"/>
</p>


### What you need, before you start


Before you get started, 

* Rhino framework is compiled with JDK 11. So, the dependencies attached to your project must be compatible with JDK 11+. 
* Rhino projects are built as Docker containers, so you will need Docker installed on your computer to be able to test your simulations.

### Upgrading from 1.x

Please note that there are some major changes beginning from the version 2.0 and if you want to upgrade to the newest version of Rhino, we strongly recommend evaluating your decision before you move on. The biggest change in the new versions is that the scenario mode is not supported anymore. If your load tests rely on scenarios, methods annotated with @Scenario, then you will need to translate the tests to the Load DSL. The reason why we discarded the scenarios is, because of the concurrency management. The scenario mode was implemented in classical blocking model and threads might get blocked instead of doing their jobs, namely generating load.  

Let's imagine a load testing scenario in which our load tests upload big files through the API. If you used scenarios prior to 2.0 and your load test framework is configured to have max. 100 threads, depending on the bandwidth and I/O performance, the threads will be busy with uploading 100 files at a certain point of time. But, in reactive mode the framework needs much less threads to achive a similar job and get the job done more efficently. Because, the reactive pipeline will take new chunks of bytes to upload as the capacity in the reactive pipeline allows so and if the pipeline reaches its limits, the consumers requesting data will signal the providers for on-hold till the capacity becomes available on the consumer side again. So, in reactive mode the number of threads will not define your limits and become the bottleneck and but the capacity of your service under test. It is what we want achive with load tests.

If you want to stick with scenario mode, you must use the Rhino 1.x in your projects. If you plan to write new load tests with Rhino, we highly recommend using the DSL from the reasons which we tried to explain, above. 

### What is Rhino ?

Rhino Load and Performance Testing Framework is a sub-project of the Rhino umbrella project and an SDK which enables developers to write load and performance tests in JUnit style. With annotation-based development model, the load test developers can provide the framework with metadata required for running tests. The Rhino is an open source project and it is developed under Apache 2.0. 


### Creating your first project

Rhino Load and Performance Testing projects are plain Maven projects with Rhino dependencies defined in the POM files. You can create a new project by creating a simple Maven project and add required dependencies manually into your POM file or more convenient way, is simply by running Rhino Maven archetype. The Maven Archetype allows developers to create a new project without building up one from the scratch:

```bash
$ mvn archetype:generate \
  -DarchetypeGroupId=io.ryos.rhino \
  -DarchetypeArtifactId=rhino-archetype \
  -DarchetypeVersion=2.0.0 \
  -DgroupId=com.acme \
  -DartifactId=my-foo-load-tests
```

In the example above, for the groupId you need to set your project's groupId which is an identifier specific to your Maven project and organization e.g `com.yourcompany.testing` and the artifactId is some artifact id used by your project to identify the artifact e.g `my-test-project`. After hitting the Maven command above in your terminal, the project will be created automatically which can be imported into your IDE. 

You may choose to create a Rhino project without using the Rhino archetype. In this case, it is required to add the Rhino core dependency into your Maven project, manually:

```xml
<dependency>
  <groupId>io.ryos.rhino</groupId>
  <artifactId>rhino-core</artifactId>
  <version>2.0.0</version>
</dependency>
```


Please note that [rhino-hello-world](https://github.com/ryos-io/Rhino/tree/master/rhino-hello-world) located in the project's root, might be a good starting point if you want to play around with the project. It includes a baseline set-up to build your custom simulation upon. 

### Writing your first Simulation

Rhino projects are plain Java applications and consist of a Java main()-method to run simulations and simulation entities which are annotated with Rhino annotations. An example application might look as follows: 

```java
import io.ryos.rhino.sdk.Simulation;

public class Rhino {

    private static final String PROPS= "classpath:///rhino.properties";❶ 

    public static void main(String ... args) { 
        Simulation.create(PROPS, MySimulation.class).start(); ❷
    }
}
```

❷ *Simulation* is the load testing controller which takes an absolute path to configuration file ❶ as parameter (in the example above, the properties file is in the classpath, therefore `classpath://<absolute path to configuration file>`) and the class type of the simulation which is to be run. Alternatively, you can put the properties file outside of the classpath e.g somewhere on your disk: "*file:///etc/init.d/rhino.properties*". The Java properties file contains application configuration, that is needed to run the load testing application. A minimal **rhino.properties** might look as follows:

```properties
# Where to find simulations
packageToScan=io.ryos.rhino.sdk.simulations

# Http client configurations
http.maxConnections=10
http.readTimeout=15000

# Node name
node=docker-dev
```

Please refer to [Configuration](https://github.com/bagdemir/rhino/wiki/Configuration) section for the complete list of available configuration options. 


Let us have a look at a Simulation example:

```java
@Simulation(name = "Server-Status Simulation") ❶
public class RhinoEntity {

  private static final String TARGET = "http://localhost:8089/api/status";
  private static final String X_REQUEST_ID = "X-Request-Id";

  private Client client = ClientBuilder.newClient();

  @Provider(factory = UUIDProvider.class)
  private UUIDProvider uuidProvider;

  @Dsl(name = "Health") ❷
  public LoadDsl performHealth() {
    return Start.dsl() ❸
        .run(http("Health API Call") ❹
            .header(c -> from(X_REQUEST_ID, "Rhino-" + UUID.randomUUID().toString()))
            .endpoint(TARGET)
            .get()
            .saveTo("result"));
  }
}
```

In the example above, ❶ we mark the simulation entity with `@Simulation` annotation with a unique name attribute. ❷ The simulation entity is a container for the DSL methods which are materialized and run by the Rhino runtime and annotated with @Dsl annotation. Every DSL method must have a unique name which is used in performance measurements and reporting e.g the DSL method above is called "Health" for healthcheck load test and must return a LoadDsl instance. ❸ To create a new Load DSL instance you use  chained method calls ❹ of *runners* e.g by calling run() method, which takes Spec instances as parameter. By using Specs you can define, for instance, how an HTTP request look like, that is made during the load testing session. 

### Creating a deployable artifact

A Docker container is the artifact you will get if you run the Maven package goal:

```shell
$ mvn -e clean install
```

After building the docker artifact, you can run the Docker artifact in CLI: 

```shell
$ docker run -it your-project:latest
```


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
* [Grafana Integration](https://ryos.io/mydoc_integration_grafana.html) - Show the metrics on Grafana. 
* [Gatling Integration](https://ryos.io/mydoc_integration_gatling.html) - To create Gatling simulation reports.