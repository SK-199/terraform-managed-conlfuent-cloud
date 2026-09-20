# Phase 3 — Confluent Cloud Private Client Connectivity & Console Access

> **Project:** Confluent Cloud Enterprise on AWS  
> **Region:** `ap-south-1` (Mumbai)  
> **Goal:** Build on Phase 1 and Phase 2 to validate private client connectivity and understand why Kafka Topic management in the Confluent Cloud Console requires additional private-network access.

---

## 1. Long-Term Repository Architecture

The project should be separated by **ownership and lifecycle**, not simply by phase number.

```text
SK-199/
│
├── confluent-cloud-foundation
│   └── Confluent environment + Kafka cluster + Stream Governance
│
├── aws-confluent-networking
│   └── AWS VPC + subnets + security groups + PNI ENIs
│
├── confluent-cloud-private-networking
│   └── Confluent PNI Gateway + Access Point + private connectivity
│
├── confluent-cloud-resources
│   └── Topics + RBAC + service accounts + API keys + schemas + connectors
│
└── confluent-cloud-cicd
    └── GitHub Actions + Terraform plan/apply + environment promotion
```

### Why separate repositories?

A Terraform repository/state boundary should normally represent a different **ownership, lifecycle, or blast-radius boundary**.

- AWS networking can live independently from Kafka.
- Kafka cluster lifecycle can be independent from topic configuration.
- Private networking depends on the Confluent environment/cluster and AWS networking.
- Kafka resources depend on the cluster and required connectivity.
- CI/CD orchestrates the deployment workflows.

---

# 2. Dependency Flow

```text
                    ┌──────────────────────────┐
                    │ confluent-cloud-foundation│
                    │                          │
                    │ Environment              │
                    │ Stream Governance        │
                    │ Enterprise Kafka Cluster │
                    └────────────┬─────────────┘
                                 │
                                 │ IDs / cluster dependency
                                 ▼
                    ┌──────────────────────────┐
                    │ confluent-cloud-private-  │
                    │ networking                │
                    │                          │
                    │ PNI Gateway              │
                    │ PNI Access Point         │
                    └────────────┬─────────────┘
                                 │
                                 │ private connection
                                 ▼
┌─────────────────────────┐      │
│ aws-confluent-networking│      │
│                         │      │
│ VPC                     │◄─────┘
│ Subnets                 │
│ Security Groups         │
│ PNI ENIs                │
│ ENI permissions         │
└────────────┬────────────┘
             │
             ▼
       AWS private network
             │
             ▼
      Private Kafka endpoint
             │
             ▼
  ┌──────────────────────────┐
  │ confluent-cloud-resources│
  │                          │
  │ Topics                   │
  │ RBAC                     │
  │ Service Accounts         │
  │ API Keys                 │
  │ Schemas                  │
  │ Connectors               │
  └──────────────────────────┘
```

---

# 3. Phase 1 — Enterprise Kafka Foundation — COMPLETE

Phase 1 created the basic Confluent Cloud Enterprise foundation.

## Resources

```text
Confluent Environment
        │
        ├── Stream Governance Essentials
        │
        └── Enterprise Kafka Cluster
                │
                ├── AWS
                ├── ap-south-1
                ├── Enterprise
                ├── LOW availability
                └── max eCKU = 1
```

### Important IDs

```text
Environment: env-rg6vx9
Kafka cluster: lkc-v78yrnz
Cluster name: dev-enterprise
```

### Terraform remote state

```text
S3 bucket: terraform-tf-location
Key: confluent-cloud/dev/terraform.tfstate
Region: ap-south-1
encrypt = true
use_lockfile = true
```

### Phase 1 flow

```text
terraform init
      │
      ▼
terraform validate
      │
      ▼
terraform plan
      │
      ▼
terraform apply
      │
      ▼
Confluent Environment
      │
      ▼
Enterprise Kafka Cluster
```

### Why Phase 1 exists

The Kafka service lifecycle is separated from networking. The Enterprise cluster exists first, and private networking is then added around it.

---

# 4. Phase 2 — AWS PNI Networking — COMPLETE

Phase 2 established the AWS network required for Confluent Private Network Interface (PNI).

## AWS VPC

```text
VPC: 10.50.0.0/24
Region: ap-south-1
```

## Subnets

```text
ap-south-1a
10.50.0.0/26

ap-south-1b
10.50.0.64/26

ap-south-1c
10.50.0.128/26
```

## AWS architecture

