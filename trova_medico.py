import requests
import pandas as pd

def download_doctor_table():
    ats_url = "https://serviziweb.asur.marche.it/mmgpls/index.php"
    response = requests.get(ats_url)
    doctor_data = pd.read_html(response.content)[0]
    columns_to_drop = doctor_data.filter(like='Unnamed').columns
    doctor_data = doctor_data.drop(columns=columns_to_drop).dropna(how='all')
    doctor_data['MEDICO'] = doctor_data['MEDICO'].ffill()
    return doctor_data