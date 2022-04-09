import pandas as pd
import numpy as np
import os
import matplotlib.pyplot as plt
from IPython.display import display

pd.set_option('display.max_rows', None)
pd.set_option('display.max_columns', None)
pd.set_option('display.width', 1000)
pd.set_option('display.colheader_justify', 'center')
pd.set_option('display.precision', 3)

cwd = os.getcwd() #current working directory

df1 = pd.read_csv(cwd+'\\googleplaystore.csv') 
data = df1[['App', 'Category', 'Rating', 'Reviews', 'Size', 'Installs', 'Type', 'Content Rating']].groupby(['App']).max().dropna().reset_index()
data["Installs"] = pd.to_numeric(data["Installs"].str.replace(",","").str.replace("+",""))
data["Reviews"] = pd.to_numeric(data["Reviews"])
mydata = data[['App',"Type", 'Size','Category', 'Content Rating', "Rating", "Reviews", "Installs"]]

size = mydata[:]
size = size[size["Size"] != "Varies with device"]
size["Size number"] = pd.to_numeric(size["Size"].str[:-1])
size["Size units"] = size["Size"].str[-1:]
size["unit bytes"] = size["Size units"].apply(lambda x: 1/1024 if x == "k" else 1)
size["unit bytes"] = pd.to_numeric(size["unit bytes"])
size["Size mb"] = size["Size number"] * size["unit bytes"]
mydata= size.iloc[:,[0,1,2,3,4,5,6,7,11]]
duplicates =mydata['App'].duplicated().sum()

def clean_data(): #funkcja
  
    display(mydata.head())
    print(mydata.info())
    print(f'No of duplicates: {duplicates}')

avg_rev =round(mydata['Reviews'].mean(),2)
avg_inst = round(mydata['Installs'].mean(),2)
avg_rat = round(mydata['Rating'].mean(),2)

def means(): #funkcja
     
    print(f'Średnia liczba recenzji aplikacji wynosi: {avg_rev}')
    print(f'Średnia liczba pobrań aplikacji wynosi: {avg_inst}')
    print(f'Średnia ocena aplikacji wynosi: {avg_rat}')

corr =mydata.corr(method='pearson')
import seaborn as sns
# plt.figure(figsize=(20,10))
# mask = np.zeros_like(corr)
# mask[np.triu_indices_from(mask)] = True
# hetmap = sns.heatmap(corr, annot=True, cmap = 'Spectral', linewidths=5, mask=mask, vmax=1)


def correlation(): #funkcja

    display(corr)
    plt.figure(figsize=(20,10))
    mask = np.zeros_like(corr)
    mask[np.triu_indices_from(mask)] = True
    sns.heatmap(corr, annot=True, cmap = 'Spectral', linewidths=5, mask=mask, vmax=1)
    



data_type = mydata[['App', 'Type', 'Rating', 'Installs', 'Reviews']]

free_type =data_type[data_type['Type']== 'Free']
paid_type =data_type[data_type['Type']== 'Paid']


def type_charts_rating(): #funkcja
    free_type['Rating'].plot.density(xlim=(0, free_type['Rating'].max()))
    paid_type['Rating'].plot.density(xlim=(0, paid_type['Rating'].max()),color = 'k')
    plt.title('Density plot for Free/Paid applications vs rating')
    plt.xlabel('Rating')
    plt.legend(['Density plot for free apps', 'Density plot for paid apps'])
    plt.show()



def type_charts_installs(): #funkcja
    free_type['Installs'].plot.density(xlim=(0, free_type['Installs'].max()))
    paid_type['Installs'].plot.density(xlim=(0, paid_type['Installs'].max()),color = 'k')
    plt.title('Density plot for Free/Paid applications vs installs')
    plt.xlabel('Installs')
    plt.legend(['Density plot for free apps', 'Density plot for paid apps'])
    plt.show()



