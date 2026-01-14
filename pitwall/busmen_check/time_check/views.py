import pytz
from django.http import JsonResponse
from django.shortcuts import render, redirect
from datetime import datetime, timedelta
from datetime import date
from zk import ZK
import calendar
import requests

from .login_busmen import Login_Busmen
from .miscellaneous import get_user_to_api_busmen, get_date_and_time, \
    get_first_day_and_ultimate_day, get_date_time_fixer, get_first_and_last_day_of_week
from .ping_device_singleton import DeviceConnectivityChecker
import json

from .zkt_eco.Zkteco import Zkteco

style_find = [
    {"find": 0, "cx": 30, "cy": 40, 'label': 'Meñique izquierdo'},
    {"find": 1, "cx": 60, "cy": 40, 'label': 'Anular izquierdo'},
    {"find": 2, "cx": 90, "cy": 40, 'label': 'Medio izquierdo'},
    {"find": 3, "cx": 120, "cy": 40, 'label': 'Indice izquierdo'},
    {"find": 4, "cx": 150, "cy": 40, 'label': 'Pulgar izquierdo'},

    {"find": 5, "cx": 30, "cy": 80, 'label': 'Pulgar derecho'},
    {"find": 6, "cx": 60, "cy": 80, 'label': 'Indice derecho'},
    {"find": 7, "cx": 90, "cy": 80, 'label': 'Medio derecho'},
    {"find": 8, "cx": 120, "cy": 80, 'label': 'Anular derecho'},
    {"find": 9, "cx": 150, "cy": 80, 'label': 'Meñique derecho'}
]

dispositivos = [
    {"name": "CHECADOR ALMACEN", "ip": "172.16.1.46", "company": "33"},  #1
    {"name": "CHECADOR COMPRAS", "ip": "172.16.1.38", "company": "33"},  #2
    {"name": "CHECADOR COSTURA", "ip": "172.16.1.21", "company": "67"},  #3
    {"name": "CHECADOR ESCARH", "ip": "172.16.1.42", "company": "9"},  #4
    {"name": "CHECADOR FINANZAS", "ip": "172.16.1.39", "company": "33"},  #5
    {"name": "CHECADOR GEOVOY", "ip": "172.16.1.47", "company": "58"},  #6
    {"name": "CHECADOR MECANICOS LINEA 1", "ip": "172.16.1.49", "company": "59"},  #7
    {"name": "CHECADOR VIGILANCIA NARANJA", "ip": "172.16.1.43", "company": "33"},  #8
    {"name": "CHECADOR RECEPCION MORADO", "ip": "172.16.1.45", "company": "33"},  #9
    {"name": "CHECADOR RH", "ip": "172.16.1.40", "company": "33"},  #10 // Araceli
    {"name": "CHECADOR RECLUTAMIENTO BUSMEN", "ip": "172.16.1.37", "company": "33"},  #11
    {"name": "CHECADOR JURIDICO", "ip": "172.16.1.36", "company": "33"},  #12
    {"name": "CHECADOR SISTEMAS", "ip": "172.16.1.35", "company": "33"},  #13
    {"name": "CHECADOR GRUPO CONTROL", "ip": "172.16.1.34", "company": "33"},  #14
    {"name": "CHECADOR CHECADOR TALLER 2 L1", "ip": "172.16.1.33", "company": "67"},  #15
    {"name": "CHECADOR CHECADOR TALLER 2 L2", "ip": "172.16.1.32", "company": "59"},  #16
    {"name": "CHECADOR CUARTO MOTORES", "ip": "172.16.1.24", "company": "59"},  #17
    {"name": "CHECADOR TF PORTON NARANJA", "ip": "172.16.1.23", "company": "67"},  #18
]

port = 4370


checker = DeviceConnectivityChecker()
reachable = checker.check_device_connectivity_all(dispositivos)
# reachable_new = checker.check_device_connectivity_all(dispositivos)
user_name_login = Login_Busmen()


# Create your views here.
def login_busmen(request):
    if request.method == 'POST':
        # Verifica si hay datos en request.POST
        if request.POST:
            # Procesa los datos enviados por POST
            username = request.POST.get('username')
            user_name_login.validate_user(username)
            if user_name_login.getter_user():
                request.session['username'] = username
                return redirect('home')

    return render(request, 'login.html', None)


# region VIEW

