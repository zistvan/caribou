import pandas as pd
import matplotlib.pyplot as plt

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

def test(in_file_path, used_features):
    df = pd.read_csv(in_file_path)

    df[["Pregnancies", "Glucose", "BloodPressure", "SkinThickness", "Insulin", "Age"]] = df[["Pregnancies", "Glucose", "BloodPressure", "SkinThickness", "Insulin", "Age"]].round(0)

    # df = df.round(0)

    print(df.head())

    df.hist(column=used_features, bins=100)

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

# test(file_path1, used_features)
# test(file_path2, used_features)

# file_path1 = "banknote.csv"
# file_path2 = "banknote_transformed.csv"
# file_path3 = "banknote_noisy.csv"

# used_features =[
#     "variance",
#     "skewness",
#     "curtosis",
#     "entropy"
# ]

file_path1 = "diabetes.csv"
file_path2 = "diabetes_transformed.csv"
file_path3 = "diabetes_noisy.csv"

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

test(file_path1, used_features)
test(file_path2, used_features)

plt.show()
