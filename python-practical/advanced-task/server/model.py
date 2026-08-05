"""
Factory functions for pizzas, orders, and users.

Every function builds a plain dict with an auto-generated ID
"""

ORDER_STATUS=["received", "preparing", "ready_to_be_delievered", "delivered", "cancelled"]

def nextId(existing_items):
    """
    find the next available ID for a list of items, return 1 if the list is empty
    """
    if not existing_items:
        return 1
    return max(item["id"] for item in existing_items) + 1

def makePizza(existing_menu, name, price, toppings):
    return {
        "id": nextId(existing_menu),
        "name": name,
        "price": price,
        "toppings": toppings,
    }


def makeOrder(existing_orders, items, address, user_id=None):
    return {
        "id": nextId(existing_orders),
        "items": items,
        "address": address,
        "user_id": user_id,
        "status": "received",
    }


def makeUser(existing_users, user_id, name, address, password_hash):
    return {
        "id": user_id,
        "name": name,
        "address": address,
        "password_hash": password_hash,
    }