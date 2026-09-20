# Phase 3 — Confluent Cloud Enterprise Operations & Private Connectivity

## 1. Purpose

This phase documents the hands-on implementation of a **Confluent Cloud Enterprise Kafka cluster on AWS**, including:

- Enterprise Kafka cluster
- Stream Governance
- AWS VPC foundation
- Private Network Interface (PNI)
- PNI Gateway
- PNI Access Point
- Customer-owned AWS ENIs
- ENI permissions for Confluent
- Security groups
- Private DNS resolution
- Private Kafka connectivity
- Private Kafka REST connectivity
- Schema Registry private endpoint
- AWS EC2 proxy for Cloud Console access
- Validation of Kafka `9092` and REST `443`
- Understanding of PNI vs legacy AWS PrivateLink
- Understanding of how Kafka operations are performed when private networking is enabled

The implementation is Terraform-managed wherever possible.

---

# 2. Target Architecture

```text
                         Confluent Cloud
                              |
                    Enterprise Kafka Cluster
                         lkc-v78yrnz
                              |
                 +------------+------------+
                 |                         |
             Kafka 9092                 REST 443
                 |                         |
                 +------------+------------+
                              |
                       PNI Access Point
                           ap-8z93yw
                              |
                       PNI Gateway
                           gw-oke30j
                              |
                    Customer AWS Account
                         343218202978
                              |
              +---------------+---------------+
              |               |               |
          Private Subnet   Private Subnet   Private Subnet
          ap-south-1a      ap-south-1b      ap-south-1c
              |               |               |
          PNI ENIs         PNI ENIs         PNI ENIs
              |               |               |
              +---------------+---------------+
                              |
                         AWS VPC
                       10.50.0.0/24
                              |
                    +---------+---------+
                    |                   |
              Private network      Public proxy
                                  subnet 10.50.0.192/28
                                          |
                                      EC2 Proxy
                                    10.50.0.202
                                    Public IP
                                    13.207.58.16
```

---

# 3. Confluent Cloud Environment

## Environment

| Property | Value |
|---|---|
| Environment | `dev` |
| Environment ID | `env-rg6vx9` |
| Stream Governance | Essentials |

## Kafka Cluster

| Property | Value |
|---|---|
| Cluster name | `dev-enterprise` |
| Cluster ID | `lkc-v78yrnz` |
| Cluster type | Enterprise |
| Cloud | AWS |
| Region | `ap-south-1` |
| Availability | LOW |
| Maximum eCKU | 1 |

This cluster was intentionally configured as a small development/lab Enterprise cluster.

---

# 4. AWS Networking Foundation

A dedicated AWS VPC was created for the Confluent private networking implementation.

## VPC

| Property | Value |
|---|---|
| VPC ID | `vpc-0c8aab6a30ebc6d84` |
| CIDR | `10.50.0.0/24` |
| Region | `ap-south-1` |
| DNS Support | Enabled |
| DNS Hostnames | Enabled |

The original EC2 VPC was not modified.

Original learning EC2 VPC:

```text
VPC: vpc-007479771f169e95a
CIDR: 172.31.0.0/16
```

The PNI implementation uses a separate VPC.

---

# 5. Private Subnets

Three private subnets were created for the PNI design.

| AZ | Subnet | CIDR |
|---|---|---|
| `ap-south-1a` | `subnet-0964403a679010c0e` | `10.50.0.0/26` |
| `ap-south-1b` | `subnet-0bd783f7d10439ce4` | `10.50.0.64/26` |
| `ap-south-1c` | `subnet-0798b574452af2370` | `10.50.0.128/26` |

The Terraform module used for this is:

```text
modules/aws-networking/
```

---

# 6. PNI Gateway

A Confluent Cloud PNI gateway was created using Terraform.

Terraform resource:

```hcl
resource "confluent_gateway" "pni" {
  display_name = "dev-pni-gateway"

  environment {
    id = confluent_environment.this.id
  }

  aws_private_network_interface_gateway {
    region = var.aws_region
    zones  = var.aws_availability_zone_ids
  }
}
```

Created gateway:

```text
Gateway ID: gw-oke30j
Name:       dev-pni-gateway
Region:     ap-south-1
Status:     Ready
```

Availability zones:

```text
aps1-az1
aps1-az2
aps1-az3
```

Confluent describes the PNI gateway as the resource representing connectivity to Confluent Cloud services from the customer's network.

