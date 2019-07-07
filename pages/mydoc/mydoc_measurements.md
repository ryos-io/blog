---
title:  Measurements
summary: "A Brief Introduction to Rhino Measurements"
series: "ACME series"
weight: 4
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_measurements.html
folder: mydoc
---

While simulation is running the test metrics can be collected by measurement instances. The metrics include the name of the measurement point, it is used in reporting and monitoring and the status of the execution, which is a string representation. Measurement instance will then store the time elapsed. Each load generator scenario gets a Measurement instance passed as an argument, so the metrics can be collected in the Measurement instances. The following example scenario measures the service response along with the step name:
 
```java
  @Scenario(name = "Health")
  public void performHealth(Measurement measurement) {
    var response = client
            .target(TARGET)
            .request()
            .header(X_REQUEST_ID, "Rhino-" + uuid)
            .get();

    measurement.measure("Health API Call", String.valueOf(response.getStatus()));
  } 
```

After the test run, the metrics collected will be used in reports and monitoring, if latter is enabled. 

As simulations might have multiple scenarios, a scenario might consist of multiple steps that are 
run sequentially whereas multiple scenarios are run in parallel (This behavior will change in 1.2.0 and scenarios will be run sequentially). After every load generative 
action/or step you may choose to record the metrics for that action. The values of the scenarios 
will be broken down in multiple charts on dashboards: 

```java
  @Scenario(name = "Health")
  public void performHealth(Measurement measurement) {
    var response = client
            .target(TARGET_HEALTH)
            .request()
            .header(X_REQUEST_ID, "Rhino-" + uuid)
            .get();

    measurement.measure("Health API Call", String.valueOf(response.getStatus()));

    var response = client
            .target(TARGET_VERSION)
            .request()
            .header(X_REQUEST_ID, "Rhino-" + uuid)
            .get();

    measurement.measure("Version API Call", String.valueOf(response.getStatus()));
  } 
````
