import calendar
from datetime import datetime, timedelta
import pytz
import requests
import json


DATA_DEFAULT_USER = [
  {
    "id": 311545,
    "name": "311545 311545",
    "privilege": "USER",
    "exist_busmen": "SIN REGISTRO EN BUSMEN",
    "activo": "?"
  },
  {
    "id": 211317,
    "name": "ABEN CARRANCO CASTILLO",
    "privilege": "USER",
    "exist_busmen": "SIN REGISTRO EN BUSMEN",
    "activo": "?"
  },
  {
    "id": 110172,
    "name": "ABRAHAM DIAZ CHAVEZ",
    "privilege": "USER",
    "exist_busmen": "SIN REGISTRO EN BUSMEN",
    "activo": "?"
  },
  {
    "id": 200008,
    "name": "ABRAHAM DIAZ CHAVEZ",
    "privilege": "USER",
    "exist_busmen": "SIN REGISTRO EN BUSMEN",
    "activo": "?"
  },
  {
    "id": 311618,
    "name": "ABRAHAM EZAU CORTES GARA",
    "privilege": "USER",
    "exist_busmen": "SIN REGISTRO EN BUSMEN",
    "activo": "?"
  },
  {
    "id": 9999,
    "name": "ADAN MAGAA",
    "privilege": "USER",
    "exist_busmen": "SIN REGISTRO EN BUSMEN",
    "activo": "?"
  },
  {
    "id": 311558,
    "name": "ADRIAN SALGADO ZAVALA",
    "privilege": "USER",
    "exist_busmen": "SIN REGISTRO EN BUSMEN",
    "activo": "?"
  },
  {
    "id": 110196,
    "name": "ADRIANA RODRIGUEZ CAMPOS",
    "privilege": "USER",
    "exist_busmen": "SIN REGISTRO EN BUSMEN",
    "activo": "?"
  },
  {
    "id": 211286,
    "name": "ADRIANA RODRIGUEZ CAMPOS",
    "privilege": "USER",
    "exist_busmen": "SIN REGISTRO EN BUSMEN",
    "activo": "?"
  },
  {
    "id": 3655,
    "name": "AGUILAR SALAMANCA GERONIMA ISABEL",
    "privilege": "USER",
    "exist_busmen": "CON USAURIO EN BUSMEN",
    "activo": "ACTIVO"
  },
  {
    "id": 110099,
    "name": "AGUSTIN DE JESUS CARRILL",
    "privilege": "USER",
    "exist_busmen": "SIN REGISTRO EN BUSMEN",
    "activo": "?"
  },
  {
    "id": 200036,
    "name": "AGUSTIN DE JESUS CARRILL",
    "privilege": "USER",
    "exist_busmen": "SIN REGISTRO EN BUSMEN",
    "activo": "?"
  },
  {
    "id": 200105,
    "name": "AGUSTIN DE JESUS CARRILL",
    "privilege": "USER",
    "exist_busmen": "SIN REGISTRO EN BUSMEN",
    "activo": "?"
  },
  {
    "id": 311666,
    "name": "ALAN MICHEL PAULO ROSADO",
    "privilege": "USER",
    "exist_busmen": "SIN REGISTRO EN BUSMEN",
    "activo": "?"
  },
  {
    "id": 311586,
    "name": "ALBERTO BELTRAN VILLEGAS",
    "privilege": "USER",
    "exist_busmen": "SIN REGISTRO EN BUSMEN",
    "activo": "?"
  },
  {
    "id": 110177,
    "name": "ALBERTO MENDOZA GARCIA",
    "privilege": "USER",
    "exist_busmen": "SIN REGISTRO EN BUSMEN",
    "activo": "?"
  },
  {
    "id": 211255,
    "name": "ALBERTO MENDOZA GARCIA",
    "privilege": "USER",
    "exist_busmen": "SIN REGISTRO EN BUSMEN",
    "activo": "?"
  },
  {
    "id": 110034,
    "name": "ALBERTO SEBASTIAN FLORES",
    "privilege": "USER",
    "exist_busmen": "SIN REGISTRO EN BUSMEN",
    "activo": "?"
  },
  {
    "id": 311678,
    "name": "ALDO LUNA GUTIERREZ",
    "privilege": "USER",
    "exist_busmen": "SIN REGISTRO EN BUSMEN",
    "activo": "?"
  },
  {
    "id": 311491,
    "name": "ALEJANDRO ALONSO JACOBO",
    "privilege": "USER",
    "exist_busmen": "SIN REGISTRO EN BUSMEN",
    "activo": "?"
  },
  {
    "id": 220840,
    "name": "ALEJANDRO CORONA JIMENEZ",
    "privilege": "USER",
    "exist_busmen": "SIN REGISTRO EN BUSMEN",
    "activo": "?"
  },
  {
    "id": 311676,
    "name": "ALEJANDRO DE ALBA LARIOS",
    "privilege": "USER",
    "exist_busmen": "SIN REGISTRO EN BUSMEN",
    "activo": "?"
  },
  {
    "id": 211351,
    "name": "ALEJANDRO DE LOZA DELGAD",
    "privilege": "USER",
    "exist_busmen": "SIN REGISTRO EN BUSMEN",
    "activo": "?"
  },
  {
    "id": 311571,
    "name": "ALEXIS GIOVANI MEDINA HE",
    "privilege": "USER",
    "exist_busmen": "SIN REGISTRO EN BUSMEN",
    "activo": "?"
  }
]


