# Phase 1 — Confluent Cloud Terraform DEV

## 1. Objective

Phase 1 creates a **DEV Confluent Cloud Enterprise Kafka environment on AWS** using Terraform.

### Current deployment

| Item | Value |
|---|---|
| Confluent Environment | `dev` |
| Environment ID | `env-rg6vx9` |
| Kafka Cluster | `dev-enterprise` |
| Kafka Cluster ID | `lkc-v78yrnz` |
| Cluster type | Enterprise |
| Cloud | AWS |
| Region | `ap-south-1` (Mumbai) |
| Availability | `LOW` |
| Maximum eCKU | `1` |
| Stream Governance | `ESSENTIALS` |
| Terraform state | AWS S3 |
| PNI / Private Networking | **Not used in Phase 1** |

---

## 2. Phase 1 Architecture

```text
                         AWS ACCOUNT
                       Region: ap-south-1
                              |
               +--------------+--------------+
               |                             |
               |                             |
        Terraform EC2                    AWS S3
        (terraform CLI)             Remote Terraform State
               |                    terraform-tf-location
               |                    |
               |                    +-- confluent-cloud/dev/
               |                        terraform.tfstate
               |
               | Confluent Provider / API
               v
      +---------------------------------------+
      |           CONFLUENT CLOUD             |
      |                                       |
      |  Organization                        |
      |      |                                |
      |      v                                |
      |  Environment: dev                     |
      |      |                                |
      |      +--> Stream Governance           |
      |      |    ESSENTIALS                  |
      |      |                                |
      |      v                                |
      |  Enterprise Kafka Cluster             |
      |      dev-enterprise                   |
      |      |                                |
      |      +-- AWS ap-south-1               |
      |      +-- max eCKU = 1                 |
      |      +-- LOW availability              |
      |                                       |
      +---------------------------------------+

      Phase 1 does NOT create:
      - AWS VPC for Confluent
      - PNI gateway
      - PNI ENIs
      - VPC peering/private networking
```

### How Phase 1 works

Terraform runs from the EC2 host. The Confluent Terraform provider authenticates to Confluent Cloud and calls the Confluent Cloud API. Confluent Cloud creates and operates the managed Kafka service on AWS. Terraform stores the desired infrastructure state in the S3 backend.

**Important:** Confluent Cloud is the managed service; this Terraform project is managing the Confluent Cloud resources, not installing Kafka brokers manually on the user's AWS EC2 instance.

---

## 3. Terraform dependency flow

```text
variables-dev.tfvars
        |
        v
     variables.tf
        |
        v
      main.tf
        |
        +------------------------------+
        |                              |
        v                              v
confluent_environment.this     module.kafka_cluster
        |                              |
        | environment_id               v
        +------------------------> confluent_kafka_cluster.this

                         |
                         v
                    Confluent Cloud
```

The environment is created first, and its ID is passed to the Kafka cluster module.

---

## 4. Repository structure

```text
confluent-cloud-terraform/
|
+-- README.md
+-- backend.tf
+-- backend-dev.tfvars
+-- backend-uat.tfvars
+-- backend-prod.tfvars
+-- provider.tf
+-- version.tf
+-- main.tf
+-- variables.tf
+-- variables-dev.tfvars
+-- variables-uat.tfvars
+-- variables-prod.tfvars
+-- outputs.tf
+-- networking.tf
+-- dns.tf
+-- kms.tf
+-- secrets-manager.tf
+-- schema-registry.tf
|
+-- modules/
    |
    +-- kafka-cluster/
    |   +-- main.tf
    |   +-- variables.tf
    |   +-- outputs.tf
    |   +-- providers.tf
    |
    +-- aws-pni/
        +-- main.tf
        +-- variables.tf
        +-- outputs.tf
```

### File purpose — one simple sentence each

