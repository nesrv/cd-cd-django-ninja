from django.urls import path
from shop.api import api
from shop.views import products_django

urlpatterns = [
    path("api/", api.urls),
    path("products-django/", products_django),
]