DATA_DEFAULT_CHECKS = [
  {
    "id": 17897,
    "name": "LEDEZMA MEDINA JUAN LUIS",
    "time": "2024-12-13T10:12:34"
  },
  {
    "id": 17768,
    "name": "SILVA BALTAZAR MARIA ELIZABETH",
    "time": "2024-12-13T08:38:54"
  },
  {
    "id": 17462,
    "name": "DEL HOYO TORRES JUAN ROQUE",
    "time": "2024-12-13T07:51:08"
  },
  {
    "id": 17768,
    "name": "SILVA BALTAZAR MARIA ELIZABETH",
    "time": "2024-12-13T07:50:56"
  },
  {
    "id": 17897,
    "name": "LEDEZMA MEDINA JUAN LUIS",
    "time": "2024-12-13T07:46:51"
  },
  {
    "id": 311716,
    "name": "JUAN LUIS LEDEZMA MEDINA",
    "time": "2024-12-12T16:24:37"
  },
  {
    "id": 17897,
    "name": "LEDEZMA MEDINA JUAN LUIS",
    "time": "2024-12-12T16:24:27"
  },
  {
    "id": 17768,
    "name": "SILVA BALTAZAR MARIA ELIZABETH",
    "time": "2024-12-12T16:23:46"
  },
  {
    "id": 17897,
    "name": "LEDEZMA MEDINA JUAN LUIS",
    "time": "2024-12-12T11:30:11"
  },
  {
    "id": 11329,
    "name": "RAMON NICOLAS ARCINIEGA",
    "time": "2024-12-12T10:42:42"
  },
  {
    "id": 2088,
    "name": "LOPEZ AVILA RIGOBERTO",
    "time": "2024-12-12T08:54:01"
  },
  {
    "id": 16723,
    "name": "HERNANDEZ PALAGOT DANIEL",
    "time": "2024-12-12T08:16:33"
  },
  {
    "id": 17768,
    "name": "SILVA BALTAZAR MARIA ELIZABETH",
    "time": "2024-12-12T08:01:47"
  },
  {
    "id": 311716,
    "name": "JUAN LUIS LEDEZMA MEDINA",
    "time": "2024-12-12T07:47:03"
  },
  {
    "id": 17897,
    "name": "LEDEZMA MEDINA JUAN LUIS",
    "time": "2024-12-11T17:59:23"
  },
  {
    "id": 17897,
    "name": "LEDEZMA MEDINA JUAN LUIS",
    "time": "2024-12-11T16:09:06"
  },
  {
    "id": 17768,
    "name": "SILVA BALTAZAR MARIA ELIZABETH",
    "time": "2024-12-11T15:04:32"
  },
  {
    "id": 16723,
    "name": "HERNANDEZ PALAGOT DANIEL",
    "time": "2024-12-11T10:23:03"
  },
  {
    "id": 17897,
    "name": "LEDEZMA MEDINA JUAN LUIS",
    "time": "2024-12-11T10:13:00"
  },
  {
    "id": 17768,
    "name": "SILVA BALTAZAR MARIA ELIZABETH",
    "time": "2024-12-11T10:12:35"
  },
  {
    "id": 17462,
    "name": "DEL HOYO TORRES JUAN ROQUE",
    "time": "2024-12-11T08:01:42"
  },
  {
    "id": 2088,
    "name": "LOPEZ AVILA RIGOBERTO",
    "time": "2024-12-11T07:54:49"
  },
  {
    "id": 17768,
    "name": "SILVA BALTAZAR MARIA ELIZABETH",
    "time": "2024-12-11T07:54:37"
  },
  {
    "id": 17897,
    "name": "LEDEZMA MEDINA JUAN LUIS",
    "time": "2024-12-11T07:54:27"
  },
  {
    "id": 17897,
    "name": "LEDEZMA MEDINA JUAN LUIS",
    "time": "2024-12-10T17:55:31"
  },
  {
    "id": 10213,
    "name": "MARTINEZ PABLO ALFONSO",
    "time": "2024-12-13T09:00:10"
  },
  {
    "id": 20743,
    "name": "HERRERA FABIOLA VICTORIA",
    "time": "2024-12-13T08:52:24"
  },
  {
    "id": 19468,
    "name": "GARCIA FERNANDO ANTONIO",
    "time": "2024-12-13T08:45:32"
  },
  {
    "id": 15793,
    "name": "PEREZ LUIS ENRIQUE",
    "time": "2024-12-13T08:30:51"
  },
  {
    "id": 23456,
    "name": "GOMEZ SANDRA ISABEL",
    "time": "2024-12-13T08:10:45"
  },
  {
    "id": 28902,
    "name": "MARTIN JUAN CARLOS",
    "time": "2024-12-13T07:50:33"
  },
  {
    "id": 23112,
    "name": "VEGA RAUL ENRIQUE",
    "time": "2024-12-13T07:45:10"
  },
  {
    "id": 20202,
    "name": "MORALES NATALIA DEL CARMEN",
    "time": "2024-12-13T07:30:21"
  },
  {
    "id": 32456,
    "name": "SANTOS MIGUEL ANGEL",
    "time": "2024-12-13T07:20:56"
  },
  {
    "id": 15468,
    "name": "ROJAS MIGUEL ALEJANDRO",
    "time": "2024-12-13T07:15:47"
  },
  {
    "id": 26789,
    "name": "MENDOZA CARLOS EDUARDO",
    "time": "2024-12-13T06:58:12"
  },
  {
    "id": 29001,
    "name": "CASTRO ENRIQUE JOSÉ",
    "time": "2024-12-13T06:45:32"
  },
  {
    "id": 15579,
    "name": "RIVERA JOSE EDUARDO",
    "time": "2024-12-13T06:30:24"
  },
  {
    "id": 11892,
    "name": "PARRA JUAN PABLO",
    "time": "2024-12-13T06:15:50"
  },
  {
    "id": 23872,
    "name": "FLORES MARTA ALEJANDRA",
    "time": "2024-12-13T06:00:13"
  },
  {
    "id": 10256,
    "name": "PEREZ LUISA MARIA",
    "time": "2024-12-13T05:50:12"
  },
  {
    "id": 10423,
    "name": "SERRANO PEDRO ALFONSO",
    "time": "2024-12-13T05:30:11"
  },
  {
    "id": 28579,
    "name": "ALVAREZ DANIEL",
    "time": "2024-12-13T05:15:42"
  },
  {
    "id": 15793,
    "name": "PEREZ LUIS ENRIQUE",
    "time": "2024-12-13T05:00:28"
  },
  {
    "id": 23124,
    "name": "GUTIERREZ LINA MARCELA",
    "time": "2024-12-13T04:45:56"
  },
  {
    "id": 29412,
    "name": "CARRILLO JUAN PABLO",
    "time": "2024-12-13T04:30:34"
  },
  {
    "id": 19372,
    "name": "SERRANO PEDRO FABIÁN",
    "time": "2024-12-13T04:10:52"
  },
  {
    "id": 17874,
    "name": "MORENO CRISTINA ALEJANDRA",
    "time": "2024-12-13T03:55:21"
  },
  {
    "id": 16785,
    "name": "SILVA ISIDRO ALFONSO",
    "time": "2024-12-13T03:30:47"
  },
  {
    "id": 10456,
    "name": "JIMENEZ CARLOS ENRIQUE",
    "time": "2024-12-13T03:15:10"
  },
  {
    "id": 27142,
    "name": "PARRA EDISON ENRIQUE",
    "time": "2024-12-13T03:00:03"
  },
  {
    "id": 25033,
    "name": "MORALES MARTIN ANTONIO",
    "time": "2024-12-13T02:45:15"
  },
  {
    "id": 11872,
    "name": "RAMIREZ PABLO EDUARDO",
    "time": "2024-12-13T02:30:26"
  },
  {
    "id": 29834,
    "name": "ALVAREZ GABRIEL EDUARDO",
    "time": "2024-12-13T02:15:09"
  },
  {
    "id": 30556,
    "name": "CASTILLO ANA PATRICIA",
    "time": "2024-12-13T02:00:17"
  },
  {
    "id": 26911,
    "name": "HERNANDEZ ALICIA MARINA",
    "time": "2024-12-13T01:50:22"
  },
  {
    "id": 29765,
    "name": "SUAREZ CECILIA ELENA",
    "time": "2024-12-13T01:40:19"
  },
  {
    "id": 27348,
    "name": "RAMIREZ JUAN EDUARDO",
    "time": "2024-12-13T01:30:50"
  },
  {
    "id": 12873,
    "name": "MORENO JAVIER ENRIQUE",
    "time": "2024-12-13T01:15:35"
  },
  {
    "id": 23672,
    "name": "PEREZ JOSÉ MANUEL",
    "time": "2024-12-13T01:00:19"
  },
  {
    "id": 19673,
    "name": "CASTRO MARIO ALFONSO",
    "time": "2024-12-13T00:45:27"
  },
  {
    "id": 21465,
    "name": "LOPEZ GUSTAVO ALFONSO",
    "time": "2024-12-13T00:30:58"
  },
  {
    "id": 18972,
    "name": "RIVERA JOSÉ MANUEL",
    "time": "2024-12-13T00:15:37"
  },
  {
    "id": 12345,
    "name": "MORALES JOSE LUIS",
    "time": "2024-12-13T00:00:19"
  }
]