Official documentation:

https://docs.confluent.io/cloud/current/networking/aws-pni.html

---

# 7. PNI ENIs

Customer-owned AWS Elastic Network Interfaces were created for PNI.

The Terraform configuration creates:

```text
3 private subnets
×
17 ENIs per subnet
=
51 ENIs
```

Therefore:

```text
Total PNI ENIs = 51
```

The ENIs are located in the customer's AWS account:

```text
AWS Account:
343218202978
```

The ENIs remain customer-controlled AWS resources.

Confluent receives limited permission to attach them to Confluent Cloud infrastructure.

---

# 8. PNI Security Group

Security group:

```text
Name:
confluent-pni-dev
```

The PNI security group allows:

### Kafka

```text
TCP 9092
Source: 10.50.0.0/24
```

### REST

```text
TCP 443
Source: 10.50.0.0/24
```

The security group is intended to control traffic between the customer VPC and Confluent Cloud through the PNI ENIs.

For a production deployment, the rules should be reviewed against the organization's approved network security policy.

---

# 9. ENI Attachment Permissions

Each PNI ENI was given:

```text
Permission:
INSTANCE-ATTACH
```

To Confluent's AWS account:

```text
784941337404
```

Important distinction:

```text
Customer AWS account:
343218202978

Confluent AWS account:
784941337404
```

The customer owns the ENIs while Confluent receives the limited permission required to attach them.

---

# 10. PNI Access Point

A Confluent PNI access point was created.

Terraform:

```hcl
resource "confluent_access_point" "pni" {
  display_name = "dev-pni-access-point"

  environment {
    id = confluent_environment.this.id
  }

  gateway {
    id = confluent_gateway.pni.id
  }

  aws_private_network_interface {
    network_interfaces = aws_network_interface.pni[*].id
    account            = var.aws_account_id
  }
}
```

Created:

```text
Access Point:
ap-8z93yw

Gateway:
gw-oke30j

Status:
Ready

AWS Account:
343218202978
```

The access point contains all 51 ENIs.

Terraform state verification confirmed:

```text
51 ENI IDs
```

---

# 11. PNI Kafka Endpoint

The active Kafka PNI endpoint is:

```text
lkc-v78yrnz-ap8z93yw.ap-south-1.aws.accesspoint.glb.confluent.cloud:9092
```

The important part is:

```text
ap-8z93yw
```

which identifies the PNI access point.

The `glb` endpoint represents the newer PNI access-point connectivity model.

---

# 12. PNI REST Endpoint

The active REST endpoint is:

```text
https://lkc-v78yrnz-ap8z93yw.ap-south-1.aws.accesspoint.glb.confluent.cloud:443
```

This is the endpoint used for Kafka REST operations through the PNI network path.

---

# 13. DNS Validation

DNS resolution was tested from the proxy EC2 instance.

Command:

```bash
nslookup lkc-v78yrnz-ap8z93yw.ap-south-1.aws.accesspoint.glb.confluent.cloud
```

The hostname resolved to private IP addresses such as:

```text
10.50.0.70
10.50.0.132
10.50.0.74
10.50.0.5
10.50.0.133
10.50.0.7
```

This proves that the PNI hostname resolves to private addresses inside the AWS networking path.

No `/etc/hosts` modification was required on the proxy for this PNI DNS resolution.

---

# 14. REST TLS Connectivity Test

The following test was performed:

```bash
curl -vk \
  https://lkc-v78yrnz-ap8z93yw.ap-south-1.aws.accesspoint.glb.confluent.cloud:443
```

Result:

```text
DNS resolution       SUCCESS
TCP 443              SUCCESS
TLS 1.3               SUCCESS
Certificate exchange SUCCESS
HTTP response         404
```

The HTTP `404` is not a network failure.

It proves that:

```text
DNS
  ↓
Private IP
  ↓
TCP 443
  ↓
TLS
  ↓
Confluent endpoint
```

is working.

---

# 15. Kafka Port 9092 Connectivity Test

Kafka connectivity was tested using:

```bash
nc -vz \
  lkc-v78yrnz-ap8z93yw.ap-south-1.aws.accesspoint.glb.confluent.cloud \
  9092
```

Result:

```text
Connection succeeded
```

Therefore TCP connectivity to the Kafka endpoint is working.

---

# 16. Kafka REST API Test

The following was tested:

```bash
curl -vk \
  https://lkc-v78yrnz-ap8z93yw.ap-south-1.aws.accesspoint.glb.confluent.cloud:443/kafka/v3/clusters
```

The connection successfully reached the Confluent endpoint and TLS negotiation completed.

The endpoint returned HTTP 404.

This should be treated as an API path/authentication/application-level issue rather than a network connectivity issue.

---

# 17. Schema Registry

The environment also has Schema Registry.

Public endpoint:

```text
https://psrc-1928ywr.ap-south-1.aws.confluent.cloud
```

Private PNI endpoint:

```text
https://lsrc-xq6ym7z-ap8z93yw.ap-south-1.aws.accesspoint.glb.confluent.cloud
```

The important concept is that this is the same Schema Registry service exposed through different network paths.

```text
Public:
Internet
   ↓
Schema Registry

Private:
AWS VPC
   ↓
PNI
   ↓
Schema Registry
```

Schema Registry can therefore be accessed privately when the client has connectivity to the PNI network.

---

# 18. Schema Registry Authentication Test

A Schema Registry API credential was tested against the public endpoint.

A valid credential returned:

```json
{}
```

when calling the Schema Registry root endpoint.

The same credential can be used against the private PNI Schema Registry endpoint, provided the client has private network connectivity.

Credentials should be supplied through environment variables or a secret-management system.

Do not commit API secrets into Git.

Example:

```bash
export SR_API_KEY="..."
export SR_API_SECRET="..."
```

Then:

```bash
curl -u "$SR_API_KEY:$SR_API_SECRET" \
  https://lsrc-xq6ym7z-ap8z93yw.ap-south-1.aws.accesspoint.glb.confluent.cloud/subjects
```

---

# 19. Legacy PrivateLink Endpoint

The cluster also displayed a legacy PrivateLink hostname:

```text
lkc-v78yrnz.ap-south-1.aws.private.confluent.cloud:9092
```

and:

```text
https://lkc-v78yrnz.ap-south-1.aws.private.confluent.cloud:443
```

However, this is **not the active PNI endpoint**.

The cluster console indicated that this legacy endpoint requires the corresponding PrivateLink Attachment to be in the `READY` state.

The hostname currently returned:

```text
NXDOMAIN
```

from the proxy environment.

This is expected because we did not build the legacy PrivateLink Attachment infrastructure.

We therefore did **not** modify the PNI implementation to make this legacy hostname work.

---

# 20. PNI vs AWS PrivateLink

These are two different private connectivity architectures.

## PNI

```text
Customer VPC
     |
Customer-owned ENIs
     |
PNI Access Point
     |
PNI Gateway
     |
Confluent Cloud
```

PNI ENIs are located in the customer's AWS VPC and controlled by the customer.

## PrivateLink

Conceptually:

```text
Customer VPC
     |
AWS VPC Endpoint
     |
AWS PrivateLink
     |
Confluent Cloud service
```

PrivateLink uses AWS PrivateLink/VPC endpoint infrastructure.

Confluent supports private connectivity options according to cluster type and AWS architecture.

Official documentation:

https://docs.confluent.io/cloud/current/networking/aws-privatelink-overview.html

---

# 21. Important PrivateLink vs PNI Questions

## Does Enterprise support both?

Yes.

Confluent documentation states that AWS Enterprise clusters can support simultaneous connectivity using PrivateLink Attachment and PNI.

Therefore:

```text
Enterprise Kafka
      |
      +---- PNI
      |
      +---- PrivateLink
```

can be possible.

---

## Is PNI replacing PrivateLink?

No.

They are different private networking solutions.

PNI uses customer-controlled ENIs and AWS Multi-VPC ENI attachment.

PrivateLink uses AWS PrivateLink connectivity.

---

## Why did we choose PNI?

This learning project specifically uses PNI to understand:

- customer-owned ENIs
- security groups
- AWS networking
- Confluent gateway
- access points
- private DNS
- private Kafka endpoints
- private REST endpoints
- browser/Console access through a proxy

---

# 22. Cloud Console and Private Networking

A very important discovery in this phase is:

**Private networking does not automatically make every Confluent Cloud Console function available from a normal internet-connected browser.**

Some Console functionality, including topic management, uses the actual Kafka cluster endpoints.

Those private endpoints are not publicly accessible.

Confluent documents two approaches:

### Option 1 — Resource Metadata Access

Useful for:

- viewing topic metadata
- viewing metrics
- Stream Lineage