def type_charts_reviews(): # funkcja
    free_type["Reviews"].plot.density(xlim=(0, free_type['Reviews'].max()))
    paid_type['Reviews'].plot.density(xlim=(0, paid_type['Reviews'].max()),color = 'k')
    plt.title('Density plot for Free/Paid applications vs reviews')
    plt.xlabel('Reviews')
    plt.legend(['Density plot for free apps', 'Density plot for paid apps'])
    plt.show()




#as Installs is main factor of decision of popularity - we selected ration mean of Installs of free apps / paid apps, which will be used for scoreboard

stos_mean_i = round(free_type['Installs'].mean()/paid_type['Installs'].mean(), 2)

def mean_ratio(): #funkcja
    
    print(f'Ratio - ilość pobrań app darmowej / płatnej: {stos_mean_i}')



s1 = data_type.groupby(by='Type').describe()['Rating']
s2 = data_type.groupby(by='Type').describe()['Reviews']
s3 = data_type.groupby(by='Type').describe()['Installs']

def statistic_type(): #funkcja

    display(s1)
    display(s2)
    display(s3)



cat_rating = mydata[["Category","Rating"]].groupby("Category").describe().reset_index()
cat_rating.columns = cat_rating.columns.droplevel()
cat_rating = cat_rating.sort_values("count", ascending=False)
cat_rating.columns = ["Category", "count", "mean", "std", "min", "25%", "50%", "75%", "max"]
top_10_cat =cat_rating.iloc[:10]

def top_10_category_rating(): #funkcja

    display(top_10_cat)



cat_reviews = mydata[["Category","Reviews"]].groupby("Category").describe().reset_index()
cat_reviews.columns = cat_reviews.columns.droplevel()
cat_reviews = cat_reviews.sort_values("count", ascending=False)
cat_reviews.columns = ["Category reviews - by count", "count", "mean", "std", "min", "25%", "50%", "75%", "max"]
top_10_cat_reviews =cat_reviews.iloc[:10]

def top_10_category_reviews(): #funkcja

    display(top_10_cat_reviews)



cat_installs = mydata[["Category","Installs"]].groupby("Category").describe().reset_index()
cat_installs.columns = cat_installs.columns.droplevel()
cat_installs = cat_installs.sort_values("count", ascending=False)
cat_installs.columns = ["Category reviews - by mean", "count", "mean", "std", "min", "25%", "50%", "75%", "max"]
top_10_cat_installs =cat_installs.iloc[:10]

def top_10_category_installs(): #funkcja

    display(top_10_cat_installs)




#score creation for category - all:
# rev_scores = mydata.sort_values(["Installs","Reviews"], ascending=False)
# rev_scores = rev_scores.groupby(["Category"]).count().reset_index()
# print("ilość aplikacji", rev_scores["App"].sum())
# print("ilość kategorii", rev_scores["Category"].count())
# rev_scores["Score"] = round(rev_scores["App"]/min(rev_scores["App"]))
# cat_rank =rev_scores.iloc[:,[0,1,-1]].sort_values(["App"], ascending=False)
# category_score =cat_rank[['Category', 'Score']]


#preparation score for size - categorize of size

mydata['Size category'] = mydata['Size mb'] // 10

# selected q 0.8 as 'popularity factor definition' for scoreboard creation

q = .8
pop = mydata[mydata["Installs"] > mydata["Installs"].quantile(q)]
pop = pop[pop["Reviews"] > pop["Reviews"].quantile(q)]
pop.sort_values(["Installs","Reviews"], ascending=False)

rev_scores = pop.sort_values(["Installs","Reviews"], ascending=False)
rev_scores = rev_scores.groupby(["Category"]).count().reset_index()
#print("ilość aplikacji", rev_scores["App"].sum())
#print("ilość kategorii", rev_scores["Category"].count())

rev_scores["Category Score"] = round(rev_scores["App"]/min(rev_scores["App"]))
rev_scores.iloc[:,[0,1,-1]].sort_values(["App"], ascending=False)
rev_scores = rev_scores[['Category', 'Category Score']]


