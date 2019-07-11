---
title:  Scenarios
summary: "Creating new load testing scenarios in simulations."
series: "ACME series"
weight: 4
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_scenarios.html
folder: mydoc
---

Scenarios are the methods which contain the load testing implementation. A simulation might contain multiple scenarios which are run in parallel. The scenario methods are to be annotated with `@Scenario` annotation, that needs a name as attribute. The name will be then used in measurements and reporting respectively.  

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

In this example the scenario method is supposed to make a get request on target with request header defined. You can use arbitrary code snippet in scenario methods. 