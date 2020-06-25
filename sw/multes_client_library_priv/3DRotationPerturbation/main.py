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

    #df[["age", "balance", "day", "campaign", "pdays", "previous"]] = df[["age", "balance", "day", "campaign", "pdays", "previous"]].round(0)
    #df[["Pregnancies", "Glucose", "BloodPressure", "SkinThickness", "Insulin", "Age"]] = df[["Pregnancies", "Glucose", "BloodPressure", "SkinThickness", "Insulin", "Age"]].round(0)

    #print(df.head())

    xx = df[used_features + [output_feature]]
    print(xx.head())

    print(xx.describe())

    print(xx.nunique())

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
        print("{} {}:\nNumber of mislabeled points out of a total {} points : {}, performance {:05.2f}%\n"
            .format(
                type(model).__name__,
                in_file_path,
                x_test.shape[0],
                (y_test != y_pred).sum(),
                100*(1-(y_test != y_pred).sum()/x_test.shape[0])
        ))

# file_path1 = "bank_labeled.csv"
# file_path2 = "bank_transformed.csv"

# used_features =[
#     "age",
# 	#"job",
# 	#"marital",
# 	#"education",
# 	#"default",
# 	"balance",
# 	#"housing",
# 	#"loan",
# 	#"contact",
# 	"day",
# 	#"month",
# 	#"duration",
# 	"campaign",
# 	"pdays",
# 	"previous",
# 	#"poutcome"
# ]

# output_feature = "y"

# file_path1 = "banknote.csv"
# file_path2 = "banknote_transformed.csv"

# used_features =[
#     "variance",
#     "skewness",
#     "curtosis",
#     "entropy"
# ]

# output_feature = "class"

file_path1 = "diabetes.csv"
file_path2 = "diabetes_transformed.csv"

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
