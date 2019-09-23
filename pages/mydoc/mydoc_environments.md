---
title: Environments
permalink: mydoc_environments.html
sidebar: mydoc_sidebar
tags: [Environments]
keywords: Environments
last_updated: November 30, 2018
summary: "Writing environment-aware load tests."
toc: false
folder: mydoc
---

Rhino simulations are environment-aware so you can start your simulations targeting a certain environment by passing the application parameter with **-Dprofile=DEV**. Environment-aware configurations are prefixed with `<env>.<configuration>=<configuration value>`:

```properties
dev.oauth.service.authentication=true
dev.oauth.service.clientId=TestService
dev.oauth.service.clientSecret=123-secret
```

Supported environment profiles, in uppercase, **DEV**, **STAGE**, **PROD** whereas the prefix in properties file are all lowercase.
