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

Scenarios are the methods which enclose the load testing implementation. A simulation might contain multiple scenarios which are run sequentially. The scenario methods are to be annotated with [@Scenario](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/annotations/Scenario.html) annotation in simulations which takes a name attribute. The name will be used in measurements and reporting, respectively, thus it is mandatory.  

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

In the example above, the scenario method will make a HTTP GET request on target with the request header defined. You can use arbitrary implementation in scenario methods. 

The scenario methods takes [Measurement](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/reporting/Measurement.html) and/or [UserSession](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/data/UserSession.html) instances as argument. Measurement object can be used to measure the execution time in scenarios. You can call measure on [Measurement](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/reporting/Measurement.html) multiple times to record multiple measurements. Please refer (here)[https://github.com/ryos-io/Rhino/wiki/Measurements] for more information on measurements. UserSession is a contextual object which contains information about the primary user. You can use user session to store data which will be valid during the session. Please refer [here](https://github.com/ryos-io/Rhino/wiki/Sessions) for more information on user sessions. 

The scenarios will be executed by threads leased from the threadpool underlying the framework of which number can be configured in configuration file. Please refer to [Parallelization](https://github.com/ryos-io/Rhino/wiki/Parallelization) section. 