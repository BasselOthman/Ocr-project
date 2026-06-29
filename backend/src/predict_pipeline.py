import json
import os
import re

import joblib
import numpy as np
import pandas as pd
import torch
import torch.nn as nn

# ================= PATH CONFIGURATION =================
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# BASE_DIR is .../backend. The models folder is located inside backend/
LOAD_DIR = os.environ.get(
    "MODEL_DIR", os.path.join(BASE_DIR, "nn_balanced_batch_saved")
)
DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")


# ================= MODEL DEFINITION =================
class MLP(nn.Module):
    def __init__(self, input_dim):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(input_dim, 256),
            nn.BatchNorm1d(256),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(256, 128),
            nn.BatchNorm1d(128),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(128, 6),
        )

    def forward(self, x):
        return self.net(x)


# ================= MAPPING CONFIGURATION =================
# Maps our standardized OCR Test_Codes to the ML model's expected Feature Columns
OCR_TO_ML_MAPPING = {
    "HBA1C": "% Hemoglobin A1c",
    "ALT": "Alanine Aminotransferase (ALT)",
    "ALB": "Albumin",
    "ALP": "Alkaline Phosphatase",
    "AST": "Asparate Aminotransferase (AST)",
    "DBIL": "Bilirubin, Direct",
    "BIL": "Bilirubin, Total",
    "HDL": "Cholesterol, HDL",
    "LDL": "Cholesterol, LDL, Calculated",  # Or Measured, map to Calculated by default
    "CHOL": "Cholesterol, Total",
    "CREAT": "Creatinine",
    "FERRITIN": "Ferritin",
    "GLU": "Glucose",
    "HCT": "Hematocrit",
    "HGB": "Hemoglobin",
    "MCV": "MCV",
    "MCH": "MCH",
    "MCHC": "MCHC",
    "PLT": "Platelet Count",
    "TP": "Protein, Total",
    "RDW": "RDW",
    "RBC": "Red Blood Cells",
    "TSH": "Thyroid Stimulating Hormone",
    "T4": "Thyroxine (T4)",
    "TRIG": "Triglycerides",
    "T3": "Triiodothyronine (T3)",
    "UREA": "Urea Nitrogen",
    "WBC": "WBC Count",
}