| File | Use case |
|---|---|
| `README.md` | Documents the project and how to operate it. |
| `backend.tf` | Declares the Terraform S3 backend without hard-coding an environment. |
| `backend-dev.tfvars` | Supplies the DEV S3 bucket, key and backend settings during `terraform init`. |
| `backend-uat.tfvars` | Reserved backend configuration for UAT. |
| `backend-prod.tfvars` | Reserved backend configuration for PROD. |
| `provider.tf` | Configures the Confluent Terraform provider. |
| `version.tf` | Defines Terraform and provider version requirements. |
| `main.tf` | Creates the Confluent environment and calls the Kafka cluster module. |
| `variables.tf` | Defines reusable input variables for the root module. |
| `variables-dev.tfvars` | Contains the actual DEV values such as region, cluster name and eCKU. |
| `variables-uat.tfvars` | Reserved values for UAT. |
| `variables-prod.tfvars` | Reserved values for PROD. |
| `outputs.tf` | Displays important IDs and Kafka endpoints after deployment. |
| `networking.tf` | Reserved for future AWS/networking configuration. |
| `dns.tf` | Reserved for future DNS configuration. |
| `kms.tf` | Reserved for future AWS KMS integration. |
| `secrets-manager.tf` | Reserved for future AWS Secrets Manager integration. |
| `schema-registry.tf` | Reserved for future Schema Registry resources/configuration. |
| `modules/kafka-cluster/main.tf` | Defines the Enterprise Kafka cluster resource. |
| `modules/kafka-cluster/variables.tf` | Defines inputs required by the Kafka module. |
| `modules/kafka-cluster/outputs.tf` | Returns cluster information to the root module. |
| `modules/kafka-cluster/providers.tf` | Explicitly tells Terraform that this module uses `confluentinc/confluent`. |
| `modules/aws-pni/*` | Holds future private-networking resources and is not called in Phase 1. |

---

## 5. Current important Terraform configuration

### Root `main.tf`

The root configuration creates the environment and then passes the environment ID into the Kafka cluster module.

```hcl
resource "confluent_environment" "this" {
  display_name = var.environment_name

  stream_governance {
    package = var.stream_governance_package
  }
}

module "kafka_cluster" {
  source = "./modules/kafka-cluster"

  environment_id = confluent_environment.this.id
  display_name   = var.kafka_cluster_name
  availability   = var.kafka_availability
  cloud          = "AWS"
  region         = var.aws_region
  max_ecku       = var.kafka_max_ecku

  depends_on = [
    confluent_environment.this
  ]
}
```

### Kafka module

```hcl
resource "confluent_kafka_cluster" "this" {
  display_name = var.display_name
  availability = var.availability
  cloud        = var.cloud
  region       = var.region

  enterprise {
    max_ecku = var.max_ecku
  }

  environment {
    id = var.environment_id
  }
}
```

---

## 6. Backend design

Terraform state is stored remotely in S3.

```text
Bucket:
terraform-tf-location

DEV state:
confluent-cloud/dev/terraform.tfstate

Region:
ap-south-1
```

The design allows separate state for each environment:

```text
confluent-cloud/dev/terraform.tfstate
confluent-cloud/uat/terraform.tfstate
confluent-cloud/prod/terraform.tfstate
```

This prevents DEV, UAT and PROD from sharing the same Terraform state file.

### First DEV initialization

```bash
terraform init -upgrade -backend-config=backend-dev.tfvars
```

Terraform does **not** automatically load `backend-dev.tfvars`; the `-backend-config` argument supplies those values during initialization.

After the backend is initialized, normal DEV operations are:

```bash
terraform validate
terraform plan -var-file=variables-dev.tfvars
terraform apply -var-file=variables-dev.tfvars
```

`terraform init -reconfigure` is normally only needed when intentionally changing backend configuration, for example moving from DEV state to UAT state.

---

## 7. Authentication

The Confluent provider needs valid Confluent Cloud API credentials. The earlier `401 Unauthorized` occurred during environment creation because the provider was not authenticated correctly at that time.

After valid credentials were available, the final apply completed successfully:

