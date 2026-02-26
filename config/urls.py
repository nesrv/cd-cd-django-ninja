from django.urls import path
from shop.api import api
from shop.views import home, products_django

urlpatterns = [
    path("", home),
    path("api/", api.urls),
    path("products-django/", products_django),
]
