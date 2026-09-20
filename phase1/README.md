# Terraform Managed Confluent Cloud

Terraform project for managing Confluent Cloud infrastructure progressively through multiple phases.

## Repository Structure

```text
phase1/
  Base Confluent Cloud DEV infrastructure

phase2/
  Phase 1 + AWS private networking / Confluent private connectivity

phase3/
  Phase 1 + Phase 2 + Kafka operational resources

phase4/
  Phase 1 + Phase 2 + Phase 3 + CI/CD and automation



# Terraform Managed Confluent Cloud

Terraform-based learning project for progressively building and managing **Confluent Cloud Enterprise on AWS** using Infrastructure as Code.

The project is intentionally developed in phases so that each stage builds on the previous one.

---

# Project Goal

The objective is to understand how a production-style Confluent Cloud platform can be built and operated using:

- Terraform
- AWS networking
- Confluent Cloud
- Private Network Interface (PNI)
- AWS PrivateLink
- Kafka APIs
- Confluent CLI
- Schema Registry
- RBAC
- Service Accounts
- Kafka topics
- CI/CD

The project starts with a development Enterprise cluster and progressively moves toward a production-style architecture.

---

# Repository Structure

```text
terraform-managed-conlfuent-cloud/
│
├── README.md
│
├── phase1/
│   ├── README.md
│   ├── PHASE3.md
│   │
│   ├── *.tf
│   ├── variables.tf
│   ├── variables-dev.tfvars
│   ├── backend.tf
│   └── ...
│
├── phase2/
│   └── ...
│
├── phase3/
│   └── ...
│
└── phase4/
    └── ...
```

## Planned Phases

```text
Phase 1
  Base Confluent Cloud DEV infrastructure

Phase 2
  AWS private networking / Confluent private connectivity

Phase 3
  Kafka operational resources

Phase 4
  CI/CD and automation
```

---

# Current Implementation

The current learning environment contains:

```text
Confluent Cloud
      |
      v
DEV Environment
      |
      v
Enterprise Kafka
      |
      v
AWS PNI
      |
      v
Customer AWS VPC
      |
      +---- Private Subnets
      |
      +---- PNI ENIs
      |
      +---- Proxy Subnet
             |
             +---- EC2 Proxy
```

---

# Phase 1 — Base Confluent Cloud

The initial environment contains:

```text
Environment:
dev

Environment ID:
env-rg6vx9

Stream Governance:
ESSENTIALS
```

Kafka:

```text
Cluster:
dev-enterprise

Cluster ID:
lkc-v78yrnz

Type:
Enterprise

Cloud:
AWS

Region:
ap-south-1

Availability:
LOW

Maximum eCKU:
1
```

The cluster is intentionally small and configured for development/learning.

---

# Phase 2 — AWS Private Networking

A dedicated AWS VPC was created for Confluent private connectivity.

```text
VPC:
vpc-0c8aab6a30ebc6d84

CIDR:
10.50.0.0/24

Region:
ap-south-1
```

Three private subnets:

```text
ap-south-1a
10.50.0.0/26

ap-south-1b
10.50.0.64/26

ap-south-1c
10.50.0.128/26
```

The original AWS learning VPC was kept separate and was not modified.

---

# PNI Architecture

Confluent Private Network Interface provides private connectivity between AWS resources and Enterprise Kafka.

Our architecture:

```text
AWS VPC
   |
   +---- Customer-owned ENIs
   |
   +---- Security Groups
   |
   v
PNI Access Point
   |
   v
PNI Gateway
   |
   v
Confluent Cloud
   |
   v
Enterprise Kafka
```

Created:

```text
PNI Gateway:
gw-oke30j

PNI Access Point:
ap-8z93yw

