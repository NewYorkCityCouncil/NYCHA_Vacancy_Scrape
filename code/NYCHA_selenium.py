from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from webdriver_manager.chrome import ChromeDriverManager
import pandas as pd
import math
import re

options = Options()
options.headless = True # Make it headless (no GUI)
options.add_argument("--window-size=1920,1200")

WEBSITE_URL = "https://eapps.nycha.info/NychaMetrics/Charts/PublicHousingChartsTabs/?section=public_housing&tab=tab_vacancies#tab_vacancies"
driver = webdriver.Chrome(options= options,service=Service(ChromeDriverManager().install()))
driver.get(WEBSITE_URL)

dev_elements = driver.find_elements(By.XPATH,'//*[@id="divDevelopmentsOccupanciesVacancies"]//*')

DevNum_lst = []
DevName_lst = []

for element in dev_elements:
   DevNum_lst.append(element.get_attribute('value'))
   DevName_lst.append(element.text)

del DevName_lst[0]
del DevNum_lst[0]

devs_df = pd.DataFrame({'Dev_Number': DevNum_lst,
'Dev_Name': DevName_lst})

def CreateDevDF(Dev_Num):
    WEBSITE_URL = "https://eapps.nycha.info/NychaMetrics/RenderChart/VacanciesOccupancies/?boroughName=&devNum=" + Dev_Num
    driver.get(WEBSITE_URL)

    # Grab dates available
    category_elements = driver.find_elements(By.XPATH,'//category')
    category_lst = []
    for element in category_elements:
        category_lst.append(element.get_attribute('label'))

    # Grab available datasets in HTML
    dataset_elements = driver.find_elements(By.TAG_NAME,'dataset')
    dataset_lst = []
    for element in dataset_elements:
        dataset_lst.append(element.get_attribute('seriesname'))
    
    # Grab the values
    set_elements = driver.find_elements(By.TAG_NAME,'set')
    set_lst = []
    for element in set_elements:
        set_lst.append(element.get_attribute('value'))

    # Number of rows = number of dates available
    num_rows = len(category_lst)

    # Regex for the vacancy values
    pageSource = driver.page_source
    vacancies = re.findall('set value="(\d+)',pageSource)[-(num_rows):]

    data = {'Dev_Number': [str(Dev_Num)] * num_rows,
    'Month - Year': category_lst, 
    dataset_lst[0]: set_lst[0:num_rows],
    dataset_lst[1]: set_lst[num_rows:2*num_rows],
    dataset_lst[2]: set_lst[2*num_rows:3*num_rows],
    'Vacancies': vacancies }

    df = pd.merge(pd.DataFrame(data),
    devs_df,
    on = 'Dev_Number',
    how = 'left')

    return(df)

CreateDevDF('51')
final_df = pd.DataFrame(columns = ['Dev_Number','Dev_Name','Month - Year','Occupied','Move-In/Selected','Non-Dwelling','Vacancies'])
for dev in devs_df['Dev_Number']:
    final_df = final_df.concat(CreateDevDF(dev))

final_df.to_csv("all_dev_data.csv", index=False)

#for i in range(13):
#    print(set_lst[0 + i] + " " + set_lst[13 + i] + " " + set_lst[26 + i] +": " + str(int(set_lst[0 + i]) + int(set_lst[13 + i]) + int(set_lst[26 + i])))

#chart_ymax = float(driver.find_element(By.XPATH,'//chart').get_attribute('yaxismaxvalue'))
#vacancies_lst = []
#for i in range(13):
#    vacancies_lst.append(int(math.ceil(chart_ymax * ymax_multiplier)) - int(set_lst[0 + i]) - int(set_lst[13 + i]) - int(set_lst[26 + i]))

