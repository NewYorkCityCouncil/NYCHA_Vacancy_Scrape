# NYCHA Vacancy
Data analysis and visuals for NYCC 1.31.23 ['Oversight – Examining Causes of Vacancies In New York City Housing Authority Properties'](https://legistar.council.nyc.gov/MeetingDetail.aspx?ID=1075729&GUID=5CFEE992-007B-4AC7-BD8D-BCADBEF26A08&Options=info|&Search=) hearing.

An associated webpage for this analysis can be found [on the council website](https://council.nyc.gov/data/nycha-vacancy/).

***

#### Data Sources
The data used was scrapped from ['New York City Housing Authority - NYCHA Metrics'](https://eapps.nycha.info/NychaMetrics/Charts/PublicHousingChartsTabs/?section=public_housing&tab=tab_vacancies#tab_vacancies) using Python and Selenium. The code can be found at ['code/NYCHA_selenium.py'](https://github.com/NewYorkCityCouncil/NYCHA_Vacancy_Scrape/blob/main/code/NYCHA_selenium.py_) and the csv file from the scrape can be found at ['data/output/all_dev_data.csv'](https://github.com/NewYorkCityCouncil/NYCHA_Vacancy_Scrape/blob/main/data/output/all_dev_data.csv).


#### Methodology 

##### Summary & Intention
The need for housing in New York City is ever present. The intense and unending demand for a NYCHA apartment makes it imperative that NYCHA quickly and efficiently place prospective tenants into vacant apartments. This has the dual result of housing a family in need and returning the apartment to the rent rolls. As NYCHA deals with an ongoing funding crisis, the need to keep vacancies as low as possible is vital.

The data team analyzed NYCHA's vacancy rates to:

- Assess the severity of the problem

- Validate NYCHA's claims

#### Main Takeaways
- In the last year, there has been a marked uptick in vacant apartments and accordingly an increase in the average turnaround days to re-occupy vacant apartments. Overall growth in the total unoccupied apartments from 4,213 (December 2021) to 7,047 (December 2022) with the largest increase coming from the growth in vacant apartments from 490 to over 3,300.

- There were a few standout developments that had markedly large increases in their vacancy rate. The most notable one is the BRONX RIVER ADDITION development, where it went from 1.3% in September 2021, to close to 25% in December 2022.

- Of the 3,000 vacancies at the end of 2022, only 390 of them were in developments currently in the RAD/PACT pipeline. Their vacancy trend follows the rest of the other non-RAD/PACT developments closely.
