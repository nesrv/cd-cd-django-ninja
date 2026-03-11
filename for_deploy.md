# CI/CD: GitHub Actions → VPS

## Схема работы

```
git push → GitHub Actions → SSH на VPS (deploy user) → git pull → docker compose up
```

Пушишь в `main` — через ~30 сек новая версия уже на сервере.

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
curl http://localhost/api/health
# {"status": "ok"}
```

Сайт доступен по адресу: `http://81.90.182.174`

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

1. Делаешь `git push origin main`
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
docker-compose.prod.yml   ← для VPS (порт 80)
Dockerfile                ← сборка Django-приложения
.github/workflows/deploy.yml  ← CI/CD pipeline
```

---

## Бенчмарки

```bash
ab -n 10000 -c 100 http://81.90.182.174/api/products
wrk -t4 -c200 -d30s http://81.90.182.174/api/products
wrk -t4 -c200 -d30s http://81.90.182.174/api/health
```
