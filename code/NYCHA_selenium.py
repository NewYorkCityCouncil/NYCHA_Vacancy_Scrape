from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from webdriver_manager.chrome import ChromeDriverManager
import pandas as pd
import re
from datetime import datetime
import os

current_dir = os.path.dirname(os.path.abspath(__file__))
BASE_DIR = os.path.dirname(current_dir)

print("Starting Chrome driver...")
options = Options()
options.add_argument("--headless=new")
options.add_argument("--window-size=1920,1200")

WEBSITE_URL = "https://eapps.nycha.info/NychaMetrics/Charts/PublicHousingChartsTabs/?section=public_housing&tab=tab_vacancies#tab_vacancies"
driver = webdriver.Chrome(options=options, service=Service(ChromeDriverManager().install()))

print(f"Loading main page...")
driver.get(WEBSITE_URL)

dev_elements = driver.find_elements(By.XPATH, '//*[@id="divDevelopmentsOccupanciesVacancies"]//option')

DevNum_lst = []
DevName_lst = []

for element in dev_elements:
    DevNum_lst.append(element.get_attribute('value'))
    DevName_lst.append(element.text)

devs_df = pd.DataFrame({'Dev_Number': DevNum_lst, 'Dev_Name': DevName_lst})
total_devs = len(devs_df)
print(f"Found {total_devs} developments to process.\n")

def CreateDevDF(Dev_Num, current, total):
    dev_name = devs_df.loc[devs_df['Dev_Number'] == str(Dev_Num), 'Dev_Name'].values
    dev_name = dev_name[0] if len(dev_name) > 0 else "Unknown"
    print(f"[{current}/{total}] Processing: {dev_name} (#{Dev_Num})...")

    WEBSITE_URL = "https://eapps.nycha.info/NychaMetrics/RenderChart/VacanciesOccupancies/?boroughName=&devNum=" + Dev_Num
    driver.get(WEBSITE_URL)

    category_elements = driver.find_elements(By.XPATH, '//category')
    category_lst = [el.get_attribute('label') for el in category_elements]

    dataset_elements = driver.find_elements(By.TAG_NAME, 'dataset')
    dataset_lst = [el.get_attribute('seriesname') for el in dataset_elements]

    set_elements = driver.find_elements(By.TAG_NAME, 'set')
    set_lst = [el.get_attribute('value') for el in set_elements]

    num_rows = len(category_lst)

    pageSource = driver.page_source
    vacancies = re.findall(r'set value="(\d+)', pageSource)[-(num_rows):]

    data = {
        'Dev_Number': [str(Dev_Num)] * num_rows,
        'Month - Year': category_lst,
        dataset_lst[0]: set_lst[0:num_rows],
        dataset_lst[1]: set_lst[num_rows:2*num_rows],
        dataset_lst[2]: set_lst[2*num_rows:3*num_rows],
        'Vacancies': vacancies
    }

    df = pd.merge(pd.DataFrame(data), devs_df, on='Dev_Number', how='left')
    return df


final_df = pd.DataFrame(columns=['Dev_Number', 'Dev_Name', 'Month - Year', 'Occupied', 'Move-In/Selected', 'Non-Dwelling', 'Vacancies'])

for i, dev in enumerate(devs_df['Dev_Number'], start=1):
    try:
        final_df = pd.concat([final_df, CreateDevDF(dev, i, total_devs)], axis=0)
    except Exception as e:
        print(f"  ⚠️  Error processing dev #{dev}: {e}")

print(f"\nAll developments processed. Saving CSV...")
date_pulled = datetime.today().strftime('%Y-%m-%d')
output_path = os.path.join(BASE_DIR, f"data/output/all_dev_data_(pulled_{date_pulled}).csv")
final_df.to_csv(output_path, index=False)
print(f"Done! File saved to: {output_path}")