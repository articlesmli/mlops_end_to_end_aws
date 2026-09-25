# MLOps End-to-End AWS Platform 

An enterprise-grade, end-to-end MLOps platform built from scratch using Infrastructure as Code (Terraform), containerization (Docker), orchestration (Kubernetes), and experiment tracking/model registry (MLflow).

## 🏗️ Architecture Overview
* **Infrastructure (IaC):** Terraform-managed AWS environment (VPC, Public/Private Subnets, Internet Gateway, Security Groups, IAM Roles, and S3 Model Registry).
* **Containerization:** Dockerized Python/FastAPI application for model serving.
* **Orchestration:** Kubernetes (K8s) deployments and services for scalable model inference.
* **ML Lifecycle:** MLflow integration for experiment tracking and artifact storage in S3.

## 📂 Repository Structure
```text
mlops_end_to_end_aws/
├── terraform/          # AWS Infrastructure code (Terraform)
├── docker/             # Dockerfiles and application code (FastAPI)
├── kubernetes/         # K8s manifest files (deployments, pods, services)
├── mlflow/             # MLflow tracking and model training scripts
└── scripts/            # Helper automation scripts