def validate_update_date_time(conn, fecha_checador: str) -> bool:
    """
    Compara la fecha y hora del checador con la fecha actual. Si son diferentes, actualiza la fecha del dispositivo.

    :param conn: Conexión establecida con el dispositivo ZKTeco.
    :param fecha_checador: Fecha del checador en formato "YYYY-MM-DD HH:MM:SS".
    :return: True si la fecha y hora coinciden, False si son diferentes (y se actualiza la fecha).
    """

    # Fecha actual
    zona_horaria = pytz.timezone('America/Mexico_City')
    fecha_actual = datetime.now(zona_horaria)

    # Convertimos la fecha del checador a un objeto datetime
    fecha_checador = datetime.strptime(fecha_checador, "%Y-%m-%d %H:%M:%S")

    # Validamos si la fecha y hora del checador coinciden con la fecha actual en año, mes, día, hora y minuto
    if (fecha_checador.year == fecha_actual.year and
            fecha_checador.month == fecha_actual.month and
            fecha_checador.day == fecha_actual.day and
            fecha_checador.hour == fecha_actual.hour and
            fecha_checador.minute == fecha_actual.minute):

        # Las fechas coinciden en el día, hora y minuto
        return True  # Las fechas son iguales

    else:
        # Las fechas son diferentes, actualizamos la fecha del dispositivo
        try:
            # Establecer la fecha actual en el checador
            conn.set_time(fecha_actual)

            print(f"Fecha actualizada correctamente en el checador: {fecha_actual}")
            return False  # Las fechas son diferentes y se actualizó la fecha

        except Exception as e:
            print(f"Error al actualizar la fecha: {e}")
            return False  # Error en la actualización de la fecha

