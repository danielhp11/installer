import requests
import json


class Login_Busmen:

    url = "https://nuevosistema.busmen.net/WS/"

    data_user = None

    def __init__(self):
        pass

    def getter_user(self):
        return self.data_user

    def validate_incidence(self, date_init, date_finish):
        url_api = f"{self.url}zktEco-incidencia.php"
        headers = {'content-type': 'application/json'}
        params = {
            'date_init': date_init,
            'date_finish': date_finish
        }

        response = requests.get(url=url_api, headers=headers, params=params)

        return json.loads(response.text)

    def validate_user(self, name):
        busmen = self.get_user_to_api_busmen(name)["data"]

        # for user in busmen:
        #     if user["usuario_registro"] == name:
        #         self.data_user = user
        self.data_user = next((user for user in busmen if user["id_usuario"] == name), None)


    def get_user_to_api_busmen(self, user):

        url_api_busmen = f"{self.url}zktEco_login.php"

        headers = {'content-type': 'application/json'}
        params = {'id_usuario': user}

        response = requests.get(url=url_api_busmen, headers=headers, params=params)

        return json.loads(response.text)
