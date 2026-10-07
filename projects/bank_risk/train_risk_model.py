import mlflow
import mlflow.sklearn
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, roc_auc_score, precision_score, recall_score

# Point to your remote AWS EKS MLflow tracking server LoadBalancer URI
# (Make sure to replace this with your actual LoadBalancer IP)
MLFLOW_TRACKING_URI = "http://<YOUR-EKS-LOADBALANCER-IP>"
mlflow.set_tracking_uri(MLFLOW_TRACKING_URI)

# Set experiment for banking risk
mlflow.set_experiment("bank-credit-risk-scoring")

def generate_credit_risk_data(n_samples=3000):
    """Simulates retail banking loan applicant data for credit risk assessment."""
    np.random.seed(42)
    credit_score = np.random.normal(loc=680, scale=60, size=n_samples).clip(500, 850)
    annual_income = np.random.exponential(scale=65000, size=n_samples) + 20000
    loan_amount = np.random.exponential(scale=15000, size=n_samples) + 5000
    debt_to_income = np.random.uniform(0.1, 0.55, size=n_samples)
    employment_length = np.random.randint(0, 20, size=n_samples)
    
    # Risk default logic: Lower credit score, higher DTI, and higher loan burden increase default probability
    risk_score = (
        (credit_score < 620).astype(int) * 3 +
        (debt_to_income > 0.4).astype(int) * 2.5 +
        (loan_amount / annual_income > 0.4).astype(int) * 2 -
        (employment_length > 5).astype(int) * 1.5
    )
    probabilities = 1 / (1 + np.exp(-1 * (risk_score - 1.5)))
    is_default = (np.random.random(n_samples) < probabilities).astype(int)
    
    df = pd.DataFrame({
        "credit_score": credit_score,
        "annual_income": annual_income,
        "loan_amount": loan_amount,
        "debt_to_income": debt_to_income,
        "employment_length": employment_length,
        "is_default": is_default
    })
    return df

if __name__ == "__main__":
    print("Generating retail banking credit risk dataset...")
    df = generate_credit_risk_data()
    
    X = df.drop("is_default", axis=1)
    y = df["is_default"]
    
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.25, random_state=42)
    
    n_estimators = 150
    max_depth = 5
    
    print("Training Bank Credit Risk Default Classifier...")
    with mlflow.start_run() as run:
        model = RandomForestClassifier(
            n_estimators=n_estimators,
            max_depth=max_depth,
            random_state=42
        )
        model.fit(X_train, y_train)
        
        # Predictions & Evaluations
        preds = model.predict(X_test)
        pred_probs = model.predict_proba(X_test)[:, 1]
        
        acc = accuracy_score(y_test, preds)
        precision = precision_score(y_test, preds, zero_division=0)
        recall = recall_score(y_test, preds, zero_division=0)
        roc_auc = roc_auc_score(y_test, pred_probs)
        
        # Log parameters to RDS metadata backend
        mlflow.log_params({
            "model_type": "RandomForestClassifier",
            "n_estimators": n_estimators,
            "max_depth": max_depth,
            "domain": "credit_risk_scoring"
        })
        
        # Log core banking risk metrics
        mlflow.log_metrics({
            "accuracy": acc,
            "precision": precision,
            "recall": recall,
            "roc_auc": roc_auc
        })
        
        # Log model binary directly to S3 and register model
        mlflow.sklearn.log_model(
            sk_model=model,
            artifact_path="credit-risk-model",
            registered_model_name="BankCreditRiskModel"
        )
        
        print(f"Credit Risk Model Training Complete! Run ID: {run.info.run_id}")
        print(f"Metrics -> Accuracy: {acc:.3f} | ROC-AUC: {roc_auc:.3f}")