But this is not sufficient for:

```text
Create topic
Update topic
Delete topic
Produce messages
Consume messages
```

### Option 2 — Connect the client to the private network

This can involve:

- proxy
- SSH tunnel
- VPN/private network connectivity
- DNS configuration

Once the browser/client can reach the private cluster endpoint, the full Console functionality can be used.

Official documentation:

https://docs.confluent.io/cloud/current/networking/ccloud-console-access.html

---

# 23. Why We Created the Proxy EC2

To experiment with Cloud Console access from an internet-connected workstation, a proxy EC2 instance was created inside the PNI VPC.

Architecture:

```text
Laptop / Browser
       |
       | Internet
       |
       v
Public IP
13.207.58.16
       |
       v
EC2 Proxy
10.50.0.202
       |
       | Private AWS network
       v
PNI Endpoint
       |
       v
Confluent Enterprise
```

EC2:

```text
Instance:
i-003229a589eae9582

Private IP:
10.50.0.202

Public IP:
13.207.58.16

Subnet:
subnet-0366f028b42f85bd6

VPC:
vpc-0c8aab6a30ebc6d84

Instance type:
t3.micro
```

---

# 24. Proxy Public Subnet

A public subnet was created specifically for the proxy.

```text
CIDR:
10.50.0.192/28

AZ:
ap-south-1a

Subnet:
subnet-0366f028b42f85bd6
```

The subnet has:

```text
MapPublicIpOnLaunch = true
```

An Internet Gateway was also created:

```text
igw-0ee1df4f489fb5cd4
```

with a public route:

```text
0.0.0.0/0
      ↓
Internet Gateway
```

---

# 25. Proxy Security Group

The learning proxy security group currently allows:

```text
TCP 22
TCP 443
TCP 9092
```

from:

```text
0.0.0.0/0
```

Outbound traffic:

```text
All
```

This configuration is intentionally broad for the learning exercise.

For production:

- SSH should be restricted to approved administration IPs or a bastion
- proxy ports should be restricted to approved client networks
- security groups should follow least privilege
- public exposure should be minimized

---

# 26. Why DNS Is Important

Private endpoints require DNS resolution to the private addresses.

For example:

```text
lkc-v78yrnz-ap8z93yw.ap-south-1.aws.accesspoint.glb.confluent.cloud
                         |
                         v
                  private 10.50.x.x
```

DNS is not simply a cosmetic configuration.

It allows the client to:

- resolve the correct private endpoint
- use the correct hostname
- preserve TLS/SNI
- reach the correct Confluent service

Confluent also documents DNS as an essential part of private networking.

Official documentation:

https://docs.confluent.io/cloud/current/networking/networking-faq.html

---

# 27. Why We Must Not Replace the PNI Hostname

We should not simply change the hostname to an arbitrary IP.

For example, this is not the correct production approach:

```text
https://10.50.0.70:443
```

The Confluent hostname must be preserved because TLS/SNI and endpoint routing depend on the hostname.

Correct:

```text
https://lkc-v78yrnz-ap8z93yw.ap-south-1.aws.accesspoint.glb.confluent.cloud
```

---

# 28. Kafka Operations with Private Networking

Private networking does not mean that Kafka operations can only be performed through the Cloud Console.

Kafka resources can be managed using:

```text
Terraform
Confluent CLI
Kafka CLI
REST API
Confluent Cloud Console
```

The important requirement is that the tool must have the required network connectivity and authorization.

For example:

```text
Terraform
    |
    v
Confluent APIs
    |
    v
Kafka resources
```

or:

```text
Kafka CLI
    |
    | private connectivity
    v
PNI
    |
    v
Enterprise Kafka
```

---

# 29. Production-Style Operating Model

A production organization may choose not to give engineers direct browser access to private Kafka endpoints.

A common infrastructure-as-code model is:

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

Terraform can manage resources such as:

- Kafka topics
- topic configurations
- service accounts
- RBAC
- ACLs
- Schema Registry configuration
- connectors
- networking resources

For operational troubleshooting, authorized administrators can use:

```text
Operations VM
      |
Private network
      |
PNI
      |
Enterprise Kafka
```

with:

```text
Confluent CLI
Kafka CLI
REST API
```

---

# 30. What Has Been Successfully Validated

The following parts have been successfully implemented/validated.

