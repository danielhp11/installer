import os
from zk import ZK

class DeviceConnectivityChecker:

    # STATIC VARIABLE GLOBAL TO SAVE INSTANCE UNIQUE
    _instance = None

    def __new__(cls, *args, **kwargs):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def ping_device(self, ip_address):
        """Realiza un ping al dispositivo y retorna True si responde."""
        response = os.system(f"ping -c 1 {ip_address}" if os.name != 'nt' else f"ping -n 1 {ip_address}")
        return response == 0

    def check_device_connectivity(self, devices, timeout=10):
        """Verifica la conectividad con los dispositivos ZKTeco."""
        reachable_devices = []
        port = 4370  # Cambia el puerto si es necesario

        for device in devices:
            ip_address = device["ip"]
            try:
                # Paso opcional: Verificar si responde al ping
                if not self.ping_device(ip_address):
                    continue

                # Intentar conexión al dispositivo ZKTeco
                zk = ZK(ip_address, port=port, timeout=timeout)
                conn = zk.connect()
                conn.disconnect()  # Desconectar si la conexión es exitosa
                reachable_devices.append(device)
            except Exception:
                pass

        return reachable_devices

    def check_device_connectivity_all(self, devices, timeout=10):
        """Verifica la conectividad con los dispositivos ZKTeco y devuelve su estado."""
        reachable_devices = []
        port = 4370  # Cambia el puerto si es necesario

        for device in devices:
            ip_address = device["ip"]
            device_status = {**device,"ping_status": False, "connection_status": False}

            try:
                # Verificar si responde al ping
                if self.ping_device(ip_address):
                    device_status["ping_status"] = True

                    # Intentar conexión al dispositivo ZKTeco
                    zk = ZK(ip_address, port=port, timeout=timeout)
                    conn = zk.connect()
                    users = conn.get_users()
                    # print("user ->", len(users))
                    device_status = {**device_status, 'users': len(users)}
                    conn.disconnect()  # Desconectar si la conexión es exitosa
                    device_status["connection_status"] = True
            except Exception:
                device_status = {**device_status, 'users': 0}

            reachable_devices.append(device_status)

        return reachable_devices