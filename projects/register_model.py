import mlflow
from mlflow.tracking import MlflowClient

mlflow.set_tracking_uri("http://a53cd1cd2e3f14de883bb55288390054-251161692.eu-west-2.elb.amazonaws.com")
client = MlflowClient()

experiment_name = "smarthome-energy-prediction"
experiment = client.get_experiment_by_name(experiment_name)

if experiment:
    runs = client.search_runs(
        experiment_ids=[experiment.experiment_id],
        order_by=["start_time DESC"],
        max_results=1
    )
    if runs:
        latest_run_id = runs[0].info.run_id
        model_uri = f"runs:/{latest_run_id}/random_forest_energy_model"
        model_name = "SmartHomeEnergyPredictor"
        
        print(f"Registering model as '{model_name}'...")
        result = mlflow.register_model(model_uri=model_uri, name=model_name)
        
        print(f"Transitioning version {result.version} to Staging...")
        client.transition_model_version_stage(
            name=model_name,
            version=result.version,
            stage="Staging",
            archive_existing_versions=True
        )
        print("Success! Model registered and moved to Staging.")