def show_user_zkt_eco(request):
    """
        VALIDATE TO SESSION START
    """
    username = request.session.get('username')
    if not username:
        return redirect('login-busmen')

    # VARIABLE TO GET TEST TIME RESPONSE ENDPOINT
    now = datetime.now()

    all_users = []

    if len(reachable) == 0:
        return render(request, 'index.html',
                      {'usuarios': all_users, 'conn': False, 'msg': "NO HAY NINGUN DISPOSITIVO CONECTADO"})

    # INSTANCE TO USE ZKTECO FUNCTION
    zkt_eco = Zkteco()

    if request.method == "POST":
        # Procesar datos enviados en formato JSON
        data = json.loads(request.body)  # Carga los datos JSON del cuerpo
        user_id = data.get("user_id", None)

        if user_id:
            for things in reachable:
                if things["ping_status"]:
                    zkt_eco.delete_user(things["ip"], user_id["id"])
            return JsonResponse({'success': True, 'message': f'SE ELIMINO CON EXITO A {user_id["name"]}'})

    # GET TO IP TO DEVICE ON
    # ip_device = get_first_device()["ip"]

    # GET ALL USER TO FIRST DEVICE ON
    # all_new_user = zkt_eco.get_all_user(ip_device)

    # print( get_first_device() )
    check = get_first_device()["ip"]
    zk = ZK(check, port=port, timeout=10)
    # conn = None
    is_conn = False
    msg = ""

    try:
        conn = zk.connect()
    except Exception as e:
        msg = "Error en la coneccion: {e}"
        return render(request, 'index.html', {'usuarios': all_users, 'conn': is_conn, 'msg': msg})

    if conn is not None:
        try:

            conn.disable_device()

            user_zkt_eco = conn.get_users()

            busmen = get_user_to_api_busmen()

            for user in user_zkt_eco:
                result = [item for item in busmen["data"] if item['id'] == user.user_id]

                all_data_busmen = {
                    "exist_busmen": "SIN REGISTRO EN BUSMEN",
                    "activo": "?",
                    'name': user.name,
                }
                if len(result) > 0:
                    user_busmen = result[0]

                    all_data_busmen = {
                        'name': f"{user_busmen['apellido_paterno']} {user_busmen['apellido_materno']} {user_busmen['nombre']}",
                        "exist_busmen": "CON USAURIO EN BUSMEN",
                        "activo": "ACTIVO" if user_busmen["activo"] == "1" else "INACTIVO",
                        "puesto": user_busmen["puesto"],
                    }

                user_data = {
                    'user_id': user.uid,
                    'id': user.user_id,
                    'privilege': "USER" if user.privilege == 0 else "ADMIN",
                    **all_data_busmen
                }
                all_users.append(user_data)
            msg = f"REGISTROS TOTALES {len(all_users)} "
            conn.enable_device()
            conn.disconnect()

        except Exception as e:
            msg = f"Error al obtener usuarios: {e}"
            all_users = []
            conn.enable_device()
            conn.disconnect()

        is_conn = conn != None

    end_time = datetime.now()

    # Calcular la diferencia entre los dos tiempos
    time_difference = end_time - now
    print(f"TARDO UN TOTAL DE = {time_difference}")

    return render(request, 'index.html', {'usuarios': all_users, 'conn': is_conn, 'msg': msg})


def get_all_check_to_day(request):
    username = request.session.get('username')
    if not username:
        return redirect('login-busmen')

    start_data, start_time = get_date_and_time()
    end_data, end_time = get_date_and_time(True)
    date_start = request.POST.get('start-date', None)
    time_start = request.POST.get('start-time', None)
    date_end = request.POST.get('end-date', None)
    time_end = request.POST.get('end-time', None)

    if date_start and time_start:
        start_data = date_start
        start_time = time_start

    if date_end and time_end:
        end_data = date_end
        end_time = time_end

    data_time = {
        'start_date': start_data,
        'start_time': start_time,
        'end_date': end_data,
        'end_time': end_time,
    }

    now = datetime.now()

    dispositivo_ip = request.POST.get('dispositivo', "None")

    zkt_eco = Zkteco()

    all_registered_check = []
    validate_incidence = user_name_login.validate_incidence(data_time["start_date"], data_time["end_date"])["data"]
    if dispositivo_ip == "None":
        # WHEN NOT SELECT DEVICE

        for things in reachable:

            if things["ping_status"]:

                all_checks = zkt_eco.get_time_check_by_user(things["ip"])

                for check in all_checks:

                    if data_time["start_date"] <= check.timestamp.strftime("%Y-%m-%d") <= data_time["end_date"]:
                        all_registered_check.append({
                            "user_id": check.user_id,
                            "date": check.timestamp.strftime("%Y-%m-%d"),
                            "time": check.timestamp.strftime("%H:%M:%S")
                        })

    #print(all_registered_check)

    inicio = datetime.strptime(data_time["start_date"], "%Y-%m-%d")
    fin = datetime.strptime(data_time["end_date"], "%Y-%m-%d")

    # Imprimir fechas intermedias (excluyendo inicio y fin)
    fecha = inicio  #+ timedelta(days=1)

    all_users = get_user_to_api_busmen()["data"]
    
    new_check = []
    not_found = "F"

    while fecha <= fin:

        for usu in all_users:


            is_validate_user = handling_filter_user( int(usu["puesto_id"]) )

            if is_validate_user:

                check = [things for things in all_registered_check if
                         things["user_id"] == usu["id"] and things["date"] == fecha.strftime("%Y-%m-%d") ]

                if len(check) == 0:

                    incidence = [thin for thin in validate_incidence if
                                 thin["id_empleado"] == usu["id"] and thin["fecha"] == fecha.strftime("%Y-%m-%d")]
                    # print(f"{usu["apellido_paterno"]} {usu["apellido_materno"]} {usu["nombre"]}")
                    # print(usu["puesto"])
                    if usu["activo"] == "1" : # and usu["puesto"] == "CARROCERO B":
                        # print(usu)
                    # if usu["activo"] == "1":
                        new_check.append({
                            "id": usu["id"],
                            "name": f"{usu["apellido_paterno"]} {usu["apellido_materno"]} {usu["nombre"]}",
                            "puesto": usu["puesto"],
                            "name_device": usu["empresa_nombre"],
                            "date": fecha.strftime("%d-%m-%Y"),
                            "time": incidence[0]["nombre"] if len(incidence) > 0 else not_found,
                        })
                else:
                    for time_check in check:
                        info_check = {
                            "id": usu["id"],
                            "name": f"{usu["apellido_paterno"]} {usu["apellido_materno"]} {usu["nombre"]}",
                            "puesto": usu["puesto"],
                            "name_device": usu["empresa_nombre"],
                            "date": fecha.strftime("%d-%m-%Y"),
                            "time": time_check["time"],
                        }
                        new_check.append(info_check)

        fecha += timedelta(days=1)

    msg = f"REGISTROS TOTALES {len(new_check)}"

    end_time = datetime.now()

    time_difference = end_time - now

    print(f"TARDO UN TOTAL DE = {time_difference}")

    return render(request, 'checks_to_day.html', {
        'usuarios': new_check,
        'msg': msg,
        'dispositivo_seleccionado': dispositivo_ip,
        'dispositivos': reachable,
        **data_time
    })