```text
AWS Account: 343218202978
          │
          ▼
┌──────────────────────────────────────┐
│ VPC 10.50.0.0/24                     │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ ap-south-1a                      │ │
│ │ 10.50.0.0/26                     │ │
│ │ 17 PNI ENIs                      │ │
│ └──────────────────────────────────┘ │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ ap-south-1b                      │ │
│ │ 10.50.0.64/26                    │ │
│ │ 17 PNI ENIs                      │ │
│ └──────────────────────────────────┘ │
│                                      │
│ ┌──────────────────────────────────┐ │
│ │ ap-south-1c                      │ │
│ │ 10.50.0.128/26                   │ │
│ │ 17 PNI ENIs                      │ │
│ └──────────────────────────────────┘ │
└──────────────────┬───────────────────┘
                   │
                   ▼
             Confluent PNI
```

## Phase 2 resources

```text
1 VPC
3 subnets
1 security group
2 ingress rules
51 ENIs
51 ENI attachment permissions
1 PNI Gateway
1 PNI Access Point
```

### Account IDs

```text
AWS account owning VPC/ENIs:
343218202978

Confluent AWS account receiving INSTANCE-ATTACH permission:
784941337404
```

### PNI Gateway

```text
Name: dev-pni-gateway
ID: gw-oke30j
Status: Ready
```

### PNI Access Point

```text
Name: dev-pni-access-point
ID: ap-8z93yw
Status: Ready
```

---

# 5. Phase 2 PNI Architecture

```text
                         AWS ACCOUNT
                       343218202978
                            │
                            ▼
                 ┌──────────────────────┐
                 │ VPC 10.50.0.0/24     │
                 │                      │
                 │  AZ-a                │
                 │  17 ENIs             │
                 │                      │
                 │  AZ-b                │
                 │  17 ENIs             │
                 │                      │
                 │  AZ-c                │
                 │  17 ENIs             │
                 └──────────┬───────────┘
                            │
                  AWS Multi-VPC ENI
                     attachment
                            │
                            ▼
                 ┌──────────────────────┐
                 │ Confluent PNI        │
                 │ Gateway              │
                 │ gw-oke30j            │
                 │ ap-south-1           │
                 │ aps1-az1/az2/az3     │
                 └──────────┬───────────┘
                            │
                            ▼
                 ┌──────────────────────┐
                 │ PNI Access Point     │
                 │ ap-8z93yw            │
                 └──────────┬───────────┘
                            │
                            ▼
                 ┌──────────────────────┐
                 │ Enterprise Kafka     │
                 │ dev-enterprise       │
                 │ lkc-v78yrnz          │
                 └──────────────────────┘
```

---

# 6. Phase 2 Validation Commands

## Validate Terraform

```bash
terraform fmt
terraform validate
terraform plan -var-file=variables-dev.tfvars
```

Expected after the implementation is synchronized:

```text
No changes. Your infrastructure matches the configuration.
```

## Count PNI ENIs

```bash
aws ec2 describe-network-interfaces \
  --region ap-south-1 \
  --filters Name=vpc-id,Values=vpc-0c8aab6a30ebc6d84 \
  --query 'length(NetworkInterfaces)'
```

Observed:

```text
51
```

## Check ENI status

```bash
aws ec2 describe-network-interfaces \
  --region ap-south-1 \
  --filters Name=vpc-id,Values=vpc-0c8aab6a30ebc6d84 \
  --query 'NetworkInterfaces[].Status' \
  --output text | tr '\t' '\n' | sort | uniq -c
```

Observed:

```text
45 available
6 in-use
```

The six in-use ENIs were distributed across the three AZs:

```text
ap-south-1a → 2 in-use
ap-south-1b → 2 in-use
ap-south-1c → 2 in-use
```

This confirms that Confluent has attached ENIs across all three AZs. The remaining available ENIs are capacity reserved for the PNI design and do not by themselves indicate a failure.

## Check attached ENIs

```bash
aws ec2 describe-network-interfaces \
  --region ap-south-1 \
  --filters Name=vpc-id,Values=vpc-0c8aab6a30ebc6d84 \
  --query 'NetworkInterfaces[?Status==`in-use`].{ENI:NetworkInterfaceId,Subnet:SubnetId,AZ:AvailabilityZone,PrivateIP:PrivateIpAddress,Description:Description}' \
  --output table
```

---

# 7. Why the Kafka Topic GUI Is Not Available Yet

After PNI was enabled, the Kafka cluster showed:

```text
Managing topics not available

All topics in this cluster are protected by a private network
and cannot be altered over the Internet.
```

This does **not** mean that PNI failed.

The distinction is:

```text
Confluent Cloud Console login
          │
          └── Public Confluent UI → available

Schema Registry UI
          │
          └── Schema Registry endpoint → available

Kafka Topic management
          │
          └── Requires access to private Kafka endpoint
              from the network path used by the operation
```

The browser is normally outside the AWS private network:

```text
Laptop / Browser
       │
       │ Public Internet
       ▼
Confluent Cloud Console
       │
       X
       │
       X  Private Kafka endpoint
       │
       ▼
      PNI
       │
       ▼
Enterprise Kafka
```

Therefore the console can still show the environment, cluster and Schema Registry while Kafka topic-management operations are unavailable from the public browser path.

The Confluent documentation referenced in the original project screenshots explains this private-network Console behavior. Use the current Confluent documentation as the authoritative source because UI behavior and wording can change.

---

# 8. Why Schema Registry Works While Topic Management Does Not

This is a key Enterprise/private-networking concept.

## Schema Registry

The Schema Registry service has its own HTTPS endpoint and supports private networking through the environment's PNI configuration.

Conceptually:

```text
                     AWS VPC
                       │
                       │ PNI
                       ▼
                PNI Access Point
                       │
             ┌─────────┴─────────┐
             │                   │
             ▼                   ▼
        Kafka Cluster       Schema Registry
        Kafka :9092          HTTPS :443
```

Your Schema Registry console currently shows:

```text
Stream Governance: Essentials
Schema Registry: lsrc-xq6ym7z
Region: ap-south-1
Schemas:
  topic1-value
```

So Schema Registry itself is healthy and usable.

## Kafka topic management

Kafka topics are managed through Kafka cluster APIs. When the cluster is protected by private networking, the Kafka endpoint is private.

```text
Topic operation
     │
     ▼
Kafka cluster endpoint
     │
     │ private network
     ▼
PNI / AWS network
     │
     ▼
Kafka cluster
```

A browser on the public Internet does not automatically have that private network path.

Therefore:

```text
Schema Registry UI       → available
Topic Create/Edit/Delete → unavailable from current public path
```

This is a **network-access distinction**, not evidence of a missing Kafka permission or Terraform failure.

---

# 9. Do Not Mix PNI and PrivateLink DNS Designs

PNI and AWS PrivateLink are different connectivity models.

For PNI, Confluent manages the DNS records for PNI endpoints. Do not automatically create Route 53 private hosted zones based on PrivateLink documentation.

Conceptually:

```text
PNI
Client → DNS → PNI endpoint → AWS ENI → Confluent

PrivateLink
Client → Route 53 / private DNS → Interface endpoint → Confluent service
```

Use the networking documentation corresponding to the actual connectivity mechanism.

---

# 10. Phase 3 Objective

## Phase 3 — Private Client Connectivity & Console Access

The objective is to move from:

```text
PNI infrastructure READY
```

to:

```text
AWS client
    │
    ▼
Private DNS resolution
    │
    ▼
Private Kafka endpoint
    │
    ▼
Confluent Enterprise Kafka
```

### Phase 3 scope

1. Create or use a test EC2 instance inside the PNI VPC.
2. Validate DNS resolution for the Kafka endpoint.
3. Test TCP connectivity to Kafka `9092`.
4. Test HTTPS/REST `443`.
5. Validate TLS certificates.
6. Test Kafka client authentication.
7. Test the Schema Registry private endpoint.
8. Understand/configure private Console access.
9. Validate Topic management through the Console once the private path is available.

---

# 11. Phase 3 Detailed Flow

```text
Step 1
Create/test EC2 client inside 10.50.0.0/24
          │
          ▼
Step 2
DNS resolution
          │
          ▼
Step 3
Kafka TCP 9092
          │
          ▼
Step 4
REST HTTPS 443
          │
          ▼
Step 5
TLS certificate validation
          │
          ▼
Step 6
Kafka authentication
          │
          ▼
Step 7
Schema Registry private endpoint
          │
          ▼
Step 8
Private Confluent Console access
          │
          ▼
Step 9
Topic Create / Update / Delete validation
```

---

# 12. Important Current Network Detail

The EC2 host used during the learning exercise is in a different VPC:

```text
Existing EC2 VPC:
172.31.0.0/16
```

The PNI VPC is:

```text
PNI VPC:
10.50.0.0/24
```