PNI ENIs:
51
```

Confluent's documentation states that PNI uses customer-controlled ENIs in the customer's AWS VPC and limited permissions for Confluent to attach those ENIs.

Official documentation:

[Confluent Cloud — AWS PNI](https://docs.confluent.io/cloud/current/networking/aws-pni.html?utm_source=chatgpt.com)

---

# PNI Endpoints

Kafka:

```text
lkc-v78yrnz-ap8z93yw.ap-south-1.aws.accesspoint.glb.confluent.cloud:9092
```

REST:

```text
https://lkc-v78yrnz-ap8z93yw.ap-south-1.aws.accesspoint.glb.confluent.cloud:443
```

Schema Registry:

```text
https://lsrc-xq6ym7z-ap8z93yw.ap-south-1.aws.accesspoint.glb.confluent.cloud
```

The `ap-8z93yw` portion identifies the PNI access point.

---

# Connectivity Validation

The following were successfully validated:

```text
DNS
  ↓
Private IP resolution
  ↓
TCP 443
  ↓
TLS
  ↓
Confluent endpoint
```

and:

```text
TCP 9092
   ↓
SUCCESS
```

The REST endpoint returned HTTP 404 for the tested root/API paths, but DNS, TCP and TLS connectivity were successful.

A `404` at the HTTP layer does not mean that the private network path is broken.

---

# Phase 3 — Operational Resources

Phase 3 will focus on managing Confluent resources such as:

```text
Kafka Topics
Topic Configurations
Service Accounts
API Keys
RBAC
ACLs
Schemas
Schema Registry
Connectors
```

The detailed current networking implementation and validation is documented in:

```text
phase1/PHASE3.md
```

---

# PNI vs AWS PrivateLink

These should not be treated as the same technology.

## PNI

```text
Customer AWS VPC
       |
Customer-owned ENIs
       |
PNI Access Point
       |
PNI Gateway
       |
Confluent Cloud
```

PNI uses AWS Multi-VPC ENI attachment.

## AWS PrivateLink

```text
Customer VPC
       |
AWS VPC Endpoint
       |
AWS PrivateLink
       |
Confluent Cloud
```

PrivateLink provides private connectivity using AWS PrivateLink infrastructure.

Confluent supports different private connectivity solutions depending on cluster type and architecture.

---

# Important PrivateLink Questions

## Is PrivateLink still useful if we use PNI?

Yes.

PNI and PrivateLink are different private networking solutions.

For AWS Enterprise clusters, Confluent documents support for simultaneous PNI and PrivateLink connectivity.

---

## Is PNI replacing PrivateLink?

No.

They solve private connectivity using different AWS mechanisms.

The choice depends on:

- organization network architecture
- security requirements
- AWS networking standards
- existing VPC design
- operational model
- connectivity requirements

---

## Can an Enterprise cluster use public and private connectivity?

Private networking changes how cluster endpoints are accessed.

When private networking is used, cluster endpoints are not simply reachable from the public internet. Client connectivity must use the configured private network path.

---

# Cloud Console vs Private Networking

A very important concept learned during this project:

**Having private Kafka connectivity does not automatically mean that every Cloud Console feature works from an ordinary internet-connected browser.**

Some Cloud Console functionality, especially topic management, communicates directly with Kafka cluster endpoints.

Confluent documents that:

```text
Topic management
Create topic
Update topic
Delete topic
Produce
Consume
```

require the client to have connectivity to the network hosting the private cluster endpoints.

---

# Resource Metadata Access

Resource Metadata Access can be used when the requirement is primarily:

```text
View topics
View metrics
Stream Lineage
```

However, it is not equivalent to full Kafka connectivity.

It does not provide full topic management such as:

```text
Create
Update
Delete
Produce
Consume
```

For full functionality, the client must have connectivity to the private network.

---

# How Can Operations Be Performed?

Private networking does not mean that the Cloud Console is the only management mechanism.

Operations can be performed using:

```text
Terraform
Confluent CLI
Kafka CLI
REST API
Cloud Console
```

provided the required:

```text
Network connectivity
+
Authentication
+
Authorization
```

are available.

A production-style model can therefore look like:

```text
Developer
    |
    v
GitHub
    |
    v
Pull Request
    |
    v
