---
title:  Gatling Integration
summary: "Generating Gatling simulation reports."
series: "ACME series"
weight: 4
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_integration_gatling.html
folder: mydoc
---


If you don't run the load tests in an distributed environment, starting Grafana and Influx DB docker containers on local machine might be cumbersome. In this case, it might be handy to generate simulation reports for local load testing purposes. The Rhino framework provides simulation logging feature to write simulation metrics into a flat file on the disk. To enable simulation logging you will use [@Logging](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/annotations/Logging.html) on the Simulation entity.

You can use as logging formatter [GatlingSimulationLogFormatter](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/reporting/GatlingSimulationLogFormatter.html) to generate Gatling simulation log files:

```java
@Simulation(name = "Reactive Upload Test")
@Logging(file = "/Users/bagdemir/load-testing/sim.log", formatter = GatlingSimulationLogFormatter.class)
public class UploadLoadSimulation {
}
```

Once the simulation completes, you can run gatling.sh with `-ro` option to generate reports:

```
$ ./bin/gatling.sh -ro /Users/bagdemir/load-testing
```

Gatling generates simulation report:

```
GATLING_HOME is set to /Users/bagdemir/Downloads/gatling
in a future release.
Parsing log file(s)...
Parsing log file(s) done
Generating reports...

================================================================================
---- Global Information --------------------------------------------------------
> request count                                     209920 (OK=0      KO=209920)
> min response time                                      0 (OK=-      KO=0     )
> max response time                                    634 (OK=-      KO=634   )
> mean response time                                     1 (OK=-      KO=1     )
> std deviation                                          4 (OK=-      KO=4     )
> response time 50th percentile                          1 (OK=-      KO=1     )
> response time 75th percentile                          1 (OK=-      KO=1     )
> response time 95th percentile                          3 (OK=-      KO=3     )
> response time 99th percentile                          5 (OK=-      KO=5     )
> mean requests/sec                                3498.667 (OK=-      KO=3498.667)
---- Response Time Distribution ------------------------------------------------
> t < 800 ms                                             0 (  0%)
> 800 ms < t < 1200 ms                                   0 (  0%)
> t > 1200 ms                                            0 (  0%)
> failed                                            209920 (100%)
---- Errors --------------------------------------------------------------------
>                                                                209920 (100,0%)
================================================================================

Reports generated in 7s.
Please open the following file: /Users/bagdemir/Downloads/gatling/test-run/index.html
```

And open up the **index.html** file `/Users/bagdemir/Downloads/gatling/test-run/index.html`:

<p align="center">
<img src="http://ryos.io/static/gatling_report.png"/>
</p>

Please beware of that simulation log file rotation is still an issue: https://github.com/ryos-io/Rhino/issues/11. So the log file will not be rotated unless you do employ another tool like logrotate. 