Therefore a DNS or `nc` test from the existing EC2 does **not** prove that the PNI path is broken.

The correct connectivity test should originate from a client that has a network path into the PNI VPC.

```text
WRONG TEST
Existing EC2
172.31.0.0/16
       │
       X
       │
PNI VPC 10.50.0.0/24

CORRECT TEST
Test EC2
10.50.0.0/24
       │
       ▼
PNI
       │
       ▼
Confluent Enterprise Kafka
```

---

# 13. Phase 3 Connectivity Commands

After a test client exists inside the PNI VPC:

## DNS

```bash
nslookup <KAFKA_BOOTSTRAP_HOSTNAME>
```

or:

```bash
dig <KAFKA_BOOTSTRAP_HOSTNAME>
```

## Kafka TLS on 9092

```bash
openssl s_client \
  -connect <KAFKA_BOOTSTRAP_HOSTNAME>:9092 \
  -servername <KAFKA_BOOTSTRAP_HOSTNAME> \
  -verify_hostname <KAFKA_BOOTSTRAP_HOSTNAME>
```

Expected successful TLS validation includes:

```text
Verify return code: 0 (ok)
```

## REST / HTTPS 443

```bash
openssl s_client \
  -connect <KAFKA_REST_HOSTNAME>:443 \
  -servername <KAFKA_REST_HOSTNAME> \
  -verify_hostname <KAFKA_REST_HOSTNAME>
```

## Port checks

```bash
nc -vz <KAFKA_BOOTSTRAP_HOSTNAME> 9092
```

```bash
nc -vz <KAFKA_REST_HOSTNAME> 443
```

These tests validate the network path only. Kafka authentication/authorization must still be validated separately.

---

# 14. Phase 3 Security Considerations

Current learning security group:

```text
Source: VPC CIDR 10.50.0.0/24

TCP 9092
Kafka client access

TCP 443
REST / HTTPS access
```

For production, apply least privilege based on the actual client source ranges and required destinations.

Review:

```text
Security Group
├── Kafka 9092
├── HTTPS 443
└── Egress requirements
```

Do not assume the learning configuration is a production-ready security baseline.

---

# 15. Phase 3 Completion Criteria

Phase 3 should be considered complete when all of the following are demonstrated:

```text
[ ] Test client exists in / has a valid route to the PNI VPC
[ ] Kafka DNS resolves
[ ] Kafka TCP 9092 reachable
[ ] Kafka TLS validation succeeds
[ ] Kafka authentication succeeds
[ ] Kafka metadata can be retrieved
[ ] Schema Registry private endpoint is reachable
[ ] Schema can be registered/retrieved through the private path
[ ] Private Console access is configured where required
[ ] Topic Create is available from the intended Console path
[ ] Topic Update/Delete are validated
```

---

# 16. What Is Completed vs Pending

```text
PHASE 1 — FOUNDATION
────────────────────────────────────
Environment                         COMPLETE
Stream Governance Essentials        COMPLETE
Enterprise Kafka cluster            COMPLETE
S3 Terraform backend                COMPLETE

PHASE 2 — PNI NETWORKING
────────────────────────────────────
AWS VPC                             COMPLETE
3 private subnets                   COMPLETE
Security group                      COMPLETE
51 PNI ENIs                         COMPLETE
51 ENI permissions                  COMPLETE
PNI Gateway                         COMPLETE
PNI Access Point                    COMPLETE
Multi-AZ PNI design                 COMPLETE

PHASE 3 — PRIVATE CONNECTIVITY
────────────────────────────────────
Private test client                 PENDING
DNS validation                      PENDING
Kafka 9092 validation               PENDING
REST 443 validation                 PENDING
TLS validation                      PENDING
Kafka authentication                PENDING
Schema Registry private test        PENDING
Console private access              PENDING
Topic GUI management                PENDING
```

---

# 17. Long-Term Roadmap

## Repository 1 — `confluent-cloud-foundation`

### Use case

Own the lifecycle of core Confluent Cloud infrastructure:

```text
Environment
Kafka cluster
Stream Governance
Cluster-level settings
```

### Depends on

Nothing in the networking layer.

---

## Repository 2 — `aws-confluent-networking`

### Use case

Own the AWS-side network foundation:

```text
VPC
Subnets
Security Groups
PNI ENIs
AWS-side permissions
```

### Depends on

Normally organization networking requirements, CIDR allocations, and AWS account/region standards.

It does not need the Kafka cluster to exist merely to create the VPC and subnets.

---

