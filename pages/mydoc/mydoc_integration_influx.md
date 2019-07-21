---
title:  Influx DB Integration
summary: "How to write Simulation metrics into Influx DB?"
series: "ACME series"
weight: 4
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_integration_influx.html
folder: mydoc
---

Rhino can send simulation metrics to Influx DB instance over Influx DB API. To enable Influx DB integration, you can use `@InfluxDB` annotation on simulation entity:

```java
@Simulation(name = "Server-Status Simulation Without User")
@Influx
public class BlockingLoadTestWithoutUserSimulation {
}
```

To configure the Influx DB integration in properties file:
```
db.influx.url=http://localhost:8086
db.influx.dbName=rhino
db.influx.username=
db.influx.password=
```

The metrics will be send in batches to Influx DB. 