def get_time_check_by_user(request):
    """
        This function is to report registro por usuario
    """
    username = request.session.get('username')
    if not username:
        return redirect('login-busmen')

    date_now = datetime.now()
    month_now = date_now.month
    year_now = date_now.year

    all_users = get_user_to_api_busmen()["data"]

    return render(request, 'time_check_by_user.html',
                  {'usuarios': all_users, "month_now": f"{month_now:02d}".strip(), "year_now": year_now})


def create_new_user(request):
    """
        This function is to report NUEVO USUARIO
    """
    username = request.session.get('username')
    if not username:
        return redirect('login-busmen')

    now = datetime.now()
    id_user = request.POST.get('user_id', None)
    name = request.POST.get('name', None)
    privilege = request.POST.get('privilege', None)
    all_users = get_user_to_api_busmen()["data"]
    msg = ""
    contex_view = {
        'dispositivos': reachable
    }
    if id_user is None:
        """
            INIT TO LOAD VIEW 
        """
        contex_view = {
            **contex_view,
            'usuarios': all_users,
            'msg': msg
        }

    if id_user is not None:
        """
            WHEN SEARCH USER BY UPDATE OR CREATE
        """
        zkt_eco = Zkteco()

        if name and privilege:
            for device in reachable:
                if device["ping_status"]:
                    zkt_eco.create_new_user(device["ip"], id_user, name, privilege)
            msg = f"EL USUARIO {name}, SE CREO CON EXITO EN TODOS LOS DISPOSITIVOS"

        ip_device = get_first_device()["ip"]
        # GETTER DATA USER BY FIRST DEVICE PING
        getter_user = zkt_eco.get_user(ip_device, id_user)

        # GETTER DATA USER ON API TO BUSMEN APP
        user_busmen = next(user for user in all_users if user.get('id') == id_user)

        """
            GET FINGER TO USER
        """

        all_find = []
        for index in range(10):
            cx = style_find[index]["cx"]
            cy = style_find[index]["cy"]
            label = style_find[index]["label"]

            all_find.append({
                'find': index,
                'registered': zkt_eco.get_finger_user(ip_device, id_user, index) is not None,
                'cx': cx,
                'cy': cy,
                'label': label
            })

        contex_view = {
            **contex_view,
            'usuarios': all_users,
            'msg': msg,
            'data': {
                **user_busmen,
                'privilege': 0 if getter_user is None else getter_user.privilege,
                'existed': getter_user is not None,
                'finger': all_find
            }
        }

    end_time = datetime.now()
    # Calcular la diferencia entre los dos tiempos
    time_difference = end_time - now
    print(f"TARDO UN TOTAL DE = {time_difference}")

    return render(request, 'register_new_user.html', contex_view)