def get_user_to_api_busmen():
    url_api_busmen = "https://nuevosistema.busmen.net/WS/zktEco.php"

    headers = {'content-type': 'application/json'}
    response = requests.get(url=url_api_busmen, headers=headers)

    return json.loads(response.text)

def format_date( fecha_str):
    # Convertir la cadena a un objeto datetime
    fecha_obj = datetime.strptime(fecha_str, "%Y-%m-%d %H:%M:%S")

    # Convertir el objeto datetime al formato deseado "dd-mm-yyyy hh:mm:ss"
    fecha_formateada = fecha_obj.strftime("%d-%m-%Y %H:%M:%S")

    return fecha_formateada


def get_date_and_time(finish=False):
    tz = pytz.timezone('America/Mexico_City')
    fecha = datetime.now(tz).strftime('%Y-%m-%d')
    hora = "00:00" if not finish else "23:59"

    return fecha, hora

def get_check_on_range(collection_things=None, star_data=None, end_data=None):
    if collection_things is None and star_data is None and end_data is None:
        return []

    # print(f"date start: {star_data} end date: {end_data}")

    new_data_collection = []
    for thing in collection_things:  # <>
        if star_data <= thing["time"] <= end_data:
            # print(thing)
            new_data_collection.append(thing)
    return new_data_collection


