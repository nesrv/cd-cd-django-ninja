"""Загружает data.sql в БД. Запуск: python load_data.py"""
import sqlite3

conn = sqlite3.connect('db.sqlite3')
with open('data.sql', encoding='utf-8') as f:
    conn.executescript(f.read())
conn.close()
print('Данные загружены.')