def list_check_user(request):
    """
        This function is to report CHECK DEL DIA
    """
    username = request.session.get('username')
    if not username:
        return redirect('login-busmen')

    now = datetime.now()

    end_time = datetime.now()

    # Calcular la diferencia entre los dos tiempos
    time_difference = end_time - now
    print(f"TARDO UN TOTAL DE = {time_difference}")

    return render(request, 'check_to_day_users.html', {})


def show_device_pin(request):
    username = request.session.get('username')
    permission_synchronise = ["rigozodac"]
    # print(username)
    if not username:
        return redirect('login-busmen')

    reachable_all = checker.check_device_connectivity_all(dispositivos)

    if request.method == "POST":
        all_data = synchronize_devices(reachable_all)

        zk = ZK(all_data["ip"], port=port, timeout=10)

        conn = zk.connect()

        conn.disable_device()

        # users = conn.get_users()

        # # iteration user on device with more users
        # for user in users:
        #     # iteration all device with ping success
        #     for things in reachable:
        #         #
        #         if things["ip"] != all_data["ip"]:
        #             sync_user_and_fingers(all_data["ip"],things["ip"], int(user.uid), user)

        conn.enable_device()

        reachable_all = checker.check_device_connectivity_all(dispositivos)

    return render(request, 'device.html',
                  {'device': reachable_all, 'validate': username in permission_synchronise})


def add_finger(request):
    username = request.session.get('username')
    if not username:
        return redirect('login-busmen')

    dispositivo_ip = request.GET.get('dispositivo', None)
    id_user = request.GET.get('user_id', None)
    finger_index = request.GET.get('finger_index', None)

    all_users = get_user_to_api_busmen()["data"]
    zkt_eco = Zkteco()
    # user = zkt_eco.get_user(dispositivo_ip, id_user)

    msg = "SE REGISTRO LA HUELLA CON EXITO"
    try:
        zkt_eco.add_new_finger_user(dispositivo_ip, id_user, finger_index, reachable)
    except Exception as e:
        print(e)

    return render(request, 'register_new_user.html',
                  {'usuarios': all_users, 'msg': msg, 'data': None, 'dispositivos': reachable})


def delete_user_time_check(request, user_id):
    # username = request.session.get('username')

    msg = f'NO SE ENCONTRO NINGUN USUARIO CON EL ID'

    # INSTANCE TO USE ZKTECO FUNCTION
    zkt_eco = Zkteco()
    # Procesar datos enviados en formato JSON
    # print(user_id)
    if user_id:
        for things in reachable:
            if things["ping_status"]:
                # print("Hola", things["ip"])
                zkt_eco.delete_user(things["ip"], user_id)

        msg = f'SE ELIMINO CON EXITO '

    return JsonResponse({'success': True, 'message': msg})

def send_notification_push(request):

    title = request.GET.get("title")
    message = request.GET.get("message")
    id_user = request.GET.get("id_user", None )

    api_key_one_signal = "os_v2_app_fbfnz5zd6bgetcqyqaltyy3tkepnncpqobbe26m4hsmzi27lz7ladubv2clfumgdthaqptjf3k26lpuhmnob3q3qua254j6w7m5xlgq"
    app_id_one_signal = "284adcf7-23f0-4c49-8a18-80173c637351"

    try:
        headers = {
            "Content-Type": "application/json; charset=utf-8",
            "Authorization": f"Basic  {api_key_one_signal}"
        }

        id_sends = {"included_segments": ["All"]} if id_user is None else {"include_player_ids": id_user }

        payload = {
            "app_id": app_id_one_signal,
            "included_segments": ["All"],
            "headings": {"en": title},
            "contents": {"en": message}
        }

        response = requests.post(
            "https://onesignal.com/api/v1/notifications",
            headers=headers,
            data=json.dumps(payload)
        )
        # print(response)
        return JsonResponse({'success': True, "message":"Se envio la notificaion", "data":response.json() })

    except Exception as e:
        return  JsonResponse({'success': False, "message":f"Error: {e}", "data": None})



# endregion VIEW

# region CRUD DEVICE
def create_new_user_by_ip_address(ip_address, user_id, name, privilege):
    """
        FUNCTION TO CREATE USER IN DEVICE SENT TO PARAMS.
    :param ip_address: IP TO DEVICE FOR CONNECTION.
    :param user_id: ID TO SISTEM BUSMEN TO ADD AND CREATE NEW USER
    :param name:  NAME TO NEW USER
    :param privilege: NUMBER TO PRIVILEGE (0 -> USER, 14 -> ADMIN)
    """
    zk = ZK(ip_address, port=port, timeout=10)

    conn = zk.connect()

    conn.disable_device()

    conn.set_user(uid=int(user_id), user_id=user_id, name=name, privilege=int(privilege), password='', group_id='',
                  card=0)

    conn.enable_device()