content_scores = pop.sort_values(["Installs","Reviews"], ascending=False)
content_scores = content_scores.groupby(["Content Rating"]).count().reset_index()
content_scores.iloc[:,:2].sort_values(["App"], ascending=False)
content_scores["Score content"] = round(content_scores["App"]/min(content_scores["App"]))
content_scores =content_scores.iloc[:,[0,1,-1]].sort_values(["App"], ascending=False)
content_scores = content_scores[['Content Rating', 'Score content']]

size_scores = pop.sort_values(["Installs","Reviews"], ascending=False)
size_scores = size_scores.groupby(["Size category"]).count().reset_index()
size_scores.iloc[:,:2].sort_values(["App"], ascending=False)
size_scores["Score size"] = round(size_scores["App"]/min(size_scores["App"]))
size_scores =size_scores.iloc[:,[0,1,-1]].sort_values(["App"], ascending=False)
size_scores = size_scores[['Size category', 'Score size']]

file  = pd.merge(mydata, content_scores, how='left', on='Content Rating')
file  = pd.merge(file, rev_scores, how='left', on='Category')
file  = pd.merge(file, size_scores, how='left', on='Size category')
file =file.fillna(0)

file_score_sum = file['Score content'] + file['Category Score'] + file['Score size']
total = pd.Series(file_score_sum)
frame = {'Total':total}
total_frame = pd.DataFrame(frame)

file['Total'] = total_frame
file =file.sort_values(['Total', 'Installs', 'Reviews'], ascending=False)

file_score_multiply = file['Total'] * stos_mean_i
total = pd.Series(file_score_multiply)
frame = {'Total':total}
total_frame = pd.DataFrame(frame)

file['Total'] = total_frame['Total']
file = file[['Category', 'Type', 'Size mb', 'Content Rating', 'Size category', 'Category Score', 'Score content', 'Score size', 'Total']]

def scoreboard (): #funkcja

    display(file.iloc[:100])


dane = data
dane[dane['Content Rating'] == 'Unrated']

categorie_test = dane['Category'].unique()

seb_categories = {c:  dane[dane['Category'] == c ]for c in categorie_test}

colors = ['r', 'g', 'b', 'y', 'm' ]


def chart_density_app (): #funkcja
    
    n_categories = 0
    index = 0
    n_plot = 1

    for col in ['Rating', 'Installs', 'Reviews']:
        for c in seb_categories.keys():
            seb_categories[c][col].plot.density(label=c.lower().capitalize(), color=colors[n_categories])
            n_categories += 1
            index += 1
            if n_categories == 5 or  index == len(seb_categories.keys()):
                plt.title(f'Density plot for category of applications vs {col} - part {n_plot}')
                plt.xlabel(col)
                plt.legend()
                plt.show()
                n_categories = 0
                n_plot += 1

dane = df1[['App', 'Category', 'Rating', 'Reviews', 'Size', 'Installs', 'Type', 'Content Rating']].groupby(['App', 'Category', 'Rating', 'Reviews', 'Size', 'Installs', 'Type', 'Content Rating']).mean().reset_index()
dane =dane.dropna()
dane.duplicated().sum()
dane = dane[['App', 'Category', 'Rating', 'Installs', 'Reviews', 'Content Rating', 'Type']]
dane['Installs'] = dane['Installs'].str.rstrip('+')
dane['Installs'] = dane['Installs'].replace(',', '', regex = True)
dane['Installs'] = pd.to_numeric(dane['Installs'])
dane['Reviews'] = pd.to_numeric(dane['Reviews'])


colors = ['r', 'g', 'b', 'y', 'm' ]
#print(dane['Content Rating'].unique())

def chart_density_rating_app (): #funkcja

    for content_rating in dane['Content Rating'].unique():
        for col in ['Rating', 'Installs', 'Reviews']:
            temp = dane[dane['Content Rating'] == content_rating]
            try:
                temp[col].plot.density(color='r')
            except ValueError:
                print(f'There is no data "{content_rating}" for column "{col}"')
            plt.title(f'Density plot of content rating "{content_rating}" for column "{col}"')
            plt.xlabel(col)
            plt.show()