| Component | Status |
|---|---|
| Enterprise Kafka cluster | READY |
| AWS VPC | Created |
| 3 private subnets | Created |
| PNI Gateway | READY |
| 51 PNI ENIs | Created |
| ENI attachment permissions | Created |
| PNI security group | Created |
| PNI Access Point | READY |
| Private DNS resolution | SUCCESS |
| Private TCP 9092 | SUCCESS |
| Private TLS 443 | SUCCESS |
| Private REST endpoint reachability | SUCCESS |
| Schema Registry private endpoint | Available |
| Proxy VPC networking | Created |
| Proxy EC2 | Running |
| Internet Gateway | Created |
| Proxy public subnet | Created |
| Legacy PrivateLink endpoint | Not configured |
| Cloud Console private access | Proxy/DNS configuration remaining |

---

# 31. Remaining Work

The core PNI infrastructure is complete.

Remaining work for the Console experiment:

```text
1. Install/configure NGINX or another proxy
2. Configure TCP/SNI forwarding
3. Configure workstation DNS/hosts
4. Configure the Confluent Console private REST endpoint
5. Test Cloud Console topic management
6. Create a test topic
7. Verify topic using CLI/REST
8. Remove the proxy or harden it after testing
```

This is an optional demonstration layer.

It is **not required for the underlying PNI infrastructure to work**.

---

# 32. Terraform Resources Created in This Phase

Major Terraform resources include:

```text
aws_vpc
aws_subnet
aws_security_group
aws_vpc_security_group_ingress_rule
aws_network_interface
aws_network_interface_permission

aws_internet_gateway
aws_route_table
aws_route_table_association

aws_instance

confluent_gateway
confluent_access_point
```

The implementation is split into logical Terraform files/modules to keep the networking design maintainable.

---

# 33. Important Lessons

### Lesson 1

Private networking and Cloud Console access are separate concerns.

```text
Private connectivity
        ≠
Browser connectivity
```

---

### Lesson 2

A private Kafka endpoint can be fully reachable even if the Cloud Console cannot manage topics.

```text
Kafka 9092       → reachable
REST 443         → reachable
Console topic UI → requires browser path
```

---

### Lesson 3

Resource Metadata Access is not full private Kafka access.

It provides visibility but does not provide full topic management.

---

### Lesson 4

PNI ENIs are customer-owned resources.

The customer controls:

- ENIs
- subnet placement
- security groups
- network routing

Confluent receives limited attachment permissions.

---

### Lesson 5

DNS is a critical component of private networking.

The Confluent hostname must resolve to the appropriate private connectivity path.

---

### Lesson 6

Private networking does not eliminate Terraform/CLI/API operations.

It changes the required network path for operations that interact with private cluster endpoints.

---

# 34. Official Confluent Documentation

## Confluent Cloud Networking

https://docs.confluent.io/cloud/current/networking/overview.html

## AWS Networking

https://docs.confluent.io/cloud/current/networking/aws-overview.html

## AWS PNI

https://docs.confluent.io/cloud/current/networking/aws-pni.html

## Cloud Console with Private Networking

https://docs.confluent.io/cloud/current/networking/ccloud-console-access.html

## AWS PrivateLink

https://docs.confluent.io/cloud/current/networking/aws-privatelink-overview.html

## AWS PrivateLink Configuration

https://docs.confluent.io/cloud/current/networking/private-links/aws-privatelink.html

## Networking FAQ

https://docs.confluent.io/cloud/current/networking/networking-faq.html

## Kafka Topics

https://docs.confluent.io/cloud/current/topics/overview.html

---

# 35. Phase 3 Final State

At the end of this phase, the learning environment contains:

```text
Confluent Cloud
└── DEV Environment
    ├── Stream Governance Essentials
    └── Enterprise Kafka
        └── dev-enterprise
             |
             └── PNI
                  |
                  ├── Gateway
                  │    └── gw-oke30j
                  │
                  └── Access Point
                       └── ap-8z93yw
                            |
                            └── 51 AWS ENIs
                                 |
                                 └── AWS VPC
                                      ├── Private Subnet 1
                                      ├── Private Subnet 2
                                      ├── Private Subnet 3
                                      │
                                      └── Proxy Subnet
                                           └── EC2 Proxy
```

The core private connectivity path has been successfully established and validated.

The next phase can build on this foundation for **Kafka operational resources, topics, RBAC, service accounts, schemas, connectors, and eventually CI/CD automation**.
