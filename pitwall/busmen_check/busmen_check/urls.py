"""
URL configuration for busmen_check project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.1/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path
from time_check import views


urlpatterns = [
    path('admin/', admin.site.urls),
    path('', views.show_user_zkt_eco, name="home"),
    path('login-busmen/', views.login_busmen, name="login-busmen"),
    path('index/', views.show_user_zkt_eco, name="home"),
    path('check-to-day/', views.get_all_check_to_day, name="check-to-day"),
    path('check-to-day-users/', views.list_check_user, name="check-to-day-users"),
    path('check-to-day/<int:user_id>/<str:month_send>/', views.create_history_time_check, name="check-to-day-id"),
    path('check-to-day-by-user/', views.get_time_check_by_user, name="check-to-day-by-user"),
    path('check-time-to-user/<str:date_send>/', views.handling_check_to_days, name="check-time-to-user"),
    path('new-user/', views.create_new_user, name="new-user"),
    path('add-new-finger/', views.add_finger, name="add-new-finger"),
    path('device-ping/', views.show_device_pin, name="device-ping"),
    path('data-user/', views.get_data_user_html, name="data-user"),
    path('synchronize-user/', views.synchronize_user, name="synchronize-user"),
    path('synchronize-user-all/', views.synchronize_user_all, name="synchronize-user-all"),
    path('delete-user/<int:user_id>/', views.delete_user_time_check, name="delete-user"),
    path('synchronize-date-device/', views.handling_synchronize_date_device, name="synchronize-date-device"),
    path('send-push-msg/', views.send_notification_push , name="send-push-msg"),
    # path('delete-user/<int:id_user>', views.send_notification_push , name="delete-user"),

    path('week-report/', views.week_report , name="week-report"),
    path('get-data-user-by-week/', views.get_data_user_by_week , name="get-data-user-by-week"),
]


