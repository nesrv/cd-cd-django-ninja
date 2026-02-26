ab -n 10000 -c 1000 https://cd-cd-django-ninja-production.up.railway.app/api/products
ab -n 10000 -c 1000 https://cd-cd-django-ninja-production.up.railway.app/products-django/

ab -n 10000 -c 100 http://127.0.0.1:8000/api/products


http://127.0.0.1:8000

uvicorn config.asgi:application --host 127.0.0.1 --port 8000


pip install waitress
waitress-serve --port=8000 config.wsgi:application