---
title: Accessing Docker Enterprise
summary: This Solution Brief documents different ways to access UCP, DTR and Docker Engine.
type: guide
author: avinashdesireddy
visibleto: loggedinleads
campaign: 
product:
- ee
platform:
- linux
tags:
- solution-brief
- swarm
- kubernetes
uniqueid: 
---

## Overview

Docker Enterprise provides access to various components via Docker CLI and kubectl using multal TLS authenitication.

Docker Enterprise Edition (EE) is the only Containers as a Service (CaaS) Platform for IT that manages and secures diverse applications across disparate infrastructure, both on-premises and in the cloud.

Before I tell you about it, let me first describe the use case. You’re a sysadmin managing a Docker cluster and you have the following requirements:

Different individuals in your LDAP/AD need various levels of access to the containers/services in your cluster -

* Some users need to be able to go inside the running containers.
* Some users just need to be able to see the logs
* You do NOT want to give SSH access to each host in your cluster.

Now, how do you achieve this? The answer, or feature rather, is a client bundle. When you do a docker version command you will see two entries. The client portion of the engine is able to connect to a local server AND a remote once a client bundle is invoked.

## What is a Client bundle

A client bundle is a group of certificates downloadable directly from the Docker Universal Control Plane (UCP) user interface within the admin section for “My Profile”. This allows you to authorize a remote Docker engine to a specific user account managed in Docker EE, absorbing all associated RBAC controls in the process. You can now execute docker swarm and kubectl commands from your remote machine that take effect on the remote cluster.

### TODO: Insert Example

asdf

### Using UCP API to download client bundle

Client bundle download script

## Docker Context



## What is Docker Context?

### When to use?