def add_new_finger(ip_address, template, data_user):
    """
        FUNCTION TO CREATE FINGER IN DEVICE SENT TO PARAMS.
    :param ip_address: IP TO DEVICE FOR CONNECTION.
    :param template: ARRAY WITH FINGER REGISTERED TO USER.
    :param data_user:  USER TO SAVE FINGERS.
    """
    zk = ZK(ip_address, port=port, timeout=10)

    conn = zk.connect()

    conn.disable_device()

    conn.save_user_template(user=data_user, fingers=template)

    conn.enable_device()


def update_user(ip_address, user_id, name, privilege):
    """
        This function update privilege to user in device
    :param ip_address: IP TO DEVICE FOR CONNECTION.
    :param user_id: ID USER TO SAVE FINGERS.
    :param privilege: NUMBER TO PRIVILEGE (0 -> USER, 14 -> ADMIN)
    """
    zk = ZK(ip_address, port=port, timeout=10)
    conn = zk.connect()

    conn.disable_device()
    conn.set_user(
        uid=user_id,  # ID único del usuario en el dispositivo
        name=name,  # Nuevo nombre del usuario (opcional)
        password="",  # Nueva contraseña del usuario (opcional)
        privilege=privilege
    )

    conn.enable_device()


def synchronize_devices(data_device):
    """
    :param data_device: Data device online
    :return: Device with more user registered
    """
    more_user_device = None

    for things in data_device:

        if things["connection_status"]:
            zk = ZK(things["ip"], port=port, timeout=10)

            conn = zk.connect()

            conn.disable_device()

            users = conn.get_users()

            if not more_user_device:
                more_user_device = {
                    **things,
                    'len': len(users),
                }

            if more_user_device and len(users) > more_user_device['len']:
                more_user_device = {
                    **things,
                    'len': len(users),
                }

            conn.enable_device()

    return more_user_device

def week_report(request):

    busmen = get_user_to_api_busmen()

    check = get_first_device()["ip"]
    zk = ZK(check, port=port, timeout=10)
    conn = zk.connect()
    conn.disable_device()

    user_zkt_eco = conn.get_users()

    all_users = []
    for user in user_zkt_eco:
        result = [item for item in busmen["data"] if item['id'] == user.user_id]

        all_data_busmen = {
            "exist_busmen": "SIN REGISTRO EN BUSMEN",
            "activo": "?",
            'name': user.name,
        }
        if len(result) > 0:
            user_busmen = result[0]

            all_data_busmen = {
                'name': f"{user_busmen['apellido_paterno']} {user_busmen['apellido_materno']} {user_busmen['nombre']}",
                "puesto": user_busmen["puesto"],
            }
        user_data = {
            'id': user.user_id,
            **all_data_busmen
        }
        all_users.append(user_data)


    conn.enable_device()
    conn.disconnect()

    all_registered_check = []
    date_param = request.GET.get("date_param")
    fist_day = f"{date_param}"
    ultimate_day = f"{date_param}"
    validate_incidence = user_name_login.validate_incidence(fist_day, ultimate_day)["data"]
    # print(validate_incidence)
    zkt_eco = Zkteco()
    for things in reachable:

        if things["ping_status"]:

            all_checks = zkt_eco.get_time_check_by_user(things["ip"])

            for check in all_checks:
                if check.timestamp.year == 2025:
                    all_registered_check.append({
                        "user_id": check.user_id,
                        "date": check.timestamp.strftime("%Y-%m-%d"),
                        "time": check.timestamp.strftime("%H:%M:%S")
                    })

    check_week = []

    for user in all_users:
        # print(f"{user}")
        result = [item for item in all_registered_check if item['user_id'] == user['id']] if date_param is None else [item for item in all_registered_check if item['user_id'] == user['id'] and item['date'] == date_param]

        if len(result) == 0:

            insidence = [thing for thing in validate_incidence if user['id'] == thing['id_empleado'] ]
            print(f"{insidence}")
            if len(insidence) == 0:
                check_week.append({
                    "user_id": user['id'],
                    "data": []
                })
            else:
                check_week.append({
                    "user_id": user['id'],
                    "data": insidence
                })
        else:
            user["data"] = result
            check_week.append(user)


    return JsonResponse( { 'success': True, 'message': "La carga de usuarios fue exitosa.", "data": check_week } )

# endregion CRUD DEVICE

def get_data_user_html(request):
    username = request.session.get('username')
    if not username:
        return redirect('login-busmen')

    payload_new = None
    if request.method == "POST":
        payload = json.loads(request.body)

        payload_new = {
            'name': payload['name'],
            'id': payload['id'],
            'privilege': 0 if payload['privilege'] == "USER" else 1,
        }

    html_content = render(request, '../templates/modal_user_data.html', payload_new).content.decode('utf-8')
    return JsonResponse({'html': html_content})


