from ninja import NinjaAPI, Schema
from .models import VideoCard

api = NinjaAPI(urls_namespace="api")

class ProductOut(Schema):
    id: int
    name: str
    price: float
    description: str

@api.get("/products", response=list[ProductOut])
def list_products(request):
    return list(VideoCard.objects.values("id", "name", "price", "description"))

@api.get("/products/{product_id}", response=ProductOut)
def get_product(request, product_id: int):
    p = VideoCard.objects.get(id=product_id)
    return {"id": p.id, "name": p.name, "price": float(p.price), "description": p.description or ""}

@api.get("/health")
def health(request):
    return {"status": "ok"}