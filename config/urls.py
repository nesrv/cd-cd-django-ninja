from django.urls import path
from shop.api import api
from shop.views import home, products_partial

urlpatterns = [
    path("", home),
    path("partials/products/", products_partial),
    path("api/", api.urls),
]
