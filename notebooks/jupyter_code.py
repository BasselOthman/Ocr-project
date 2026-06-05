import pandas as pd
import numpy as np
import torch
import torch.nn as nn

from sklearn.impute import SimpleImputer
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import (
    roc_auc_score,
    average_precision_score,
    precision_score,
    recall_score,
    f1_score
)

from torch.utils.data import Dataset, DataLoader, WeightedRandomSampler

import warnings
warnings.filterwarnings("ignore")

DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print("DEVICE:", DEVICE)
# -----
TRAIN_PATH = "/kaggle/input/datasets/emanmuhammed/grad-proj/train_multilabel10_group.csv"
VAL_PATH   = "/kaggle/input/datasets/emanmuhammed/grad-proj/val_multilabel10_group.csv"
TEST_PATH  = "/kaggle/input/datasets/emanmuhammed/grad-proj/test_multilabel10_group.csv"
# -----
train_df = pd.read_csv(TRAIN_PATH)
val_df   = pd.read_csv(VAL_PATH)
test_df  = pd.read_csv(TEST_PATH)

print(len(train_df), len(val_df), len(test_df))
# -----
DISEASE_COLS = [
    "anemia",
    "diabetes",
    "hyperlipidemia",
    "kidney",
    "liver",
    "thyroid"
]

DROP_COLS = [
    "subject_id",
    "hadm_id",
    "charttime"
]
# -----
def make_xy(df):

    Y = df[DISEASE_COLS].fillna(0).astype(int)

    X = df.drop(columns=DISEASE_COLS)

    drop_exist = [c for c in DROP_COLS if c in X.columns]
    X = X.drop(columns=drop_exist)

    # gender → numeric
    if "gender" in X.columns:
        X["gender"] = X["gender"].map({"M":1,"F":0})

    
    X = X.select_dtypes(include=[np.number])

    return X, Y
# -----
X_train_df, Y_train_df = make_xy(train_df)
X_val_df,   Y_val_df   = make_xy(val_df)
X_test_df,  Y_test_df  = make_xy(test_df)

print(X_train_df.shape)
# -----
def add_missing_flags(X):

    X = X.copy()

    for c in X.columns:
        X[c+"_missing"] = X[c].isna().astype(int)

    return X
# -----
X_train_df = add_missing_flags(X_train_df)
X_val_df   = add_missing_flags(X_val_df)
X_test_df  = add_missing_flags(X_test_df)
# -----
print(X_train_df.dtypes)
# -----
imputer = SimpleImputer(strategy="median")

X_train = imputer.fit_transform(X_train_df)
X_val   = imputer.transform(X_val_df)
X_test  = imputer.transform(X_test_df)

scaler = StandardScaler()

X_train = scaler.fit_transform(X_train)
X_val   = scaler.transform(X_val)
X_test  = scaler.transform(X_test)

Y_train = Y_train_df.values
Y_val   = Y_val_df.values
Y_test  = Y_test_df.values
# -----
class TabDataset(Dataset):

    def __init__(self,X,Y):
        self.X = torch.tensor(X,dtype=torch.float32)
        self.Y = torch.tensor(Y,dtype=torch.float32)

    def __len__(self):
        return len(self.X)

    def __getitem__(self,i):
        return self.X[i],self.Y[i]
# -----
none_mask = (Y_train.sum(axis=1)==0)

#focusing on diseased more
weights = np.where(none_mask,0.4,0.6)

sampler = WeightedRandomSampler(
    weights=weights,
    num_samples=len(weights),
    replacement=True
)
# -----

# -----
train_ds = TabDataset(X_train,Y_train)
val_ds   = TabDataset(X_val,Y_val)
test_ds  = TabDataset(X_test,Y_test)

train_loader = DataLoader(
    train_ds,
    batch_size=256,
    sampler=sampler
)

val_loader = DataLoader(val_ds,batch_size=512)
test_loader = DataLoader(test_ds,batch_size=512)
# -----
class MLP(nn.Module):

    def __init__(self,input_dim):

        super().__init__()

        self.net = nn.Sequential(

            nn.Linear(input_dim,256),
            nn.BatchNorm1d(256),
            nn.ReLU(),
            nn.Dropout(0.3),

            nn.Linear(256,128),
            nn.BatchNorm1d(128),
            nn.ReLU(),
            nn.Dropout(0.3),

            nn.Linear(128,6)
        )

    def forward(self,x):
        return self.net(x)
# -----
model = MLP(X_train.shape[1]).to(DEVICE)

optimizer = torch.optim.Adam(
    model.parameters(),
    lr=1e-3
)