```text
Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

The two resources were:

1. `confluent_environment.this`
2. `module.kafka_cluster.confluent_kafka_cluster.this`

---

## 8. PNI decision in Phase 1

PNI is intentionally **not active** in this phase.

The repository contains:

```text
modules/aws-pni/
```

but `main.tf` does not call that module.

Therefore the Phase 1 apply does not create the AWS PNI resources.

The old PNI variables should also not be kept in `variables-dev.tfvars` when they are not declared by the root module, because Terraform will report undeclared-variable warnings.

Future PNI work should start only after the organization's AWS networking design is known, including the required VPC/subnet/CIDR/connectivity model.

---

## 9. What is managed by whom?

```text
Terraform
  |
  +-- Confluent environment configuration
  +-- Kafka cluster configuration
  +-- Stream Governance package configuration
  +-- Terraform state
  |
  v
Confluent Cloud
  |
  +-- Managed Kafka service
  +-- Kafka brokers / platform operations
  +-- Cluster infrastructure on AWS
  +-- Kafka service endpoints

AWS in Phase 1
  |
  +-- S3 Terraform state bucket
  +-- EC2 host running Terraform CLI
```

Terraform does not SSH into Confluent Kafka brokers or install Kafka software on the EC2 machine.

---

## 10. Important commands

### Format

```bash
terraform fmt -recursive
```

### Validate

```bash
terraform validate
```

### Plan

```bash
terraform plan -var-file=variables-dev.tfvars
```

### Apply

```bash
terraform apply -var-file=variables-dev.tfvars
```

### Outputs

```bash
terraform output
```

### Providers

```bash
terraform providers
```

### State resources

```bash
terraform state list
```

### Destroy DEV

```bash
terraform destroy -var-file=variables-dev.tfvars
```

---

## 11. Important interview questions

### Q1. Why use Terraform for Confluent Cloud?

Terraform provides infrastructure as code, repeatable deployments, reviewable changes, state management and a path to CI/CD.

### Q2. Why use an S3 backend?

It stores Terraform state remotely so the state is not dependent on one developer's local machine.

### Q3. Why separate state for DEV, UAT and PROD?

Each environment should have an independent state boundary so Terraform operations in one environment do not accidentally operate on another environment's state.

### Q4. What is the difference between `backend-dev.tfvars` and `variables-dev.tfvars`?

`backend-dev.tfvars` configures where Terraform state is stored during `terraform init`; `variables-dev.tfvars` supplies normal Terraform input variables during plan/apply.

### Q5. Why is the Kafka module separate from `main.tf`?

The module encapsulates Kafka cluster creation so the same reusable logic can later be used for DEV, UAT and PROD.

### Q6. What is eCKU?

An eCKU is a Confluent Cloud capacity unit used to represent Kafka cluster capacity.

### Q7. Why is this DEV cluster configured with one eCKU?

The current environment is a learning/practice DEV deployment and the requested maximum capacity is intentionally set to `1`.

### Q8. Is the Kafka cluster running on the EC2 server?

No. The EC2 server runs Terraform CLI; Confluent Cloud operates the managed Kafka service on AWS.

### Q9. What does `401 Unauthorized` mean during Terraform apply?

It indicates that the Confluent provider could not authenticate successfully with Confluent Cloud using the credentials available to Terraform.

### Q10. What is Terraform drift?

Drift is a difference between the configuration Terraform manages and the actual remote infrastructure, often caused by changes made outside Terraform.

### Q11. What happens if the state is lost?

Terraform loses its recorded mapping between configuration and managed resources; state recovery or resource import may then be required before safely continuing management.

### Q12. Why pin provider versions?

Version constraints make deployments more predictable and reduce unexpected behavior caused by automatic provider changes.

### Q13. Why does the child module need `providers.tf`?

It explicitly declares `confluentinc/confluent` so Terraform does not incorrectly infer another provider source for the module.

### Q14. Why is `depends_on` used between the environment and Kafka module?

It makes the intended dependency explicit: the Kafka cluster belongs to the environment created by the root configuration.

---

## 12. Scenario-based interview questions

### Scenario 1 — Plan wants to destroy the Kafka cluster

Do not apply immediately. Inspect the plan, compare it with the variables and configuration, check the state and determine whether the change is intentional.

Useful command:

```bash
terraform plan -var-file=variables-dev.tfvars
```

### Scenario 2 — DEV deployment is unexpectedly using UAT state

Check the backend configuration first. Verify the active S3 state key and whether `terraform init -reconfigure` was used when switching backend configuration.

### Scenario 3 — Terraform gives 401 from Confluent Cloud

Check the Confluent API key/secret available to the shell or execution environment and verify that the credentials are valid and authorized for the Confluent Cloud organization/environment operation.

### Scenario 4 — Environment creation succeeds but Kafka creation fails

Check the cluster resource parameters, environment ID, region, cloud, availability, eCKU configuration, provider version and Confluent Cloud permissions.

### Scenario 5 — Organization asks for private connectivity

Do not immediately create a new VPC. First obtain the organization's approved VPC/subnet/CIDR and connectivity requirements, then activate the PNI/private-networking design in a separate phase.

### Scenario 6 — Someone changes the cluster manually in Confluent Cloud

Run a Terraform plan and inspect the detected difference. Decide whether the change should be brought back under Terraform control or intentionally reflected in the code.

### Scenario 7 — Move from DEV to UAT

Switch the backend deliberately:

```bash
terraform init -reconfigure -backend-config=backend-uat.tfvars
```

Then use UAT variables:

```bash
terraform plan -var-file=variables-uat.tfvars
```

The key interview point is that **backend state selection and normal Terraform variables are separate concepts**.

### Scenario 8 — CI/CD is introduced later

The pipeline should run Terraform in controlled stages such as:

```text
Git PR
  |
  v
