# Production-Grade MLflow Platform on AWS EKS

An enterprise-ready MLOps tracking and model registry platform deployed on **AWS EKS** (Elastic Kubernetes Service), backed by **AWS RDS (PostgreSQL)** for backend metadata storage, and **AWS S3** for secure, scalable artifact storage.

---

## Architecture Overview


```

+-------------------------------------------------------------------+
|                        AWS Cloud (us-east-1)                      |
|                                                                   |
|   +--------------------+     +---------------------------------+  |
|   | AWS EKS Cluster    |     | AWS RDS PostgreSQL              |  |
|   | (t3.small nodes)   | --> | (Backend Store & Model Registry)|  |
|   +--------------------+     +---------------------------------+  |
|             |                                                     |
|             v                                                     |
|   +--------------------+     +---------------------------------+  |
|   | AWS Load Balancer  |     | AWS S3 Bucket                   |  |
|   | (External Traffic) | --> | (Artifact Storage Root)         |  |
|   +--------------------+     +---------------------------------+  |
+-------------------------------------------------------------------+

```

---

## 🚀 Tech Stack

* **Orchestration**: Kubernetes, AWS EKS (`t3.small`)
* **Tracking Server**: MLflow (`v2.11.1`) running via Gunicorn in Docker
* **Backend Database**: AWS RDS PostgreSQL (stores experiments, runs, parameters, metrics, and registry metadata)
* **Artifact Store**: Amazon S3 (`ml-model-registry-store-2026`)
* **Language & Tooling**: Python 3.10, Boto3, Docker, kubectl, Terraform

---

## 📁 Repository Structure

```text
ml_infra/
├── docker/
│   └── Dockerfile                 # Custom MLflow container image
├── kubernetes/
│   └── ml_platform.yaml           # Consolidated EKS Deployment & LoadBalancer Service
├── mlflow/
│   └── mlflow_db_secret.yaml      # Database connection credentials secret
├── projects/
│   ├── train_model.py             # SmartHome Energy Predictor training script
│   └── register_model.py          # Model registration & staging script
└── terraform/
    └── main.tf                    # Infrastructure provisioning (EKS, RDS, S3)

```

---

## ⚙️ Key Configuration Highlights

1. **Kubernetes Health Probes**: Configured liveness and readiness probes to map to the root path (`/`) instead of `/health` to maintain stable zero-downtime deployments without container crash loops.
2. **Environment Constraints**: Built using Python 3.10 with `mlflow==2.11.1`, pinning `setuptools<74` and `packaging<24` for seamless dependency resolution.

---

## 🛠️ Getting Started & Deployment

### 1. Apply Kubernetes Manifests

Deploy the MLflow tracking server and expose it via the AWS LoadBalancer service:

```bash
kubectl apply -f kubernetes/mlflow_db_secret.yaml
kubectl apply -f kubernetes/ml_platform.yaml

```

Verify that pods are running successfully:

```bash
kubectl get pods

```

### 2. Train and Log Models

Run the training script to generate synthetic data, train a `RandomForestRegressor`, log metrics/parameters to RDS, and push model artifacts to S3:

```bash
cd projects/
python3 train_model.py

```

### 3. Register and Stage Models

Run the registration script to promote your latest run into the MLflow Model Registry and transition it to the `Staging` stage:

```bash
python3 register_model.py

```

---

## 🌐 Accessing the UI

Retrieve your external AWS LoadBalancer URL via kubectl:

```bash
kubectl get svc mlflow-server-service

```

Open the LoadBalancer endpoint in your browser to view experiments, compare run performance metrics, and manage registered models.

```