CI/CD
    |
    v
Terraform Plan
    |
    v
Approval
    |
    v
Terraform Apply
    |
    v
Confluent Cloud
```

For direct operational troubleshooting:

```text
Operations VM
      |
Private network
      |
PNI / PrivateLink
      |
Enterprise Kafka
```

---

# Why We Created the Proxy

The EC2 proxy was created specifically to learn how Cloud Console access can be provided to a private cluster from a workstation outside the VPC.

Architecture:

```text
Laptop
   |
Internet
   |
13.207.58.16
   |
EC2 Proxy
10.50.0.202
   |
AWS VPC
   |
PNI
   |
Confluent Enterprise
```

The proxy is therefore an **optional Console-access experiment**, not a requirement for PNI itself.

Confluent documents proxy/SSH/DNS approaches for allowing external clients such as the Cloud Console, REST API, CLI, Terraform and Kafka API to reach private cluster endpoints.

---

# Production Considerations

The current project is a learning environment.

Before production use, review:

- VPC CIDR allocation from enterprise network architecture
- subnet sizing
- approved AWS Availability Zones
- security group rules
- SSH access
- proxy exposure
- IAM permissions
- API key storage
- Secrets Manager integration
- Terraform state security
- S3 state bucket policies
- state locking
- RBAC
- service accounts
- audit requirements
- CI/CD approvals
- DEV/UAT/PROD separation
- disaster recovery
- monitoring
- logging
- DNS architecture

The current proxy security group is intentionally broad for learning and should not be copied directly into production.

---

# Important Official Documentation

### Confluent Cloud Networking

[Networking on Confluent Cloud](https://docs.confluent.io/cloud/current/networking/overview.html?utm_source=chatgpt.com)

### AWS Networking

[AWS Networking Overview](https://docs.confluent.io/cloud/current/networking/aws-overview.html?utm_source=chatgpt.com)

### AWS PNI

[Private Network Interface on AWS](https://docs.confluent.io/cloud/current/networking/aws-pni.html?utm_source=chatgpt.com)

### Cloud Console with Private Networking

[Use Confluent Cloud Console with Private Networking](https://docs.confluent.io/cloud/current/networking/ccloud-console-access.html?utm_source=chatgpt.com)

### AWS PrivateLink Overview

[AWS PrivateLink Overview](https://docs.confluent.io/cloud/current/networking/aws-privatelink-overview.html?utm_source=chatgpt.com)

### AWS PrivateLink Setup

[Create an AWS PrivateLink Connection](https://docs.confluent.io/cloud/current/networking/private-links/aws-privatelink.html?utm_source=chatgpt.com)

### Networking FAQ

[Confluent Cloud Networking FAQ](https://docs.confluent.io/cloud/current/networking/networking-faq.html?utm_source=chatgpt.com)

### Kafka Topics

[Confluent Cloud Topics](https://docs.confluent.io/cloud/current/topics/overview.html?utm_source=chatgpt.com)

---

# Current State

```text
                    Confluent Cloud
                          |
                    DEV Environment
                          |
                  Enterprise Kafka
                     lkc-v78yrnz
                          |
                       PNI
                          |
                 +--------+--------+
                 |                 |
             Gateway          Access Point
             gw-oke30j          ap-8z93yw
                                   |
                              51 AWS ENIs
                                   |
                              AWS VPC
                             10.50.0.0/24
                                   |
                         +---------+---------+
                         |                   |
                   Private Subnets       Proxy
                                             |
                                          EC2
                                      13.207.58.16
```

Core PNI connectivity has been implemented and validated.

Next development focus:

```text
Phase 3
   |
   +-- Topics
   +-- Topic configuration
   +-- Service Accounts
   +-- API Keys
   +-- RBAC
   +-- Schemas
   +-- Connectors
   |
   v
Phase 4
   |
   +-- GitHub
   +-- CI/CD
   +-- Terraform Plan
   +-- Approval
   +-- Terraform Apply
   +-- DEV → UAT → PROD
```
