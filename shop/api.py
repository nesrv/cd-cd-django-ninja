from ninja import NinjaAPI, Schema
from django.shortcuts import get_object_or_404
from .models import VideoCard

api = NinjaAPI(urls_namespace="api")


class ProductOut(Schema):
    id: int
    name: str
    price: float
    description: str


@api.get("/products", response=list[ProductOut])
def list_products(request):
    return VideoCard.objects.all()


@api.get("/products/{product_id}", response=ProductOut)
def get_product(request, product_id: int):
    return get_object_or_404(VideoCard, id=product_id)


@api.get("/health")
def health(request):
    return {"status": "ok"}