def installs_category_no ():  #funkcja

    for cat in dane["Category"].unique():
        temp = dane[dane['Category'] == cat]
        temp['Installs'].value_counts().plot(kind='bar', color=('red','green', 'blue', 'yellow', 'black'))
        plt.title(f'Installs for category "{cat}"')
        plt.show()



data2 = df1[['App', 'Category', 'Rating', 'Reviews', 'Size', 'Installs', 'Type', 'Content Rating']].groupby(['App']).max().dropna().reset_index()
data2["Installs"] = pd.to_numeric(data2["Installs"].str.replace(",","").str.replace("+",""))
data_all=data2[['App', 'Category', 'Rating', 'Reviews', 'Size', 'Installs', 'Type', 'Content Rating']]
mydata2 = data2[["Size", "Rating", "Reviews", "Installs"]]
mydata2["Reviews"] = pd.to_numeric(mydata2["Reviews"])
data_all["Reviews"] = pd.to_numeric(data_all["Reviews"])


def chart_free_type_no (): # funkcja

  #podział darmowe i płatne
    print(data_all["Type"].value_counts())
    data_all["Type"].value_counts().plot(kind='bar',figsize=(7, 6), rot=0 )
    plt.ylabel("Ilość aplikacji", labelpad=14)
    plt.title("Podział aplikacji na darmowe i płatne", y=1.02)
    plt.grid(b=True, axis='y')
    plt.show()

#podział na rozmiar aplikacji
def chart_size_data_no_data ():  

    fig = plt.figure()
    ax = fig.add_axes([0,0,1,1])
    z=data_all[data_all["Size"]!="Varies with device"].count()["Size"]
    h=data_all[data_all["Size"]=="Varies with device"].count()["Size"]
    zh=[z,h]
    zh_name=["posiadamy dane o rozmiarze ","Varies with device (brak danych)"]
    print("posiadamy dane o rozmiarze : ", z)
    print("Varies with device : ",h)
    ax.bar(zh_name,zh,width = 0.45)
    plt.ylabel("Ilość aplikacji", labelpad=14)
    plt.title("Podział aplikacji na Size", y=1.02)
    plt.grid(b=True, axis='y')
    plt.show()

def chart_content_ratinng_all (): #funkcja

#ilość aplikacji podział na ceontent
    print(data_all["Content Rating"].value_counts())
    data_all["Content Rating"].value_counts().plot(kind='barh',figsize=(10, 6), rot=0 )
    plt.ylabel("Kategoria", labelpad=14)
    plt.xlabel("Ilość aplikacji", labelpad=14)
    plt.title("Podział aplikacji na Content Rating", y=1.02)
    plt.grid(b=True, axis='x')
    plt.show()


def chart_installations_avg_comp (): #funkcja

#podział na instalacje pow sredniej
    sr=data_all["Installs"].mean()
    print("Średnia liczba instalacji wszytskich aplikacji")
    fig = plt.figure()
    ax = fig.add_axes([0,0,1,1])
    z=data_all[data_all["Installs"]>sr].count()["Installs"]
    h=data_all[data_all["Installs"]<sr].count()["Installs"]
    zh=[z,h]
    zh_name=["Pow śr","poniżej śr"]
    print("pow sr: ", z)
    print("poniżej sr : ",h)
    ax.bar(zh_name,zh,width = 0.45)
    plt.ylabel("Ilość aplikacji", labelpad=14)
    plt.title("Podział na instalacje", y=1.02)
    plt.grid(b=True, axis='y')
    plt.show()

def chart_no_install (): #funkcja

    #podział ze wzgledu na ilość instalacji
    data_all["Reviews"].value_counts().plot(kind='barh',figsize=(15, 11), rot=0 )
    plt.ylabel("OIlość instalacji", labelpad=14)
    plt.xlabel("Ilość aplikacji", labelpad=14)
    plt.title("Podział na ilość instalacji", y=1.02)
    plt.grid(b=True, axis='x')
    plt.show()

