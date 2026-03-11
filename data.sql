-- PostgreSQL 17+ совместимый синтаксис
-- GENERATED ALWAYS AS IDENTITY, DATE, NUMERIC, TEXT, CHECK, REFERENCES

-- Пользователи (user_id — для NATURAL JOIN с orders, cart_items)
CREATE TABLE users (
    user_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        TEXT NOT NULL,
    created_at  DATE NOT NULL DEFAULT CURRENT_DATE
);

-- Товары (product_id — для NATURAL JOIN с cart_items)
CREATE TABLE products (
    product_id  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name        TEXT NOT NULL,
    price       NUMERIC(12, 2) NOT NULL CHECK (price >= 0),
    description TEXT,
    created_at  DATE NOT NULL DEFAULT CURRENT_DATE
);

-- Заказы 
CREATE TABLE orders (
    order_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     BIGINT NOT NULL REFERENCES users (user_id),
    status      TEXT NOT NULL DEFAULT 'ожидает'
        CHECK (status IN ('ожидает', 'подтверждён', 'отправлен', 'доставлен', 'отменён', 'возвращён')),
    total       NUMERIC(12, 2) NOT NULL CHECK (total >= 0),
    created_at  DATE NOT NULL DEFAULT CURRENT_DATE,
    updated_at  DATE NOT NULL DEFAULT CURRENT_DATE
);

-- Позиции корзины 
CREATE TABLE cart_items (
    cart_item_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id     BIGINT NOT NULL REFERENCES users (user_id),
    product_id  BIGINT NOT NULL REFERENCES products (product_id),
    quantity    INT NOT NULL CHECK (quantity > 0),
    price       NUMERIC(12, 2) NOT NULL CHECK (price >= 0),
    created_at  DATE NOT NULL DEFAULT CURRENT_DATE,
    UNIQUE (user_id, product_id)
);

-- Позиции заказа 
CREATE TABLE order_items (
    order_item_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id      BIGINT NOT NULL REFERENCES orders (order_id),
    product_id    BIGINT NOT NULL REFERENCES products (product_id),
    quantity      INT NOT NULL CHECK (quantity > 0),
    price         NUMERIC(12, 2) NOT NULL CHECK (price >= 0)
);

CREATE INDEX idx_orders_user_id ON orders (user_id);
CREATE INDEX idx_orders_status ON orders (status);
CREATE INDEX idx_cart_items_product_id ON cart_items (product_id);

-- Фейковые данные (users: 7, products: 5, orders: 9, cart_items: 7; заказы: отменён, возвращён)
INSERT INTO products (name, price, description) VALUES
    ('Ноутбук', 89990.00, '15.6", 16 GB RAM'),
    ('Мышь беспроводная', 1290.00, 'Bluetooth 5.0'),
    ('Клавиатура', 4500.00, 'Механическая RGB'),
    ('Монитор 27"', 34990.00, '4K UHD, IPS'),
    ('Наушники', 5990.00, 'Беспроводные, ANC');

INSERT INTO users (name) VALUES
    ('Иван Петров'),
    ('Мария Сидорова'),
    ('Алексей Козлов'),
    ('Елена Волкова'),
    ('Дмитрий Новиков'),
    ('Ольга Смирнова'),
    ('Сергей Кузнецов');

INSERT INTO orders (user_id, status, total, created_at, updated_at) VALUES
    (1, 'подтверждён', 95490.00, '2026-01-16', '2026-01-16'),
    (2, 'ожидает', 1290.00,    '2026-01-18', '2026-01-18'),
    (3, 'доставлен', 94490.00, '2026-01-11', '2026-01-14'),
    (4, 'отправлен', 40990.00, '2026-01-19', '2026-01-20'),
    (5, 'ожидает', 17880.00,   '2026-01-20', '2026-01-20'),
    (6, 'отменён', 4500.00,    '2026-01-17', '2026-01-18'),
    (1, 'возвращён', 5990.00,  '2026-01-10', '2026-01-20'),
    (5, 'отменён', 89990.00,   '2026-01-19', '2026-01-19'),
    (4, 'возвращён', 34990.00, '2026-01-12', '2026-01-25');

INSERT INTO cart_items (user_id, product_id, quantity, price, created_at) VALUES
    (1, 1, 1, 89990.00, '2026-01-15'),
    (2, 2, 2, 1290.00,  '2026-01-18'),
    (3, 3, 1, 4500.00,  '2026-01-10'),
    (4, 4, 1, 34990.00, '2026-01-19'),
    (5, 5, 3, 5990.00,  '2026-01-20'),
    (6, 3, 1, 4500.00,  '2026-01-17'),
    (7, 1, 1, 89990.00, '2026-01-21');

INSERT INTO order_items (order_id, product_id, quantity, price) VALUES
    (1, 1, 1, 89990.00), (1, 3, 1, 5500.00),
    (2, 2, 2, 1290.00),
    (3, 1, 1, 89990.00), (3, 3, 1, 4500.00),
    (4, 4, 1, 34990.00), (4, 5, 1, 5990.00),
    (5, 5, 3, 5990.00),
    (6, 3, 1, 4500.00),
    (7, 5, 1, 5990.00),
    (8, 1, 1, 89990.00),
    (9, 4, 1, 34990.00), (9, 5, 1, 5990.00);
-- Заказы 7, 9 — возвращён: товары 4 (монитор), 5 (наушники) в возвратах