from django.urls import path
from . import main

urlpatterns = [
    path('', main.read_root, name='read_root'),
] 