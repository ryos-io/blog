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

In reactive mode, the framework spawns as many thread as it is necessary. There is no 1:1 relation between a user and thread, instead the users will be created by producers as long as the consumers have capacity to consume them.  Otherwise, the pipeline is to be back pressured. 
