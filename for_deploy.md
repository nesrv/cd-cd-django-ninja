# CI/CD: GitHub Actions → VPS

## Схема работы

```
git push → GitHub Actions → SSH на VPS (deploy user) → git pull → docker compose up
```

Пушишь в `master` — через ~30 сек новая версия уже на сервере.

---

## 1. Первоначальная настройка VPS (один раз, под root)

### Подключиться к VPS:
```bash
ssh root@81.90.182.174
```

### Установить Docker:
```bash
curl -fsSL https://get.docker.com | sh
```

### Создать пользователя (если ещё нет) и дать доступ к Docker:
```bash
id alekseeva || adduser --disabled-password --gecos "" alekseeva
echo "alekseeva:alekseeva" | chpasswd
usermod -aG docker alekseeva
```

### Создать директорию проекта и отдать deploy:
```bash
mkdir -p /opt/shop
chown alekseeva:alekseeva /opt/shop
```

### Переключиться на deploy и склонировать:
```bash
su - alekseeva
cd /opt/shop
git clone https://github.com/nesrv/cd-cd-django-ninja.git .
```

### Запустить:
```bash
docker compose -f docker-compose.prod.yml up --build -d
```

### Проверить:
```bash
curl http://localhost:8080/api/health
# {"status": "ok"}
```

Сайт доступен по адресу: `http://81.90.182.174:8080`

---

## 2. Настройка GitHub Secrets

В репозитории на GitHub: **Settings → Secrets and variables → Actions → New repository secret**

Добавить три секрета:

| Имя              | Значение          |
|------------------|-------------------|
| `VPS_HOST`       | `81.90.182.174`   |
| `VPS_USER`       | `alekseeva`       |
| `VPS_PASSWORD`   | `alekseeva`       |

---

## 3. Как работает деплой

После настройки — всё автоматически:

1. Делаешь `git push origin master`
2. GitHub Actions подключается к VPS по SSH
3. Выполняет `git pull` + `docker compose up --build -d`
4. Новая версия запущена

### Файл workflow: `.github/workflows/deploy.yml`

---

## 4. Полезные команды на VPS

```bash
# Посмотреть логи
docker compose -f docker-compose.prod.yml logs -f

# Перезапустить
docker compose -f docker-compose.prod.yml restart

# Остановить
docker compose -f docker-compose.prod.yml down

# Пересобрать с нуля
docker compose -f docker-compose.prod.yml up --build -d

# Зайти в контейнер Django
docker compose -f docker-compose.prod.yml exec web bash

# Зайти в PostgreSQL
docker compose -f docker-compose.prod.yml exec db psql -U postgres shop
```

---

## 5. Структура файлов

```
docker-compose.yml        ← для локальной разработки (порт 8000)
docker-compose.prod.yml   ← для VPS (порт 8080)
Dockerfile                ← сборка Django-приложения
.github/workflows/deploy.yml  ← CI/CD pipeline
```

---

## Бенчмарки

```bash
ab -n 10000 -c 100 http://81.90.182.174:8080/api/products
wrk -t4 -c200 -d30s http://81.90.182.174:8080/api/products
wrk -t4 -c200 -d30s http://81.90.182.174:8080/api/health
```

### Результат wrk (gunicorn, 3 воркера, PostgreSQL):

```
wrk -t4 -c200 -d30s http://81.90.182.174:8080/api/products

  4 threads and 200 connections
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     1.06s   560.98ms   1.99s    60.63%
    Req/Sec    17.51     11.34    60.00     59.31%
  1658 requests in 33.11s, 2.54MB read
  Socket errors: connect 0, read 0, write 0, timeout 1531
Requests/sec:     50.08
Transfer/sec:     78.45KB
```

### Результат ab (gunicorn, 3 воркера, PostgreSQL):

```
ab -n 10000 -c 100 http://81.90.182.174:8080/api/products

Server Software:        gunicorn
Concurrency Level:      100
Time taken for tests:   301.733 seconds
Complete requests:      10000
Failed requests:        0
Requests per second:    33.14 [#/sec] (mean)
Time per request:       3017.333 [ms] (mean)

  50%   2084
  66%   2359
  75%   3217
  90%   5224
  95%   7192
  99%  13388
 100%  17572 (longest request)
```

**Проблемы:**
- **50 req/s** — мало, 1531 таймаут из 1658 запросов
- 3 синхронных воркера Gunicorn не справляются с 200 соединениями
- Нет пула соединений к PostgreSQL — каждый запрос открывает новое подключение

---

## Оптимизация

### 1. Увеличить воркеры и переключить на uvicorn (асинхронный режим)

В `docker-compose.prod.yml` заменить command:
```yaml
command: >
  sh -c "python manage.py migrate &&
         python load_data.py &&
         uvicorn config.asgi:application --host 0.0.0.0 --port 8000 --workers 4"
```

Django Ninja нативно поддерживает async — uvicorn обрабатывает множество соединений в одном процессе без блокировки.

### 2. Добавить пул соединений к PostgreSQL

Установить `django-pgconnpool` или использовать встроенный `CONN_MAX_AGE` в `settings.py`:

```python
DATABASES = {
    'default': {
        ...
        'CONN_MAX_AGE': 600,  # держать соединение 10 минут
    }
}
```

Или через `dj-database-url`:
```python
DATABASES = {
    'default': dj_database_url.config(
        default='postgresql://postgres:postgres@localhost:5432/shop',
        conn_max_age=600,
    )
}
```

### 3. Ожидаемый результат

| Метрика        | До        | После (ожидание) |
|---------------|-----------|-------------------|
| Req/sec       | 50        | 250–500+          |
| Avg Latency   | 1.06s     | 100–400ms         |
| Timeouts      | 1531      | 0                 |
