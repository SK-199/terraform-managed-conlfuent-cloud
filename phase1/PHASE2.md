# Phase 2 — Enterprise Kafka with AWS Private Networking

## Objective

Phase 2 extends Phase 1 by adding AWS private networking to the existing Confluent Cloud Enterprise Kafka cluster.

The Kafka cluster type remains **Enterprise**.

Phase 2 focuses on infrastructure and network connectivity, not Kafka resource management.

## Architecture

```text
                         AWS Account
              ┌─────────────────────────────┐
              │                             │
              │ Existing Organization VPC   │
              │                             │
              │   Private Subnet            │
              │        │                    │
              │        ▼                    │
              │      AWS ENI                │
              │        │                    │
              │   Security Group             │
              │                             │
              └────────┼────────────────────┘
                       │
                 Private Connectivity
                       │
                       ▼
              ┌─────────────────────┐
              │   Confluent Cloud   │
              │                     │
              │ Environment: dev    │
              │                     │
              │ Enterprise Kafka    │
              │ dev-enterprise      │
              └─────────────────────┘
```

## Phase 1 vs Phase 2

| Item                         | Phase 1    | Phase 2                         |
| ---------------------------- | ---------- | ------------------------------- |
| Confluent Environment        | Yes        | Yes                             |
| Stream Governance            | Essentials | Essentials                      |
| Kafka Cluster                | Enterprise | Enterprise                      |
| AWS Region                   | ap-south-1 | ap-south-1                      |
| eCKU                         | 1          | 1 for development               |
| Public connectivity          | Yes        | No / private connectivity added |
| AWS VPC integration          | No         | Yes                             |
| Private networking           | No         | Yes                             |
| PNI                          | No         | Yes                             |
| Topics                       | No         | No                              |
| Schemas                      | No         | No                              |
| Connectors                   | No         | No                              |
| API keys/resource management | No         | No                              |

## Why Enterprise is retained

The purpose of Phase 2 is to learn private networking for an Enterprise Kafka cluster.

Confluent Cloud currently supports AWS Private Network Interface (PNI) for Enterprise Kafka clusters.

PNI uses ENIs in the customer's AWS VPC and allows the customer to control the associated security groups.

## AWS networking model

The organization owns the AWS networking infrastructure.

Terraform should consume existing networking information such as:

* VPC ID
* Subnet IDs
* Availability Zones
* Security Group information
* Required CIDR information

The Phase 2 Terraform project should not create an organization VPC unless the network design explicitly requires Terraform to own it.

## Phase 2 responsibilities

Terraform will eventually manage or configure:

1. Confluent Cloud Enterprise Kafka cluster
2. AWS private networking integration
3. Required AWS network resources
4. Security configuration
5. Private connectivity
6. Validation of Kafka connectivity

## Out of scope

Kafka resource management is intentionally excluded from this repository.

The following will be handled in a separate repository:

* Topics
* Service Accounts
* API Keys
* Producer access
* Consumer access
* RBAC
* ACLs
* Schema onboarding
* Schema deletion/version management
* Connectors
* Other Kafka resource operations

## Networking comparison

### Enterprise

AWS Enterprise clusters support private networking through:

* Private Network Interface (PNI)
* AWS PrivateLink

### Dedicated

AWS Dedicated clusters additionally support:

* VPC Peering
* Transit Gateway
* PrivateLink

Dedicated clusters use a Confluent Cloud network construct for these networking configurations.

## Implementation approach

Phase 2 will be implemented incrementally.

### Step 1

Copy Phase 1 as the starting point.

### Step 2

Verify that the copied configuration produces no changes.

### Step 3

Identify the organization's AWS VPC and subnet design.

### Step 4

Add the required networking variables.

### Step 5

Add the AWS networking resources/modules required for PNI.

### Step 6

Configure the Confluent Cloud networking integration.

### Step 7

Validate private Kafka connectivity.

### Step 8

Document the architecture, Terraform dependencies, commands, and troubleshooting.

## Important design principle

The organization owns the AWS network.

Confluent Cloud owns the managed Kafka infrastructure.

Terraform acts as the automation layer connecting the two.

## Phase 2 target

```text
Existing AWS Network
        +
AWS Private Networking
        +
Existing Enterprise Kafka
        =
Private Enterprise Kafka connectivity
```

Phase 3 will be a separate repository dedicated to Confluent Cloud resource management.