def chart_reviews_avg_comp (): #funkcja


    #podział na reviews pow i poniżej sredniej
    sr=round(data_all["Reviews"].mean(),2)
    print("Sr", sr)
    fig = plt.figure()
    ax = fig.add_axes([0,0,1,1])
    z=data_all[data_all["Reviews"]>sr].count()["Reviews"]
    h=data_all[data_all["Reviews"]<sr].count()["Reviews"]
    zh=[z,h]
    zh_name=["Pow śr","poniżej śr"]
    print("pow sr: ", z)
    print("poniżej sr : ",h)
    ax.bar(zh_name,zh,width = 0.45)
    plt.ylabel("Ilość aplikacji", labelpad=14)
    plt.title("Podział na Reviews", y=1.02)
    plt.grid(b=True, axis='y')
    plt.show()





def chart_size_quantile(): #funckja

   
    plt.figure(figsize=(20,10))
    quantiles = np.arange(0.3, 1, 0.1).round(1)
    quantiles.round()
    for q in quantiles:
    
        t = size[size["Installs"] > size["Installs"].quantile(q)]
        t = t[t["Reviews"] > t["Reviews"].quantile(q)]
        t["Size mb"].plot.density(xlim=(0,t["Size mb"].max()), ylim=(0,.03))
        plt.xlabel("Size [Mb]")
        plt.legend(quantiles)
    pass

########### APP APP ###############

### WIDGETS ###

import ipywidgets as widgets
from IPython.display import display

def widget():
    categories = data["Category"].sort_values().unique()
    category_scoreboard = pd.merge(data["Category"].drop_duplicates(), rev_scores, on="Category", how="left").fillna(0)

    contents = data["Content Rating"].unique()
    content_scoreboard = pd.merge(data["Content Rating"].drop_duplicates(), content_scores, on="Content Rating", how="left").fillna(0) 

    size = widgets.IntSlider(max = 110)
    size_widget = widgets.VBox([widgets.Label("Size [Mb]"), size])
    category = widgets.Dropdown(options=categories)
    category_widget = widgets.VBox([widgets.Label("Category"), category])
    freepaid_button = widgets.ToggleButtons(options=["Free", "Paid"])
    content = widgets.RadioButtons(options=contents, desciption="Content rating:")
    content_widget = widgets.VBox([widgets.Label("Content Rating"), content])

### SCOREBOARDS and SCORE COUNTING ###

category_score = float(category_scoreboard[category_scoreboard["Category"] == category.value]["Category Score"])
content_score = float( content_scoreboard[content_scoreboard["Content Rating"] == content.value]["Score content"] )

if freepaid_button.value == "Free": 
    subscription_score = round(stos_mean_i)
else:
    subscription_score = 1

if size.value < 100:
    size_input = size.value
else:
    size_input = 100
size_score = float(size_scores[size_scores["Size category"] == (size_input//10)]["Score size"])

cat_max = category_scoreboard["Category Score"].max()
cont_max = content_scoreboard["Score content"].max()
size_max = size_scores["Score size"].max()

max_score = round ((cat_max + cont_max + size_max) * round(stos_mean_i))

score = round ((category_score + size_score + content_score) * subscription_score,2)
score_prc = round(score*100/max_score,2)

if subscription_score == 1 :
    paid_app_message = f"free apps got x{stos_mean_i} score multiplier"
else:
    paid_app_message = "max"

def print_app_stats():    
    print(f"Size score:           {size_score} / {size_max}")
    print(f"Category score:       {category_score} / {cat_max}")
    print(f"Free/paid multiplier: x{subscription_score} - {paid_app_message}")
    print(f"Content score:        {content_score} / {cont_max}")
    print(f"---------------------------------------")
    print(f"TOTAL SCORE:          {score} / {max_score}")
    print(f"TOTAL SCORE %         {score_prc}% / 100.00%")