# ================= PIPELINE CLASS =================
class PredictionPipeline:
    def __init__(self):
        self.is_loaded = False
        try:
            print(f"Loading ML models from {LOAD_DIR} on {DEVICE}...")
            self.imputer = joblib.load(os.path.join(LOAD_DIR, "imputer.pkl"))
            self.scaler = joblib.load(os.path.join(LOAD_DIR, "scaler.pkl"))
            self.feature_columns = joblib.load(
                os.path.join(LOAD_DIR, "feature_columns.pkl")
            )
            self.disease_cols = joblib.load(os.path.join(LOAD_DIR, "disease_cols.pkl"))
            self.drop_cols = joblib.load(os.path.join(LOAD_DIR, "drop_cols.pkl"))

            with open(os.path.join(LOAD_DIR, "metadata.json"), "r") as f:
                self.metadata = json.load(f)

            with open(os.path.join(LOAD_DIR, "thresholds.json"), "r") as f:
                self.thresholds = json.load(f)

            self.model = MLP(self.metadata["input_dim"]).to(DEVICE)
            self.model.load_state_dict(
                torch.load(
                    os.path.join(LOAD_DIR, "model_state_dict.pth"), map_location=DEVICE
                )
            )
            self.model.eval()
            self.is_loaded = True
            print("ML pipeline successfully loaded.")
        except Exception as e:
            print(f"Failed to load ML models: {e}")

    def add_missing_flags_inference(self, X):
        X = X.copy()
        original_cols = list(X.columns)
        for c in original_cols:
            X[c + "_missing"] = X[c].isna().astype(int)
        return X

    def parse_float_value(self, raw_value_str):
        if not raw_value_str:
            return np.nan
        # e.g., "38% (1.63 abs)", "15.5", "< 7"
        numbers = re.findall(r"\d+\.\d+|\d+", str(raw_value_str))
        if numbers:
            return float(numbers[0])
        return np.nan

    def predict(self, ocr_results_list, patient_demographics=None):
        if not self.is_loaded:
            return {"error": "ML pipeline failed to load."}

        print("Starting prediction on patient data...")

        # 1. Build a dict of the extracted numerical values
        features_dict = {}
        for res in ocr_results_list:
            test_code = res.get("Test_Code")
            val_str = res.get("Value", "")
            if test_code in OCR_TO_ML_MAPPING:
                ml_key = OCR_TO_ML_MAPPING[test_code]
                num_val = self.parse_float_value(val_str)
                # Take first observation if duplicates
                if ml_key not in features_dict and not np.isnan(num_val):
                    features_dict[ml_key] = num_val

        # 2. Add demographics if passed or leave blank (they will be imputed)
        if patient_demographics:
            if "gender" in patient_demographics:
                features_dict["gender"] = (
                    1 if patient_demographics["gender"].upper() == "M" else 0
                )
            if "anchor_age" in patient_demographics:
                features_dict["anchor_age"] = patient_demographics["anchor_age"]
            if "height_cm" in patient_demographics:
                features_dict["height_cm"] = patient_demographics["height_cm"]
            if "weight_kg" in patient_demographics:
                features_dict["weight_kg"] = patient_demographics["weight_kg"]

        # 3. Create a 1-row DataFrame
        df = pd.DataFrame([features_dict])

        # 4. Generate missing flags and fill missing columns with NaN
        df = self.add_missing_flags_inference(df)

        for c in self.feature_columns:
            if c not in df.columns:
                df[c] = np.nan

        # 5. Order columns identically to training feature columns
        df = df[self.feature_columns]

        # 6. Preprocessing: Impute and Scale
        X_np = self.imputer.transform(df)
        X_np = self.scaler.transform(X_np)

        # 7. Model Inference & Explainability (Saliency Gradients)
        X_tensor = torch.tensor(X_np, dtype=torch.float32, requires_grad=True).to(
            DEVICE
        )

        logits = self.model(X_tensor)
        probs = torch.sigmoid(logits)[0]

        results = {}
        for i, d in enumerate(self.disease_cols):
            probability = float(probs[i].item())
            is_positive = bool(probability >= self.thresholds.get(d, 0.5))

            # Calculate gradient (feature attribution) for this disease
            if X_tensor.grad is not None:
                X_tensor.grad.zero_()
            self.model.zero_grad()
            probs[i].backward(retain_graph=True)

            grads = X_tensor.grad.cpu().numpy()[0]

            # Compute a simple sensitivity score: gradient * deviation from mean (which is X_np since it is StandardScaled)
            saliency = grads * X_np[0]

            # Extract top 3 drivers (features that push probability up the most)
            drivers = {}
            for j, col_name in enumerate(self.feature_columns):
                # Filter out missing flags and demographics for pure lab-based clinical drivers
                if "_missing" not in col_name and col_name not in [
                    "gender",
                    "anchor_age",
                    "height_cm",
                    "weight_kg",
                ]:
                    # Ensure standard float
                    if not np.isnan(saliency[j]) and saliency[j] > 0:
                        drivers[col_name] = float(saliency[j])

            # Sort by contribution (descending)
            sorted_drivers = dict(
                sorted(drivers.items(), key=lambda item: item[1], reverse=True)[:3]
            )

            results[d] = {
                "probability": round(probability, 4),
                "is_positive": is_positive,
                "drivers": sorted_drivers,
            }

        return results


# Expose a global pipeline instance
_pipeline_instance = None


def get_pipeline():
    global _pipeline_instance
    if _pipeline_instance is None:
        _pipeline_instance = PredictionPipeline()
    return _pipeline_instance
