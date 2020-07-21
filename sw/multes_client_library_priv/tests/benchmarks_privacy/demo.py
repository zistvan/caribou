import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import warnings
from sklearn.model_selection import train_test_split
from sklearn.naive_bayes import GaussianNB
from sklearn.tree import DecisionTreeClassifier
from sklearn.neighbors import KNeighborsClassifier
from sklearn.svm import SVC
from sklearn.gaussian_process import GaussianProcessClassifier
from sklearn.ensemble._forest import RandomForestClassifier
from sklearn.neural_network import MLPClassifier
from sklearn.ensemble._weight_boosting import AdaBoostClassifier
from sklearn.discriminant_analysis import QuadraticDiscriminantAnalysis
from sklearn.metrics import confusion_matrix
from sklearn.preprocessing._data import StandardScaler
from sklearn.exceptions import ConvergenceWarning
warnings.filterwarnings("ignore", category=ConvergenceWarning)

pert = 0
orig = 0

used_features = []
output_feature = []

def set(host, file, key):
    os.system("./bench -r=1 -w=true -p=false -m=s -h=" + host + " -f=" + file + " -k=" + key)

def getp(host, file, key):
    os.system("./bench -r=1 -w=true -p=false -m=p -h=" + host + " -f=" + file + " -k=" + key)

    csv_path = ""
    if "banknote" in file:
        csv_path = "banknote_s_pert.csv"
    elif "diabetes" in file:
        csv_path = "diabetes_pert.csv"
    elif "bank" in file:
        csv_path = "bank_labeled_pert.csv"

    global pert
    pert = pd.read_csv(csv_path)

def get(host, file, key):
    os.system("./bench -r=1 -w=true -p=false -m=n -h=" + host + " -f=" + file + " -k=" + key)

    csv_path = ""
    if "banknote" in file:
        csv_path = "banknote_s_orig.csv"
    elif "diabetes" in file:
        csv_path = "diabetes_orig.csv"
    elif "bank" in file:
        csv_path = "bank_labeled_orig.csv"

    global orig
    orig = pd.read_csv(csv_path)

def compare_classifiers(file):
    if "banknote" in file:
        used_features =["Variance", "Skewness", "Curtosis", "Entropy"]
        output_feature = "Class"
        orig = pd.read_csv("banknote_s_orig.csv")
        pert = pd.read_csv("banknote_s_pert.csv")
    elif "diabetes" in file:
        used_features =["Pregnancies", "Glucose", "BloodPressure", "SkinThickness", "Insulin", "BMI", "DiabetesPedigreeFunction", "Age"]
        output_feature = "Outcome"
        orig = pd.read_csv("diabetes_orig.csv")
        pert = pd.read_csv("diabetes_pert.csv")
    elif "bank" in file:
        used_features =["Age", "Job", "Marital", "Education", "Default", "Balance", "Housing", "Loan", "Contact", "Day", "Month", "Duration",
            "Campaign", "Pdays", "Previous", "Poutcome"]
        output_feature = "Y"
        orig = pd.read_csv("bank_labeled_orig.csv")
        pert = pd.read_csv("bank_labeled_pert.csv")
    
    sc = StandardScaler()
    orig_scaled = orig.copy()
    pert_scaled = pert.copy()
    orig_scaled[used_features] = sc.fit_transform(orig_scaled[used_features])
    pert_scaled[used_features] = sc.fit_transform(pert_scaled[used_features])

    y_orig = orig_scaled[output_feature]
    x_orig = orig_scaled.drop([output_feature], axis=1)[used_features]
    y_pert = pert_scaled[output_feature]
    x_pert = pert_scaled.drop([output_feature], axis=1)[used_features]

    x_train_orig, x_test_orig, y_train_orig, y_test_orig = train_test_split(x_orig, y_orig, test_size=0.33, random_state=42)
    x_train_pert, x_test_pert, y_train_pert, y_test_pert = train_test_split(x_pert, y_pert, test_size=0.33, random_state=42)

    models = [DecisionTreeClassifier(),
              KNeighborsClassifier(),
              SVC(),
              GaussianProcessClassifier(),
              RandomForestClassifier(),
              MLPClassifier(),
              AdaBoostClassifier(),
              QuadraticDiscriminantAnalysis(),
              GaussianNB()]

    fig = plt.figure()
    for idx, model in enumerate(models):
        model.fit(x_train_orig, y_train_orig)
        y_pred_orig = model.predict(x_test_orig)
        tn_orig, fp_orig, fn_orig, tp_orig = confusion_matrix(y_test_orig, y_pred_orig).ravel()
        model.fit(x_train_pert, y_train_pert)
        y_pred_pert = model.predict(x_test_pert)
        tn_pert, fp_pert, fn_pert, tp_pert = confusion_matrix(y_test_pert, y_pred_pert).ravel()

        accuracy_orig = (tp_orig+tn_orig)/(tp_orig+tn_orig+fp_orig+fn_orig)*100
        accuracy_pert = (tp_pert+tn_pert)/(tp_pert+tn_pert+fp_pert+fn_pert)*100
        precision_orig = tp_orig/(tp_orig+fp_orig)*100
        precision_pert = tp_pert/(tp_pert+fp_pert)*100
        recall_orig = tp_orig/(tp_orig+fn_orig)*100
        recall_pert = tp_pert/(tp_pert+fn_pert)*100

        print(("\n{}:\n Accuracy original  | masked = {:5.2f} | {:5.2f}\n"+
                      " Precision original | masked = {:5.2f} | {:5.2f}\n"+
                      " Recall original    | masked = {:5.2f} | {:5.2f}")
            .format(type(model).__name__, accuracy_orig, accuracy_pert, precision_orig, precision_pert, recall_orig, recall_pert))

        plot_data = [[accuracy_orig, precision_orig, recall_orig], [accuracy_pert, precision_pert, recall_pert]]
        X = np.arange(3)
        ax = fig.add_subplot(3, 3, idx+1)
        ax.bar(X + 0.00, plot_data[0], color = 'b', width = 0.25, label="Original data")
        ax.bar(X + 0.25, plot_data[1], color = 'g', width = 0.25, label="Masked data")
        ax.set_title(type(model).__name__)
        ax.set_xticks(X)
        ax.set_xticklabels(["Accuracy", "Precision", "Recall"])
    
    plt.tight_layout()
    plt.legend()
    plt.show()
