---
title:  Parallelization
summary: "How to control the parallelizaton level in Simulations."
series: "ACME series"
weight: 4
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_parallelization.html
folder: mydoc
---

In non-reactive mode, the number of threads can be configured in properties file:

```
runner.parallelisim=4
```

In reactive mode, however, the framework spawns as many thread as it is required depending on the current capacity that the HTTP client has. In this mode, there is no 1:1 relation between a user and thread, instead the users will be created by producers as long as the consumers, the sink is the HTTP client, have capacity to consume them.  Otherwise, the pipeline will be backpressured. 

The test developers should pay attention to resource limits that simulations are bound to. In non-reactive mode, blocking scenarios might have performance impact on simulations so the number of threads configuration is the knob to tweak, whereas in reactive mode, or in DSL approach, the max. number of connections:

```
reactive.maxConnections=1000
```

In reactive mode, the framework will get backpressured once there is no connection available in the pool. 