def synchronize_user(request):
    username = request.session.get('username')
    if not username:
        return redirect('login-busmen')

    if request.method == 'POST':
        try:
            # Decodifica el cuerpo de la solicitud JSON
            body = json.loads(request.body)
            user_id = body.get('user_id')
            # print("user_id:", user_id)
            zkt_eco = Zkteco()
            if user_id:
                data_user_replic = []
                user_data_replic = None
                finger_user_replic = None
                for device in reachable:
                    user_data = zkt_eco.get_user(device["ip"], user_id)
                    # print( device["name"], user_data)
                    if user_data is None:
                        data_user_replic.append(device)
                    elif user_data_replic is None:
                        user_data_replic = user_data
                        for things in range(10):
                            finger = zkt_eco.get_finger_user(device["ip"], user_id, things)
                            # print(finger)
                            if finger:
                                finger_user_replic = finger

                for things in data_user_replic:
                    # print(f"COPIAR USUARIO {user_data_replic.name} A ESTE DISPOSITIVO \n",things)
                    # print("finger data user", finger_user_replic.fid, finger_user_replic)
                    zkt_eco.create_new_user(things["ip"], user_data_replic.user_id, user_data_replic.name,
                                            user_data_replic.privilege)
                    zkt_eco.update_finger_user(things["ip"], int(user_data_replic.user_id), finger_user_replic)

                return JsonResponse({'success': True, 'message': f'USUARIO SINCRONIZADO CORRECTAMENTE'})

        except json.JSONDecodeError:
            return JsonResponse({'success': False, 'message': 'Invalid JSON data'})

    return JsonResponse({'success': False, 'message': 'Invalid request'})


def synchronize_user_all(request):
    username = request.session.get('username')

    if not username:
        return redirect('login-busmen')

    reachable_all = reachable  #checker.check_device_connectivity_all(dispositivos)

    device_more_user = None
    for things in reachable_all:
        # print(things)
        if things["ping_status"] and device_more_user is None:
            device_more_user = things
        elif things["ping_status"] and things["users"] and things["users"] > device_more_user["users"]:
            device_more_user = things

    zkt_eco = Zkteco()

    # print(device_more_user)
    all_user = zkt_eco.get_all_user(device_more_user["ip"])

    for user in all_user:

        for device in reachable_all:

            try:
                if device["ping_status"] and device["ip"] != device_more_user["ip"]:
                    is_user = zkt_eco.get_user(device["ip"], user.user_id)

                    # print(f"user {user.name} device more {device_more_user["name"]} copy to {device["name"]}")
                    if is_user is None:
                        finger_user = zkt_eco.finger_template_user(device_more_user["ip"], int(user.user_id))

                        zkt_eco.create_new_user(device["ip"], user.user_id, user.name, user.privilege)
                        # print(f"user {user.name} device more {device_more_user["name"] } copy to {device["name"]}")
                        for finger in finger_user:
                            zkt_eco.update_finger_user(device["ip"], int(user.user_id), finger)
            except Exception as e:
                print(e)

    return JsonResponse({'success': False, 'message': 'Invalid request'})


def get_first_device():
    first_device = None

    for device in reachable:
        # print(device)
        if first_device is None and device["ping_status"]:
            first_device = device
    return first_device


def create_history_time_check(request, user_id, month_send):
    username = request.session.get('username')
    if not username:
        return redirect('login-busmen')

    zkt_eco = Zkteco()

    data_select = f"{month_send}-01"

    attendance_user = []

    date_now = datetime.strptime(data_select, "%Y-%m-%d")

    fist_day, ultimate_day = get_first_day_and_ultimate_day(date_now)

    for device in reachable:
        if device["ping_status"]:
            attendence = zkt_eco.get_time_check_by_user(device["ip"], user_id)
            if len(attendence) > 0:
                for att in attendence:
                    # print( att.timestamp, device["name"] )
                    if fist_day <= att.timestamp <= ultimate_day:
                        attendance_user.append({'date': att.timestamp, 'temperature': device["name"]})

    day = ultimate_day.day
    month = fist_day.month if fist_day.month > 9 else f"0{fist_day.month}"

    att_user = []
    for things in range(day):
        new_things = things + 1
        is_existing = [old for old in attendance_user if old['date'].day == new_things]

        count = new_things if new_things > 9 else f"0{new_things}"
        if len(is_existing) > 0:
            text = ""
            for old in is_existing:
                hour = old['date'].hour if old['date'].hour > 9 else f"0{old['date'].hour}"
                minute = old['date'].minute if old['date'].minute > 9 else f"0{old['date'].minute}"
                second = old['date'].second if old['date'].second > 9 else f"0{old['date'].second}"

                text = text + f"| {hour}:{minute}:{second} |"

            att_user.append({'date': f"{fist_day.year}-{month}-{count}", 'temperature': text})
        else:
            att_user.append({'date': f"{fist_day.year}-{month}-{count}", 'temperature': "SIN REGISTRO"})

    return JsonResponse({'success': True, 'message': 'Hola', 'data': att_user, 'date_select': month_send})