terraform fmt / validate
  |
  v
terraform plan
  |
  v
Review / approval
  |
  v
terraform apply
```

Production should use its own backend state and environment-specific variables.

---

## 13. Phase 1 → Phase 2 roadmap

```text
PHASE 1 — CURRENT
|
+-- Confluent Environment
+-- Enterprise Kafka
+-- 1 eCKU DEV
+-- Stream Governance Essentials
+-- AWS ap-south-1
+-- S3 remote Terraform state
+-- No PNI
|
v
PHASE 2 — FUTURE
|
+-- Organization AWS networking integration
+-- VPC / subnet design as required
+-- PNI / private connectivity
+-- DNS
+-- KMS
+-- Secrets Manager
+-- CI/CD
+-- DEV / UAT / PROD deployment flow
|
v
PHASE 3 — RESOURCE MANAGEMENT
|
+-- Topics
+-- Service Accounts
+-- API Keys
+-- RBAC / ACLs
+-- Schemas
+-- Connectors
+-- Operational automation
```

---

## 14. One-minute interview explanation

> I built a Terraform-based Confluent Cloud deployment for DEV. Terraform runs from an AWS EC2 host and uses the Confluent provider to create a Confluent Cloud environment and an Enterprise Kafka cluster in AWS Mumbai. The cluster is configured with a maximum of one eCKU for practice, and Stream Governance Essentials is enabled. Terraform state is stored remotely in S3 with a separate state key for each environment. The Kafka creation is implemented as a reusable Terraform module. Phase 1 intentionally does not create private networking or PNI; those resources are kept for a later phase after the organization's AWS networking requirements are finalized. The structure is designed so UAT, PROD and CI/CD can be added without changing the basic architecture.

---

## 15. Phase 1 status

```text
Terraform initialization       DONE
Terraform formatting           DONE
Terraform validation           DONE
Terraform plan                 DONE
Confluent environment          CREATED
Enterprise Kafka cluster       CREATED
Stream Governance              ESSENTIALS
Kafka capacity                 1 eCKU
AWS region                     ap-south-1
S3 remote state                CONFIGURED
PNI                             NOT USED
Phase 1                        COMPLETE
```

#Error
<img width="634" height="576" alt="image" src="https://github.com/user-attachments/assets/7ca55e0c-6792-4dc7-a1b7-88363f3a178b" />

dev-enterprise
Cluster networking setup incomplete
intentionally did not configure private networking / PNI in Phase 1.

Unable to create topic
Topics
Managing topics not available
Your browser can't create, delete, or change settings for topics of this cluster. All topics in this cluster are protected by a private network and cannot be altered over the Internet.
We will update in phase2

