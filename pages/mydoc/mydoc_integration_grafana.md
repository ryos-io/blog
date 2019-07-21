---
title:  Grafana Integration
summary: "How to control the parallelizaton level in Simulations."
series: "ACME series"
weight: 4
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_integration_grafana.html
folder: mydoc
---


> **_NOTE:_** Grafana Integration is available from 1.5.0

Before you configure the framework to integrate with Grafana, the Influx DB cluster must be configured as data source in Grafana, so that Grafana is able to visualise metrics from the Influx DB. On Grafana, follow the path `Configuration -> Data Source` the set up Influx DB as Data Source.

Rhino can be configured to set up your Grafana dashboards before the tests are executed to visualise the metrics stored in Influx DB. It uses the simulation's execution id that is to be unique for every execution with which the framework also create an Influx DB measurement, otherwise the metrics will be written into an existing measurement table. The simulation id can be set as environment variable - in a distributed environment, the environment variable is to be injected by container orchestration platform like Mesos, K8, etc. : 

```
export SIM_ID="123-abc"
```

To let the framework create dashboard, you need to add following configurations into rhino.properties:

```
grafana.endpoint=http://localhost:3000
grafana.token="<token with write access obtained from Grafana under Configuration -> API Keys >"
```

To enable Grafana integration for your simulation, `@Grafana` annotation is to be added to your simulation entity:

```java
@Simulation(name = "Reactive Test", durationInMins = 5)
@Grafana
public class RhinoEntity {
}
```

Once the test is started, the dashboard with the id, `$SIM_ID` will get created by the framework, if it does not exist, otherwise the dashboard will be re-used:

<p align="center">
  <img src="https://github.com/bagdemir/rhino/blob/master/rhino_grafana.png"  width="712"/>
</p>