## Repository 3 — `confluent-cloud-private-networking`

### Use case

Own Confluent-side private connectivity:

```text
PNI Gateway
PNI Access Point
Private endpoint configuration
```

### Depends on

```text
confluent-cloud-foundation
+
aws-confluent-networking
```

It needs the Confluent environment/cluster context and AWS network/ENI information.

---

## Repository 4 — `confluent-cloud-resources`

### Use case

Own application/data-plane resources:

```text
Topics
Topic configuration
RBAC grants
Service Accounts
API Keys
Schemas
Connectors
```

### Depends on

```text
Foundation
+
Required network connectivity
+
Security/IAM model
```

---

## Repository 5 — `confluent-cloud-cicd`

### Use case

Own deployment automation:

```text
GitHub Actions
Terraform plan
Terraform apply
Approvals
Environment promotion
DEV → UAT → PROD
```

### Depends on

The deployment interfaces and credentials of the infrastructure repositories.

---

# 18. Final End-to-End Architecture

```text
                              GitHub
                                 │
          ┌──────────────────────┼──────────────────────┐
          │                      │                      │
          ▼                      ▼                      ▼
 Foundation Repository    AWS Networking Repo       CI/CD Repo
          │                      │                      │
          ▼                      ▼                      │
 Confluent Environment        AWS VPC                  │
          │                      │                      │
          ▼                      ├── Subnets            │
 Enterprise Kafka              ├── SG                  │
          │                      └── PNI ENIs            │
          │                             │               │
          └──────────────┬──────────────┘               │
                         ▼                              │
                  PNI Gateway                           │
                         │                              │
                         ▼                              │
                  PNI Access Point                      │
                         │                              │
              ┌──────────┴───────────┐                  │
              │                      │                  │
              ▼                      ▼                  │
        Kafka :9092             Schema Registry          │
                               HTTPS :443                │
              │                      │                  │
              └──────────┬───────────┘                  │
                         ▼                              │
                 Private AWS Client                     │
                         │                              │
                         ▼                              │
              Kafka / Schema APIs                       │
                         │                              │
                         ▼                              │
              Resources Repository ◄────────────────────┘
                         │
             ┌───────────┼────────────┐
             ▼           ▼            ▼
          Topics       RBAC       Connectors/Schemas
```

---

# 19. Key Learning Outcome

By the end of Phase 3, the project should demonstrate the complete path:

```text
Terraform
   ↓
Confluent Enterprise
   ↓
AWS VPC
   ↓
PNI
   ↓
Private DNS
   ↓
Private Kafka endpoint
   ↓
Kafka client
   ↓
Schema Registry
   ↓
Private Console access
   ↓
Topic management
```

The major conceptual transition is:

> **Phase 1:** Create the Enterprise Kafka service.
>
> **Phase 2:** Establish AWS PNI private networking.
>
> **Phase 3:** Prove and operate the private connectivity path.

---

# 20. Reference Material / Screenshots

During this project, the following Confluent Cloud UI behavior was captured and discussed:

- Enterprise cluster networking page showing `dev-pni-gateway` as **Ready**.
- PNI Access Point `dev-pni-access-point` as **Ready**.
- Kafka Topics page showing **Managing topics not available** after private networking was enabled.
- Schema Registry page showing Stream Governance Essentials and schema `topic1-value`.
- Confluent documentation screenshot/reference for private Console access and proxy architecture.

For the GitHub repository, recommended structure:

```text
docs/
└── images/
    ├── phase1-cluster.png
    ├── phase2-pni-gateway.png
    ├── phase2-access-point.png
    ├── phase2-networking.png
    ├── phase3-topic-private-network.png
    └── phase3-console-private-access.png
```

Screenshots should be stored separately from this Markdown file so the documentation remains readable and Git history remains manageable.

---

# 21. Official Confluent References

Use current Confluent documentation as the authoritative source for implementation details and UI behavior:

- AWS PNI: https://docs.confluent.io/cloud/current/networking/aws-pni.html
- Confluent Cloud Console access with private networking: https://docs.confluent.io/cloud/current/networking/ccloud-console-access.html
- Connectivity testing: https://docs.confluent.io/cloud/current/networking/testing.html
- Schema Registry data contracts: https://docs.confluent.io/cloud/current/sr/fundamentals/data-contracts.html

> **Important:** Confluent Cloud UI labels and screenshots can change. The architecture and commands in this document describe the learning implementation; verify current product behavior against the linked Confluent documentation before applying the design to production.