def handling_synchronize_date_device(request):
    username = request.session.get('username')
    if not username:
        return redirect('login-busmen')

    msg = ""

    for device in reachable:
        if device["ping_status"]:
            zk = ZK(device["ip"], port=port, timeout=10)
            conn = zk.connect()
            conn.disable_device()

            device_time = conn.get_time()

            zona_horaria = pytz.timezone('America/Mexico_City')
            fecha_actual = datetime.now(zona_horaria)

            hora_actual = fecha_actual.time().replace(microsecond=0)

            hora_dispositivo = device_time.time().replace(microsecond=0)

            if hora_dispositivo == hora_actual:
                # print("Las horas coinciden")
                msg += f"{device['name']}:\nTiene la hora y fecha correcta\n"
            else:
                # print("Las horas son diferentes")
                msg += f"{device['name']}:\n fecha incorrecta {device_time}, se actualizo por {hora_actual} \n"
                conn.set_time(fecha_actual)
            conn.enable_device()

    return JsonResponse({'success': True, 'message': msg})


def handling_check_to_days(request, date_send):
    now = datetime.now()
    # print(f"init -> {now}")
    zkt_eco = Zkteco()
    ip_device = get_first_device()["ip"]

    users_list = zkt_eco.get_all_user(ip_device)

    attendance_user = []
    #date_now = datetime.now().date()
    date_now = datetime.strptime(date_send, "%Y-%m-%d").date()
    # print(f"date select {date_send} {date_now}")

    for user in users_list:
        check_device_now = [
            {"date": att.timestamp.strftime("%d/%m/%y"), 'hour': att.timestamp.strftime("%H:%M:%S"),
             "device": device["name"]}
            for device in reachable if device["ping_status"]
            for att in zkt_eco.get_time_check_by_user(device["ip"], user.user_id)
            if att.timestamp.date() == date_now
        ]
        attendance_user.append({"user": user.name, "check": check_device_now})

    end_time = datetime.now()

    # Calcular la diferencia entre los dos tiempos
    time_difference = end_time - now
    print(f"TARDO UN TOTAL DE = {time_difference}")

    return JsonResponse({'success': True, 'message': 'Datos cargados con exito', 'data': attendance_user})

def handling_filter_user(remove_id):
    """
    User not check time
    """
    # contralor de ruta     | 17
    # inplant               | 50
    # supervisores          | 1
    # coordinadores de ruta | 84

    if( remove_id == 17 ):
        return False

    if( remove_id == 50 ):
        return False

    if( remove_id == 1 ):
        return False

    if( remove_id == 84 ):
        return False


    return True


def get_data_user_by_week(request):

    # print("param",request.GET.get('init'))

    data_select = request.GET.get('init') #date.today()
    # print("=>",data_select)

    it_week = True

    all_users = get_user_to_api_busmen()["data"]

    date_now = datetime.strptime(str(data_select), "%Y-%m-%d")

    first_day, ultimate_day = get_first_and_last_day_of_week(date_now) if it_week else get_first_day_and_ultimate_day(date_now)

    # print(first_day, ultimate_day )

    validate_incidence = user_name_login.validate_incidence(first_day, ultimate_day)["data"]

    users_list = []

    zkt_eco = Zkteco()

    all_registered_check = []
    for things in reachable:

        if things["ping_status"]:

            all_checks = zkt_eco.get_time_check_by_user(things["ip"])

            for check in all_checks:
                # print(first_day >= check.timestamp <= ultimate_day, F"{first_day} >= {check.timestamp} <= {ultimate_day}")
                if first_day <= check.timestamp <= ultimate_day:
                    all_registered_check.append({
                        "user_id": check.user_id,
                        "date": check.timestamp,
                        "time": check.timestamp.strftime("%H:%M:%S")
                    })

    for user in all_users:
        data_user = get_check_to_month_new( user["id"], first_day , ultimate_day, validate_incidence, all_registered_check )
        data_user["puesto"] = user["puesto"]
        data_user["nombre"] = f"{user['apellido_paterno']} {user['apellido_materno']} {user['nombre']}"
        users_list.append(data_user)

    ultimate_day_cal = calendar.monthrange(ultimate_day.year, ultimate_day.month)[1]
    collection_month = []
    collection_month.append({"headerName": "NOMBRE", "field": "nombre"})
    collection_month.append({"headerName": "Puesto", "field": "puesto"})
    current_day = first_day
    while current_day <= ultimate_day:
        fecha_formateada = f"{current_day.year}-{current_day.month:02d}-{current_day.day:02d}"
        fecha = f"{current_day.day:02d}-{current_day.month:02d}-{current_day.year}"
        collection_month.append({"headerName": fecha, "field": fecha_formateada})
        # print(fecha)
        current_day += timedelta(days=1)
    # for d in range(first_day.day, first_day.day + 1):
    #     fecha_formateada = f"{ultimate_day.year}-{ultimate_day.month:02d}-{d:02d}"
    #     collection_month.append({"headerName": fecha_formateada, "field": fecha_formateada})

    nombre_mes = f"{first_day.strftime("%d/%m/%Y")} - {ultimate_day.strftime("%d/%m/%Y")}"

    # print(users_list)

    return JsonResponse({'success': True, 'message': 'Hola', 'data': users_list, 'days': collection_month,  'month': nombre_mes })



