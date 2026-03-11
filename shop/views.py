from django.shortcuts import render
from .models import VideoCard


def home(request):
    return render(request, "shop/home.html")


def products_partial(request):
    products = VideoCard.objects.all()
    return render(request, "shop/products_list.html", {"products": products})