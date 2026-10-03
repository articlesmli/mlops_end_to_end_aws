import mlflow
import mlflow.sklearn
import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error, r2_score
from sklearn.model_selection import train_test_split

# Point directly to your AWS Load Balancer MLflow tracking server
MLFLOW_TRACKING_URI = "http://a53cd1cd2e3f14de883bb55288390054-251161692.us-east-1.elb.amazonaws.com"
mlflow.set_tracking_uri(MLFLOW_TRACKING_URI)
mlflow.set_experiment("smarthome-energy-prediction")

print("Generating synthetic smart home dataset...")
np.random.seed(42)
n_samples = 1000

# Features: temperature, humidity, square_footage, number_of_occupants
temp = np.random.uniform(10, 35, n_samples)
humidity = np.random.uniform(20, 90, n_samples)
sqft = np.random.uniform(800, 3500, n_samples)
occupants = np.random.randint(1, 6, n_samples)

# Target: Energy consumption (kWh) with some noise
energy_kwh = (
    2.5 * temp 
    + 1.2 * humidity 
    + 0.05 * sqft 
    + 15.0 * occupants 
    + np.random.normal(0, 10, n_samples)
)

df = pd.DataFrame({
    'temperature': temp,
    'humidity': humidity,
    'sqft': sqft,
    'occupants': occupants,
    'energy_kwh': energy_kwh
})

X = df[['temperature', 'humidity', 'sqft', 'occupants']]
y = df['energy_kwh']

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Hyperparameters for our model
n_estimators = 100
max_depth = 10

with mlflow.start_run() as run:
    print(f"Starting MLflow run: {run.info.run_id}")
    
    # Log hyperparameters
    mlflow.log_param("model_type", "RandomForestRegressor")
    mlflow.log_param("n_estimators", n_estimators)
    mlflow.log_param("max_depth", max_depth)
    
    # Train model
    model = RandomForestRegressor(n_estimators=n_estimators, max_depth=max_depth, random_state=42)
    model.fit(X_train, y_train)
    
    # Evaluate model
    predictions = model.predict(X_test)
    rmse = np.sqrt(mean_squared_error(y_test, predictions))
    r2 = r2_score(y_test, predictions)
    
    # Log metrics (saved to AWS RDS PostgreSQL)
    mlflow.log_metric("rmse", rmse)
    mlflow.log_metric("r2_score", r2)
    print(f"Model trained! RMSE: {rmse:.4f}, R2 Score: {r2:.4f}")
    
    # Log the trained model artifact (saved to AWS S3)
    mlflow.sklearn.log_model(model, "random_forest_energy_model")
    print("Model artifacts successfully uploaded to AWS S3!")

print("Mock project training run completed successfully!")
