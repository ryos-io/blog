---
title:  Service-to-Service Authentication
summary: "How to use service credentials in Simulations?"
series: "ACME series"
weight: 4
last_updated: July 3, 2016
sidebar: mydoc_sidebar
permalink: mydoc_s2s.html
folder: mydoc
toc: false
---

This section is pertaining to the **Load DSL mode**, and demonstrates how to use service to service authentication for OAuth enabled services. In **Scenario mode** you send authorization headers by using your HTTP client and its header methods.  Please refer to the HTTP client's documentation of your choice. 

### Using S2S in Load DSL

In web services environment, it is a common practice that client services send a service token along with the user' access tokens to APIs being tested. In this case, one of the tokens is used in `Authorization` header as `Bearer` token whereas the other token is sent in a custom header to the backend, e.g `X-Service-Token`. Other option is to send the service token with Authorization header and to use a custom one for the user's access token. The test developer can set the type of the **Bearer** which is sent in Authorization header with the configuration: `dev.oauth.bearer` whereas the `dev.oauth.headerName` defines the name of the non-bearer token. The following example demonstrates the service token being as bearer, whereas the `X-User-Token` is being used for the user token:

```
dev.oauth2.service.authentication=true
dev.oauth2.service.clientId=TestService
dev.oauth2.service.clientSecret=123-secret
dev.oauth2.service.grantType=authorization_code
dev.oauth2.service.clientCode=eyJ4NXUiO12345=
dev.oauth2.bearer=service
dev.oauth2.headerName=X-User-Token
```

The first line enables the service-to-service authentication. The service will be authenticated with clientId, clientSecret, grantType and the clientCode against authorisation server. As of 1.6.0, the only accepted grant type value is the `authorization_code`. The service token will be sent as bearer while the user token is sent in `X-User-Token`.

> **_WARNING:_** As of 1.6.0, the only accepted grant type value for service-to-service authentication is the `authorization_code`

`dev.oauth.bearer` can take either `service` or `user` pre-defined values. The `service` string literal stands for service token as the `user` is for user token. To enable service-to-service authentication together with user token, use auth() directive on DSL:

```java
Start.dsl()
     .run(http("API Request")
        .header(session -> from(X_REQUEST_ID, "Rhino-" + UUID.randomUUID().toString()))
        .header(X_API_KEY, SimulationConfig.getApiKey())
        .auth()
        .endpoint(FILES_ENDPOINT)
        .get()
        .saveTo("result"))
```

Please note that, the service tokens cannot be sent unattended. They must be accompanied by user tokens in requests. How to deal with test users in simulations, you can refer to [Test Users](https://github.com/ryos-io/Rhino/wiki/Testing-with-Users).