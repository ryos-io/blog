---
title:  Simulation Configurations
summary: "How to configure your simulations"
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

# Service Authentication
dev.oauth.service.authentication=true
dev.oauth.service.clientId=TestService
dev.oauth.service.clientSecret=123-secret
dev.oauth.service.grantType=authorization_code
dev.oauth.service.clientCode=eyJ4NXUiO12345=
dev.oauth.bearer=service
dev.oauth.headerName=X-User-Token

# Influx DB Integration
db.influx.url=http://localhost:8086
db.influx.dbName=rhino
db.influx.username=
db.influx.password=

# Grafana Integration
grafana.endpoint=http://localhost:3000
grafana.token="<token with write access obtained from Grafana."

```
Please keep in mind that some properties like "auth.*" are bound to environments. So, they must be prefixed by environment labels: **dev**, **stage** or **prod** are valid values (as of 1.8.0).

|  Property | Description |
|---|---|
| **packageToScan** | Package name where annotated simulation entities are to be located. Wildcards not supported. The simulation scan is not recursive.  |


### OAuth Configuration

|  Property | Description |
|---|---|
| **{env}.users.source** | file or vault. Vault support is in Beta. |
| **{env}.auth.endpoint**  | Authorization server endpoint. |
| **{env}.auth.clientId** |  Client id for user login. |
| **{env}.auth.clientSecret** | Client secret for user login.  |
| **{env}.auth.apiKey** |  Api key if the service behind the Gateway.  |
| **{env}.auth.grantType** | Grant type. |
| **{env}.auth.userSource** |  Path to user source. Core SDK currently supports only classpath CSV files e.g classpath:///test_users.csv  |

For service-to-service authentication please refer to [S2S Authentication](https://github.com/ryos-io/Rhino/wiki/Service-to-Service-Authentication) section.

|  Property | Description |
|---|---|
| **{env}.oauth.service.authentication** | **true** or **false** to enable service token authentication. |
| **{env}.oauth.service.clientId** | Client id. |
| **{env}.oauth.service.clientSecret** | Client secret to log in the client against authorization server. |
| **{env}.oauth.service.grantType** | grant type, "authorization_code" is the only supported grant type as of 1.7.1 |
| **{env}.oauth.service.clientCode** | Client code to log in the client against authorization server. |
| **{env}.oauth.bearer** | Bearer token type, "user" for user token or "service" for service token. |
| **{env}.oauth.headerName** | The name of the custom header e.g X-User-Token if bearer is used for service token. |

### Influx DB Configuration

|  Property | Description |
|---|---|
| **db.influx.url** |  Influx DB endpoint. |
| **db.influx.dbName** | Database name. |
| **db.influx.username** | Influx DB username. |
| **db.influx.password** |  Influx DB Password. |
| **db.influx.batch.actions** | The number of metrics sent in batches.  |
| **db.influx.batch.duration** | Wait time till the batch will be sent regardless of the size of it. |
| **db.influx.policy** |  [Retention policy](https://docs.influxdata.com/influxdb/v1.7/concepts/glossary/#retention-policy-rp) found in Influx DB. |

### Grafana Configuration

|  Property | Description |
|---|---|
| **grafana.endpoint** | Grafana endpoint, e.g http://localhost:3000 . |
| **grafana.token** | Grafana access token. |

### Parallelism in Scenario-mode 

|  Property | Description |
|---|---|
| **runner.parallelisim** | Number of threads in non-reactive mode that a client is allowed to spawn. |

### Http Client Configurations (from 1.6.0) 

|  Property | Description |
|---|---|
| **http.maxConnections** | Number of connections the HTTP client can handle in reactive mode. |
| **http.connectTimeout** | Return the maximum time in millisecond an the Http client can wait when connecting to a remote host. |
| **http.readTimeout** | The maximum time in millisecond an Http client can stay idle. |
| **http.handshakeTimeout** | Return the maximum time in millisecond an Http client waits until the client-service handshake is completed. |
| **http.requestTimeout** | Return the maximum time in millisecond an Http client waits until the response is completed. |

### Accessing Configurations in Simulations

The configurations can be access through [SimulationConfig](http://ryos.io/static/javadocs/io/ryos/rhino/sdk/SimulationConfig.html) instance in Simulation instances which provides static getter methods. 