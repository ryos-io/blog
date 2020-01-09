---
title:  Simulation Configurations
series: "ACME series"
weight: 4
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_configuration.html
folder: mydoc
toc: false
---

The Rhino projects require `rhino.properties` test configuration file which contain configuration properties and must be located in load testing project's classpath or in the file system. The configuration file's path will be passed to the factory method while creating a new Simulation instance:

```java
public static void main(String... args) {
  Simulation.create("classpath:///rhino.properties", SIM_NAME).start();
}
```

An example simulation configuration might look as follows:


```properties
packageToScan=io.ryos.rhino.sdk

# User Authentication
dev.auth.endpoint=https://auth-endpoint/token
dev.auth.clientId=YourClientId
dev.auth.clientSecret=123-abc
dev.auth.apiKey=YourAPIKey
dev.auth.grantType=password
dev.auth.userSource=classpath:///test_users.csv

# Influx DB Integration
db.influx.url=http://localhost:8086
db.influx.dbName=rhino
db.influx.username=
db.influx.password=

# Grafana Integration
grafana.endpoint=http://localhost:3000
grafana.token="<token with write access obtained from Grafana>"

```
Please keep in mind that some properties are environment aware, e.g "auth.*" and are bound to environments. So, they must be prefixed by environment labels: **dev**, **stage** or **prod** are valid values (as of 1.8.0).

In addition to the configurations in properties file, there are also configuration options that are available in SDK annotations. Let us take a closer look at these options:

### Simulation Configuration

|  Property | Description |
|---|---|
| **packageToScan** | Package name where annotated simulation entities are to be located. Wildcards not supported. The simulation scan is not recursive.  | Config Property |
| **name** | Name of the Simulation used in reporting.  | @Simulation |
| **userRegion** | User region. | @Simulation |
| **maxNumberOfUsers** | Max. number of different users, employed in simulation. Your data source might contain more users than the number defined by maxNumberOfUsers. If it has less than maxNumberOfUsers, then all users will be used. | @Simulation |
| **durationInMins** | Simulation duration in minutes.  | @Simulation |

### OAuth Configuration

If your environment relies on OAuth framework, you can leverage Rhino's OAuth support to enable OAuth authorization and authentication:

|  Property | Description |
|---|---|
| **{env}.users.source** | `file` or `vault`are valid values. `file` enables CSV based user source. Vault support is in Beta. | Config Property |
| **{env}.auth.endpoint**  | Authorization server endpoint. | Config Property |
| **{env}.auth.clientId** |  Client id for user login. | Config Property |
| **{env}.auth.clientSecret** | Client secret for user login.  | Config Property |
| **{env}.auth.apiKey** |  Api key, if the service behind the Gateway.  | Config Property |
| **{env}.auth.grantType** | Grant type. | Config Property |
| **{env}.auth.userSource** |  Path to user source e.g classpath:///test_users.csv  | Config Property |

If the testing endpoint require a service token, you can enable service authorization support in configuration properties.
For detailed information to service-to-service authentication please refer to [S2S Authentication](https://github.com/ryos-io/Rhino/wiki/Service-to-Service-Authentication) section.

|  Property | Description |
|---|---|
| **{env}.oauth.service.authentication** | **true** or **false** to enable service token authentication. If enabled, client service will be logged in and the service token will be sent to the resource server. | Config Property |
| **{env}.oauth.service.clientId** | Client id of the service. | Config Property |
| **{env}.oauth.service.clientSecret** | Client secret to log in the client against authorization server. | Config Property |
| **{env}.oauth.service.grantType** | grant type, "authorization_code" is the only supported grant type as of 1.7.1 | Config Property |
| **{env}.oauth.service.clientCode** | Client code to log in the client against authorization server. | Config Property |
| **{env}.oauth.bearer** | Bearer token type, "user" for user token or "service" for service token. | Config Property |
| **{env}.oauth.headerName** | The name of the custom header e.g X-User-Token if bearer is used for service token. | Config Property |

### Influx DB Configuration

|  Property | Description |
|---|---|
| **db.influx.url** |  Influx DB endpoint. | Config Property |
| **db.influx.dbName** | Database name. | Config Property |
| **db.influx.username** | Influx DB username. | Config Property |
| **db.influx.password** |  Influx DB Password. | Config Property |
| **db.influx.batch.actions** | The number of metrics sent in batches.  | Config Property |
| **db.influx.batch.duration** | Wait time till the batch will be sent regardless of the size of it. | Config Property |
| **db.influx.policy** |  [Retention policy](https://docs.influxdata.com/influxdb/v1.7/concepts/glossary/#retention-policy-rp) found in Influx DB. |  Config Property |

In addition to the configurations above, the Influx DB support must be enabled by adding @Influx annotation to the Simulation at class-level.

### Grafana Configuration

|  Property | Description |
|---|---|
| **grafana.endpoint** | Grafana endpoint, e.g http://localhost:3000 . | Config Property |
| **grafana.token** | Grafana access token. | Config Property |

In addition to the configurations above, the Grafana support must be enabled by adding @Grafana annotation to the Simulation at class-level.

### Http Client Configurations (from 1.6.0) 

|  Property | Description |
|---|---|
| **http.maxConnections** | Number of connections the HTTP client can handle in reactive mode. | Config Property |
| **http.connectTimeout** | Return the maximum time in millisecond an the Http client can wait when connecting to a remote host. | Config Property |
| **http.readTimeout** | The maximum time in millisecond an Http client can stay idle. | Config Property |
| **http.handshakeTimeout** | Return the maximum time in millisecond an Http client waits until the client-service handshake is completed. | Config Property |
| **http.requestTimeout** | Return the maximum time in millisecond an Http client waits until the response is completed. | Config Property |

### Accessing Configurations in Simulations

The configurations can be access through [SimulationConfig](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/SimulationConfig.html) instance in Simulation instances which provides static getter methods. 