import numpy as np
import pandas as pd
import pickle 
import streamlit as st
import matplotlib.pyplot as plt
import asyncio
import aiohttp

import xgboost as xgb

from sklearn.model_selection import train_test_split

import os


loop = asyncio.new_event_loop()
asyncio.set_event_loop(loop)

cwd = os.getcwd().replace('\\','/') #current working directory

file = pd.read_csv('C:/Users/andrz/Desktop/ISA/Projekt/jdszr6-grupa-bez-nazwy/ML_project/insurance.csv')

file['user_ID'] = pd.DataFrame(file.index).astype(int)
file = file[['user_ID', 'age', 'sex', 'bmi', 'children', 'smoker', 'region', 'charges']]

file_dummies = pd.get_dummies(file[['sex', 'smoker', 'region']])
file_dummies['user_ID'] = file['user_ID']

file = pd.merge(file, file_dummies, on='user_ID')
file = file[['user_ID', 'age', 'sex_female', 'sex_male', 'bmi', 'children', 'smoker_yes', 'region_northeast', 'region_northwest', 'region_southeast', 'region_southwest', 'charges']]
file = file.sort_values(by='user_ID')
file = file[['age', 'sex_female', 'sex_male', 'bmi', 'children', 'smoker_yes', 'region_northeast', 'region_northwest', 'region_southeast', 'region_southwest', 'charges']]

X = file.drop(columns=['charges'], axis=1)
y = file['charges']

X_train, X_test, y_train, y_test = train_test_split(X,y, train_size=0.7, random_state=42)
y_train_sqrt=np.sqrt(y_train)

model_v2=xgb.XGBRegressor( base_score=0.5, booster='gbtree', colsample_bylevel=1,
             colsample_bynode=1, colsample_bytree=0.7, enable_categorical=False,
             gamma=0.01, gpu_id=-1, importance_type=None,
             interaction_constraints='', learning_rate=0.05, max_delta_step=0,
             max_depth=3, min_child_weight=1,
             monotone_constraints='()', n_estimators=150, n_jobs=8,
             num_parallel_tree=1, predictor='auto', random_state=0, reg_alpha=0,
             reg_lambda=1, scale_pos_weight=1, subsample=1, tree_method='exact',
             validate_parameters=1, verbosity=None)

model_v2.fit(X_train.to_numpy(),y_train_sqrt.to_numpy())

sum_charges = round(y_test.sum(),2)
no_records = len(y_test)
pop = 10*(no_records/0.3)
min_rate = round(sum_charges / pop , 2)
earn_rate_v = round(1.12 * min_rate, 2)



def predict_chance(model, df_pred):
    prediction = round(float(model.predict(df_pred))**2,2) #predictions using our model
    return prediction 

def assign_to_group(df_pred, pred): #assign client to group according to charges value
    groups = ["1st - economical", "2nd - optimal", "3rd - exclusive"]
    limit_1 = float(df_pred['age']) * 295 
    limit_2 = float(df_pred['age']) * 295 + 20000
    if float(pred) < limit_1:
        group = groups[0]
    elif float(pred) < limit_2:
        group = groups[1]
    else:
        group = groups[2]
    return group

def offer_insurance_rate(df_pred, pred):
    # discounts = ['6%', '3%', '2%']
    limit_1 = float(df_pred['age']) * 295 
    limit_2 = float(df_pred['age']) * 295 + 20000
    if float(pred) < limit_1:
        rate = round(0.94 * earn_rate_v,2)
    elif float(pred) < limit_2:
        rate = round(0.97 * earn_rate_v,2)
    else:
        rate = round(0.98 * earn_rate_v,2)
    return rate

def value_on_hist(target, values):
    bins = 100
    plt.rcParams['axes.facecolor'] = 'none'
    plt.grid(color="gray", alpha=0.25, linestyle='dashed')
    p = values.hist(bins=bins, alpha=0.33)
    bin_width = (values.max() - values.min()) /bins
    bin_id = int(target/bin_width)-1
    plt.plot([target,target], [1,70], "o--", color='black')
    plt.xlabel("charges")
    plt.ylabel("quantity / density")
    plt.annotate(f"      {target} \nClient's charge value is here", [target, 35], 
                    font={'size':14, 'family':'courier new', 'weight':'bold'},
                    color = "red", rotation = 90, verticalalignment = 'center', horizontalalignment = 'center')

def main():
   
    html_temp="""
        <div>
        <h1><font size = '8' color = 'green'><center><strong>Health Insurance Prediction</strong></center></font></h1>
        <h2><font size = '5'><center>Calculation of health insurance charge value <br> and health insurance ratio</font></center></h2>
        <h3><font size = '4' color ='gold'><center>Single coverage of health insurance is 557.50 $ per month. <br> Our company can propose better offer for our clients.</center></color></font></h3> 
        </div>
        """
    st.markdown(html_temp,unsafe_allow_html=True) #a simple html 
    age=st.select_slider("Enter your age", range(120))
    pass
    sex=st.selectbox("Select Your gender", ['male', 'female'])
    pass
    weight=st.select_slider("Enter Your weight [kg]", range(5,250))
    pass
    height=st.select_slider("Enter Your height [m]", range(50,250))
    pass
    children = st.selectbox('How many childrens do you have?', range(10))
    pass
    smoker=st.selectbox('Are You currently smoking?', ['yes', 'no']) 
    pass
    region=st.selectbox('Enter Your region', ['southeast', 'northeast', 'southwest', 'nothwest'])
    pass
    bmi = weight / ((height/100)**2)

    

    df_pred = pd.DataFrame(data=[[
                                age,
                                (lambda x: 1 if x == 'male' else 0)(sex),
                                (lambda x: 1 if x == 'female' else 0)(sex),
                                bmi,
                                children,
                                (lambda x: 1 if x == 'yes' else 0)(smoker),
                                (lambda x: 1 if x == 'northeast' else 0)(region),
                                (lambda x: 1 if x == 'northwest' else 0)(region),
                                (lambda x: 1 if x == 'southeast' else 0)(region),
                                (lambda x: 1 if x == 'southwest' else 0)(region)
                                ]],
                            columns = X.columns)

    prediction = ""
    group = ""
    rate =""

    if st.button("Predict"): #result will be displayed if button is pressed
        prediction = predict_chance(model_v2, df_pred)
        group = assign_to_group(df_pred, prediction)
        rate = offer_insurance_rate(df_pred, prediction)
        
        st.success("The predicted value of client's charges is: {}".format(prediction))
        st.success("                        Client assigned to: \"{}\" group".format(group))
        st.success("                        We can offer insurance rate: {} $ per month".format(rate))
        st.set_option('deprecation.showPyplotGlobalUse', False)
        st.pyplot(fig=value_on_hist(prediction, file["charges"]))

    

if __name__=='__main__':
    main()
    pass