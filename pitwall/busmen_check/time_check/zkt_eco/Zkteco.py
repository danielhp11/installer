from zk import ZK

class Zkteco:
    port = 4370
    def __init__(self, **kwargs):
        pass

    def get_user(self, ip_device = None, id_user = None):
        """
            THIS FUNCTION GET USER
        :return:
        """
        if ip_device is None or id_user is None:
            return None

        zk = ZK(ip_device, port=self.port, timeout=10)
        conn = zk.connect()
        conn.disable_device()
        users = conn.get_users()
        user = next((u for u in users if u.user_id == id_user), None)
        conn.enable_device()
        return user

    def get_all_user(self, ip_device = None,):
        zk = ZK(ip_device, port=self.port, timeout=10)
        conn = zk.connect()
        conn.disable_device()
        users = conn.get_users()
        conn.enable_device()
        return users

    def create_new_user(self, ip_device = None, id_user = None, name= None, privilege = None, password_new = "", group_id_new = "", card_new = 0):
        """
               FUNCTION TO CREATE USER IN DEVICE SENT TO PARAMS.
           :param ip_address: IP TO DEVICE FOR CONNECTION.
           :param user_id: ID TO SYSTEM BUSMEN TO ADD AND CREATE NEW USER
           :param name:  NAME TO NEW USER
           :param privilege: NUMBER TO PRIVILEGE (0 -> USER, 14 -> ADMIN)
           """
        zk = ZK(ip_device, port=self.port, timeout=10)

        conn = zk.connect()

        conn.disable_device()

        conn.set_user(uid=int(id_user), user_id=id_user, name=name, privilege=int(privilege) )

        conn.enable_device()


    def add_new_finger_user(self,ip_device = None ,id_user = None, id_finger_user = None, devices = None):
        """
            THIS FUNCTION GET ALL FINGER REGISTERED USER
        :return:
        """
        if ip_device is None or id_user is None and id_finger_user is None:
            return None
        zk = ZK(ip_device, port=self.port, timeout=10)
        conn = zk.connect()

        conn.disable_device()

        try:
            conn.enroll_user(int(id_user), int(id_finger_user))
        except:
            print("Failed to add new finger user")


        finger_template = self.get_finger_user(ip_device, id_user, id_finger_user)

        conn.enable_device()

        if finger_template:
            for device in devices:
                if device["ip"] != ip_device:
                    zk = ZK(device["ip"], port=self.port, timeout=10)
                    conn = zk.connect()
                    conn.disable_device()
                    conn.save_user_template(user=int(id_user),fingers=finger_template)
                    conn.enable_device()
                    # print(device)

    def get_finger_user(self, ip_device = None, id_user = None, index_finger = None):
        if ip_device is None and id_user is None and index_finger is None :
            return None
        zk = ZK(ip_device, port=self.port, timeout=10)
        conn = zk.connect()
        conn.disable_device()

        finger_registered = conn.get_user_template(int(id_user), int(index_finger))

        conn.enable_device()

        return finger_registered

    def update_finger_user(self, device_ip, user_id, finger_user):
        zk = ZK(device_ip, port=self.port, timeout=10)
        conn = zk.connect()
        conn.disable_device()
        conn.save_user_template(user=int(user_id), fingers=finger_user)
        conn.enable_device()

    def finger_template_user(self, ip_device = None, id_user = None):
        zk = ZK(ip_device, port=self.port, timeout=10)
        conn = zk.connect()
        conn.disable_device()
        data_finger = []
        for index in range(10):
            finger_template = conn.get_user_template(uid=id_user, temp_id=index)
            if finger_template is not None:
                data_finger.append(finger_template)
        conn.enable_device()
        return  data_finger

    def get_time_check_by_user(self, ip_device, id_user=None):
        zk = ZK(ip_device, port=self.port, timeout=10)
        conn = zk.connect()
        conn.disable_device()

        attendances = conn.get_attendance()
        if id_user is not None:
            user_attendance = [att for att in attendances if int(att.user_id) == int(id_user) ]
        else:
            user_attendance = [att for att in attendances]

        conn.enable_device()

        return  user_attendance

    def delete_user(self, ip_address, user_id):
        zk = ZK(ip_address, port=self.port, timeout=10)
        conn = zk.connect()

        conn.disable_device()
        users = conn.get_users()
        user_exists = any(int(user.user_id) == int(user_id) for user in users)
        print(user_exists)

        if user_exists:
            # Eliminar usuario si existe
            conn.delete_user(user_id=user_id)

        conn.enable_device()