criterion = nn.BCEWithLogitsLoss()
# -----
EPOCHS = 20

for epoch in range(EPOCHS):

    model.train()

    total_loss = 0

    for Xb,Yb in train_loader:

        Xb = Xb.to(DEVICE)
        Yb = Yb.to(DEVICE)

        optimizer.zero_grad()

        logits = model(Xb)

        loss = criterion(logits,Yb)

        loss.backward()

        torch.nn.utils.clip_grad_norm_(model.parameters(),1.0)

        optimizer.step()

        total_loss += loss.item()

    print("Epoch",epoch,"loss",total_loss/len(train_loader))
# -----
def predict(loader):

    model.eval()

    preds = []
    trues = []

    with torch.no_grad():

        for Xb,Yb in loader:

            Xb = Xb.to(DEVICE)

            logits = model(Xb)

            prob = torch.sigmoid(logits).cpu().numpy()

            preds.append(prob)
            trues.append(Yb.numpy())

    preds = np.vstack(preds)
    trues = np.vstack(trues)

    return preds,trues
# -----
train_prob,train_true = predict(train_loader)
val_prob,val_true     = predict(val_loader)
test_prob,test_true   = predict(test_loader)
# -----
results = []

for i,d in enumerate(DISEASE_COLS):

    t = test_true[:,i]
    p = test_prob[:,i]

    auc = roc_auc_score(t,p)
    pr  = average_precision_score(t,p)

    pred = (p>0.5).astype(int)

    precision = precision_score(t,pred)
    recall    = recall_score(t,pred)
    f1        = f1_score(t,pred)

    results.append({
        "disease":d,
        "AUC":auc,
        "PR_AUC":pr,
        "precision":precision,
        "recall":recall,
        "F1":f1
    })

results_df = pd.DataFrame(results)

results_df
# -----
import os
import json
import joblib
import torch

SAVE_DIR = "/kaggle/working/nn_balanced_batch_saved"
os.makedirs(SAVE_DIR, exist_ok=True)

# 1) save model weights
torch.save(model.state_dict(), os.path.join(SAVE_DIR, "model_state_dict.pth"))

# 2) save preprocessing objects
joblib.dump(imputer, os.path.join(SAVE_DIR, "imputer.pkl"))
joblib.dump(scaler, os.path.join(SAVE_DIR, "scaler.pkl"))

# 3) save final feature columns AFTER make_xy + add_missing_flags
joblib.dump(list(X_train_df.columns), os.path.join(SAVE_DIR, "feature_columns.pkl"))

# 4) save labels and config
joblib.dump(DISEASE_COLS, os.path.join(SAVE_DIR, "disease_cols.pkl"))
joblib.dump(DROP_COLS, os.path.join(SAVE_DIR, "drop_cols.pkl"))

# 5) save thresholds (you currently use 0.5 for all)
thresholds = {d: 0.5 for d in DISEASE_COLS}
with open(os.path.join(SAVE_DIR, "thresholds.json"), "w") as f:
    json.dump(thresholds, f, indent=2)

# 6) save metadata
metadata = {
    "input_dim": int(X_train.shape[1]),
    "num_outputs": len(DISEASE_COLS),
    "batch_size_train": 256
}
with open(os.path.join(SAVE_DIR, "metadata.json"), "w") as f:
    json.dump(metadata, f, indent=2)

print("Saved files:")
for fn in os.listdir(SAVE_DIR):
    print("-", fn)
# -----
import zipfile
import os

zip_path = "/kaggle/working/nn_balanced_batch_saved.zip"

with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as z:
    for fn in os.listdir(SAVE_DIR):
        full_path = os.path.join(SAVE_DIR, fn)
        z.write(full_path, arcname=fn)

print("ZIP saved to:", zip_path)
# -----
import os
import json
import joblib
import torch
import torch.nn as nn
import pandas as pd
import numpy as np

LOAD_DIR = "/kaggle/working/nn_balanced_batch_saved"

DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")

# load saved preprocessing
imputer = joblib.load(os.path.join(LOAD_DIR, "imputer.pkl"))
scaler = joblib.load(os.path.join(LOAD_DIR, "scaler.pkl"))
feature_columns = joblib.load(os.path.join(LOAD_DIR, "feature_columns.pkl"))
disease_cols = joblib.load(os.path.join(LOAD_DIR, "disease_cols.pkl"))
drop_cols = joblib.load(os.path.join(LOAD_DIR, "drop_cols.pkl"))

with open(os.path.join(LOAD_DIR, "metadata.json"), "r") as f:
    metadata = json.load(f)

with open(os.path.join(LOAD_DIR, "thresholds.json"), "r") as f:
    thresholds = json.load(f)

