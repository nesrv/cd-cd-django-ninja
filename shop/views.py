from django.http import JsonResponse
from django.shortcuts import render
from .models import VideoCard

def home(request):
    return render(request, "shop/home.html")

def products_django(request):
    data = list(VideoCard.objects.values("id", "name", "price", "description"))
    return JsonResponse({"products": data})