from django.http import JsonResponse
from .models import VideoCard

def products_django(request):
    data = list(VideoCard.objects.values("id", "name", "price", "description"))
    return JsonResponse({"products": data})