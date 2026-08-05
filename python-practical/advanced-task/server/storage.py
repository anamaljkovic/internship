import json
import os

DATA_DIR = os.path.join(os.path.dirname(__file__), "..", "data")

MENU_PATH = os.path.join(DATA_DIR, "menu.json")
ORDERS_PATH = os.path.join(DATA_DIR, "orders.json")
USERS_PATH = os.path.join(DATA_DIR, "users.json")


def load_json(path, default):
    """
    Load and parse a JSON file, or return a default value if it doesn't exist yet.
    """

    if not os.path.exists(path):
        return default
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def save_json(path, data):
    """
    Write data to a JSON file, creating parent directories if needed.
    """
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2)


def loadMenu():
    return load_json(MENU_PATH, [])


def saveMenu(menu):
    save_json(MENU_PATH, menu)


def loadOrders():
    return load_json(ORDERS_PATH, [])


def saveOrders(orders):
    save_json(ORDERS_PATH, orders)


def loadUsers():
    return load_json(USERS_PATH, [])


def saveUsers(users):
    save_json(USERS_PATH, users)