print("Loaded successfully.")
print("Input dim:", metadata["input_dim"])
print("Diseases:", disease_cols)
# -----
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

            nn.Linear(128, 6)
        )

    def forward(self, x):
        return self.net(x)

model = MLP(metadata["input_dim"]).to(DEVICE)
model.load_state_dict(torch.load(os.path.join(LOAD_DIR, "model_state_dict.pth"), map_location=DEVICE))
model.eval()

print("Model loaded.")
# -----
def make_xy_inference(df, disease_cols, drop_cols):
    df = df.copy()

   
    df = df.drop(columns=[c for c in disease_cols if c in df.columns], errors="ignore")

    # drop cols
    drop_exist = [c for c in drop_cols if c in df.columns]
    df = df.drop(columns=drop_exist, errors="ignore")

    # gender -> numeric
    if "gender" in df.columns:
        df["gender"] = df["gender"].map({"M": 1, "F": 0})

    # keep only numeric
    df = df.select_dtypes(include=[np.number])

    return df


def add_missing_flags_inference(X):
    X = X.copy()

    original_cols = list(X.columns)
    for c in original_cols:
        X[c + "_missing"] = X[c].isna().astype(int)

    return X
# -----
def predict_dataframe(df_raw):
    df = df_raw.copy()

    # نفس preprocessing
    X_df = make_xy_inference(df, disease_cols, drop_cols)
    X_df = add_missing_flags_inference(X_df)

    # لازم نفس الأعمدة بالظبط
    for c in feature_columns:
        if c not in X_df.columns:
            X_df[c] = np.nan

    X_df = X_df[feature_columns]

    # impute + scale
    X_np = imputer.transform(X_df)
    X_np = scaler.transform(X_np)

    X_tensor = torch.tensor(X_np, dtype=torch.float32).to(DEVICE)

    with torch.no_grad():
        logits = model(X_tensor)
        probs = torch.sigmoid(logits).cpu().numpy()

    prob_df = pd.DataFrame(probs, columns=disease_cols)

    # apply thresholds
    pred_df = prob_df.copy()
    for d in disease_cols:
        pred_df[d + "_pred"] = (pred_df[d] >= thresholds[d]).astype(int)

    pred_df["none_pred"] = (pred_df[[d + "_pred" for d in disease_cols]].sum(axis=1) == 0).astype(int)

    return pred_df
# -----
TEST_PATH = "/kaggle/input/datasets/emanmuhammed/grad-proj/test_multilabel10_group.csv"
test_df = pd.read_csv(TEST_PATH)


# -----
 # predictions
pred_df = predict_dataframe(test_df)

# نخلي label names واضحة
pred_df_cols = [c + "_prob" for c in DISEASE_COLS]
pred_df_prob = pred_df[DISEASE_COLS].copy()
pred_df_prob.columns = pred_df_cols

pred_df_labels = pred_df[[d + "_pred" for d in DISEASE_COLS] + ["none_pred"]]

# merge مع original test
result_df = pd.concat([test_df.reset_index(drop=True), pred_df_prob, pred_df_labels], axis=1)

result_df.head()
# -----
from sklearn.metrics import accuracy_score, f1_score, precision_score, recall_score

metrics = []

for d in DISEASE_COLS:
    y_true = test_df[d]
    y_pred = result_df[d + "_pred"]

    acc = accuracy_score(y_true, y_pred)
    f1  = f1_score(y_true, y_pred)
    prec = precision_score(y_true, y_pred)
    rec  = recall_score(y_true, y_pred)

    metrics.append([d, acc, prec, rec, f1])

metrics_df = pd.DataFrame(metrics, columns=["disease", "accuracy", "precision", "recall", "f1"])

metrics_df
# -----
total_correct = 0
total_all = 0

for d in DISEASE_COLS:
    total_correct += (test_df[d] == result_df[d + "_pred"]).sum()
    total_all += len(test_df)

overall_accuracy = total_correct / total_all

print("Overall accuracy:", overall_accuracy)
# -----
exact_match = (test_df[DISEASE_COLS].values == result_df[[d + "_pred" for d in DISEASE_COLS]].values).all(axis=1).mean()

print("Exact match accuracy:", exact_match)
# -----
SAVE_PATH = "/kaggle/working/test_predictions_full.csv"
result_df.to_csv(SAVE_PATH, index=False)

print("Saved to:", SAVE_PATH)
# -----
for d in DISEASE_COLS:
    result_df[d + "_correct"] = (test_df[d] == result_df[d + "_pred"]).astype(int)

result_df.head()
# -----