acciones = {
    "Retardo llegada a las": lambda: "R",
    "Permiso para salir anticipadamente": lambda: "PSA",
    "Permiso por matrimonio": lambda: "PM",
    "Permiso por defunción": lambda: "PD",
    "Permiso sin sueldo": lambda: "PSG",
    "Permiso con sueldo": lambda: "PCG",
    "Vacaciones": lambda: "V",
    "Permiso por departamento medico": lambda: "PDM",
    "Cambio de horario": lambda: "CH",
    "Indisciplina": lambda: "Indisciplina",
    "Ineficiencia": lambda: "Ineficiencia",
    "Mala calidad y/o desperdicio": lambda: "Mala calidad y/o desperdicio",
    "otros": lambda: "otros",
    "Incapacidad": lambda: "I",
}
def get_check_to_month(id_user, fist_day, ultimate_day, validate_incidence, attendance_user ):

    day = ultimate_day.day
    month = fist_day.month if fist_day.month > 9 else f"0{fist_day.month}"

    att_user = {}
    # print(f"fist_day {fist_day} ultimate_day {ultimate_day}")
    for things in range(day):
        new_things = things + 1
        is_existing = [old for old in attendance_user if old['date'].day == new_things and old['user_id'] == id_user]

        count = new_things if new_things > 9 else f"0{new_things}"

        if id_user == 16723:
            print(is_existing)
        if len(is_existing) > 0:

            att_user[f"{fist_day.year}-{month}-{count}"] = "A"

        else:
            incidence = [thin for thin in validate_incidence if
                         thin["id_empleado"] == id_user and thin["fecha"] == f"{fist_day.year}-{month}-{count}"]

            inciden = acciones.get(incidence[0]["nombre"], lambda: "N/A")() if len(incidence) > 0 else "F"

            att_user[f"{fist_day.year}-{month}-{count}"] = inciden

    return att_user

def get_check_to_month_new(id_user, first_day, ultimate_day, validate_incidence, attendance_user):
    """
    Devuelve un dict con claves 'YYYY-MM-DD' para cada día desde first_day hasta ultimate_day (incluyendo ambos),
    el valor será:
      - "A" si en attendance_user existe asistencia para ese id_user en esa fecha
      - acciones.get(nombre, lambda: "N/A")() si hay una incidencia para ese id_user en esa fecha
      - "F" si no hay ni asistencia ni incidencia

    Se asume que:
      - first_day y ultimate_day son datetime o date
      - attendance_user entries tienen 'date' (datetime o 'YYYY-MM-DD' string) y 'user_id'
      - validate_incidence entries tienen 'id_empleado' y 'fecha' (datetime o 'YYYY-MM-DD' string) y 'nombre'
      - existe un diccionario/función `acciones` en el scope que mapea nombres a funciones o valores
    """

    # Normalizar first_day y ultimate_day a objetos date
    def to_date(d):
        if isinstance(d, datetime):
            return d.date()
        if isinstance(d, date):
            return d
        # si es string, intentar parsear 'YYYY-MM-DD' o 'YYYY-MM-DD HH:MM:SS'
        return datetime.strptime(str(d).split()[0], "%Y-%m-%d").date()

    start = to_date(first_day)
    end = to_date(ultimate_day)

    # Preparar estructuras rápidas para búsqueda
    # attendance_user: convertir a set de dates solo para el usuario id_user
    att_dates = set()
    for a in attendance_user:
        if a.get('user_id') != id_user:
            continue
        d = a.get('date')
        try:
            att_dates.add(to_date(d))
        except Exception:
            # ignorar entradas mal formateadas
            continue

    # validate_incidence: mapear (id_empleado, date) -> nombre
    inc_map = {}
    for inc in validate_incidence:
        try:
            d = to_date(inc.get('fecha'))
            key = (inc.get('id_empleado'), d)
            inc_map[key] = inc.get('nombre')
        except Exception:
            continue

    att_user = {}
    current = start
    one_day = timedelta(days=1)

    while current <= end:
        key_str = current.strftime("%Y-%m-%d")

        if current in att_dates:
            att_user[key_str] = "A"
        else:
            nombre = inc_map.get((id_user, current))
            if nombre:
                # acciones debe estar definido en tu scope; mantener tu comportamiento
                att_user[key_str] = acciones.get(nombre, lambda: "N/A")()
            else:
                att_user[key_str] = "F"

        current += one_day

    return att_user
