import pandas as pd
from sklearn.preprocessing import LabelEncoder
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

# le = LabelEncoder()
# df["job"] = le.fit_transform(df["job"])
# df["marital"] = le.fit_transform(df["marital"])
# df["education"] = le.fit_transform(df["education"])
# df["default"] = le.fit_transform(df["default"])
# df["housing"] = le.fit_transform(df["housing"])
# df["loan"] = le.fit_transform(df["loan"])
# df["contact"] = le.fit_transform(df["contact"])
# df["month"] = le.fit_transform(df["month"])
# df["poutcome"] = le.fit_transform(df["poutcome"])
# df["y"] = le.fit_transform(df["y"])

# df.to_csv ("bank_labeled.csv", index = None, header=True)

def test(in_file_path, used_features, output_feature):
    df = pd.read_csv(in_file_path)

    xx = df[used_features + [output_feature]]
    xx[used_features] = xx[used_features].round(0)
    print(xx.head())
    print(xx.describe())
    print(xx.nunique())

    sc = StandardScaler()
    df[used_features] = sc.fit_transform(df[used_features])

    y = df[output_feature]
    x = df.drop([output_feature], axis=1)[used_features]

    x_train, x_test, y_train, y_test = train_test_split(x, y, test_size=0.33, random_state=42)

    models = [GaussianNB(),
              DecisionTreeClassifier(),
              KNeighborsClassifier(),
              SVC(),
              GaussianProcessClassifier(),
              RandomForestClassifier(),
              MLPClassifier(),
              AdaBoostClassifier(),
              QuadraticDiscriminantAnalysis()]

    for model in models:
        model.fit(x_train, y_train)
        y_pred = model.predict(x_test)
        tn, fp, fn, tp = confusion_matrix(y_test, y_pred).ravel()
        print("{} {}:\n {}\n Accuracy = {:5.4f}\n Precision = {:5.4f}\n Recall = {:5.4f}"
            .format(
                type(model).__name__,
                in_file_path,
                (tn, fp, fn, tp),
                (tp+tn)/(tp+tn+fp+fn),
                tp/(tp+fp),
                tp/(tp+fn)
        ))

# file_path1 = "bank_labeled.csv"
# file_path2 = "bank_labeled_fpga.csv"

# used_features =[
#     "Age",
# 	"Job",
# 	"Marital",
# 	"Education",
# 	"Default",
# 	"Balance",
# 	"Housing",
# 	"Loan",
# 	"Contact",
# 	"Day",
# 	"Month",
# 	"Duration",
# 	"Campaign",
# 	"Pdays",
# 	"Previous",
# 	"Poutcome"
# ]

# output_feature = "Y"

# file_path1 = "banknote_s.csv"
# file_path2 = "banknote_s_fpga.csv"

# used_features =[
#     "Variance",
#     "Skewness",
#     "Curtosis",
#     "Entropy"
# ]

# output_feature = "Class"

file_path1 = "diabetes.csv"
file_path2 = "diabetes_fpga.csv"

used_features =[
    "Pregnancies",
	"Glucose",
	"BloodPressure",
	"SkinThickness",
	"Insulin",
	"BMI",
	"DiabetesPedigreeFunction",
	"Age"
]

output_feature = "Outcome"

test(file_path1, used_features, output_feature)
test(file_path2, used_features, output_feature)