def get_first_day_and_ultimate_day(date):
  # Primer día del mes
  primer_dia = date.replace(day=1)

  # Último día del mes
  ultimo_dia = date.replace(day=calendar.monthrange(date.year, date.month)[1])

  return primer_dia, ultimo_dia


def get_first_and_last_day_of_week(date_input):
    input_type = type(date_input)

    if isinstance(date_input, str):
        date = datetime.strptime(date_input, "%Y-%m-%d").date()

    elif isinstance(date_input, datetime):
        date = date_input.date()

    elif isinstance(date_input, dt_date):
        date = date_input
    else:
        raise TypeError("date_input debe ser str, datetime o date")


    start_of_week = date - timedelta(days=date.weekday())

    end_of_week = start_of_week + timedelta(days=6)

    if input_type is str:
        return start_of_week.strftime("%Y-%m-%d"), end_of_week.strftime("%Y-%m-%d")
    elif input_type is datetime:
        return datetime.combine(start_of_week, datetime.min.time()), datetime.combine(end_of_week, datetime.min.time())
    elif input_type is dt_date:
        return start_of_week, end_of_week


def get_date_time_fixer(user_device, save_logs, data_time, all_users):


  not_found = "F"

  for user in all_users:

    check_user =  [item for item in user_device if f"{item.user_id}" == user['id'] and is_valid]

    log_check = [ time for time in check_user if data_time["start_date"] <= str(time.timestamp).split(" ")[0] <= data_time["end_date"] and data_time["start_time"] <= \
                  str(time.timestamp).split(" ")[1] <= data_time["end_time"] ] #and user["maletin"] == name_device["company"]

    is_user_exited = [user_old for user_old in save_logs if user_old["id"] == user["id"] ]

    # if user["id"] == "17546":
    #   print(f"{user["maletin"]} | {name_device["company"]} | log_check {log_check} | is_user_exited {is_user_exited}")

    if len(log_check) > 0:

      for log in log_check:

        things = {
          'id': user['id'],
          'name': f"{user['apellido_paterno']} {user['apellido_materno']} {user['nombre']}",
          'puesto': user['puesto'],
          'name_device': user["empresa_nombre"] ,
          'date': str(log.timestamp).split(" ")[0],
          'time': str(log.timestamp).split(" ")[1],
        }
        save_logs.append(things)

    else:

      if len(is_user_exited) == 0:
        things = {
          'id': user['id'],
          'name': f"{user['apellido_paterno']} {user['apellido_materno']} {user['nombre']}",
          'puesto': user['puesto'],
          'company': user["empresa_nombre"],
          'name_device': not_found,
          'date': not_found,
          'time': not_found,
        }

        save_logs.append(things)

