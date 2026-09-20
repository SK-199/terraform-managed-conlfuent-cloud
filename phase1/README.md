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
