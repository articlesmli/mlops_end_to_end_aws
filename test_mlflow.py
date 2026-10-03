import mlflow
import os

# Point MLflow to your local port-forwarded server
mlflow.set_tracking_uri("http://localhost:8080")

# Set or create an experiment name
mlflow.set_experiment("aws-eks-production-test")

# Start an MLflow run
with mlflow.start_run() as run:
    print(f"Starting run ID: {run.info.run_id}")
    
    # Log a parameter
    mlflow.log_param("model_type", "linear_regression")
    mlflow.log_param("environment", "aws-eks-free-tier")
    
    # Log a metric
    mlflow.log_metric("rmse", 0.42)
    mlflow.log_metric("accuracy", 0.91)
    
    # Create a dummy artifact file to test S3 upload
    with open("sample_artifact.txt", "w") as f:
        f.write("Hello from our production MLflow server on AWS EKS with S3 storage!")
    
    # Log the artifact to S3 via MLflow
    mlflow.log_artifact("sample_artifact.txt")
    
    print("Successfully logged parameters, metrics, and artifacts to your AWS infrastructure!")

# Clean up local dummy file
if os.path-exists("sample_artifact.txt"):
    os.remove("sample_artifact.txt")
