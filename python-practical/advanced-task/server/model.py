"""
Factory functions for pizzas, orders, and users.

Every function builds a plain dict with an auto-generated ID
"""

ORDER_STATUS=["received", "preparing", "ready_to_be_delievered", "delivered", "cancelled"]

def next_id(existing_items):
    """
    Compute the next available integer ID from existing ones (json file)

    IDs are calculated this way (max existing ID + 1), they stay correct across
    server restarts 
    """
    if not existing_items:
        return 1
    return max(item["id"] for item in existing_items) + 1

def make_pizza(existing_menu, name, price, toppings):
    return {
        "id": next_id(existing_menu),
        "name": name,
        "price": price,
        "toppings": toppings,
    }


def make_order(existing_orders, items, address, user_id=None):
    return {
        "id": next_id(existing_orders),
        "items": items,
        "address": address,
        "user_id": user_id,
        "status": "received",
    }


def make_user(existing_users, name, address, password_hash):
    return {
        "id": next_id(existing_users),
        "name": name,
        "address": address,
        "password_hash": password_hash,
    }

def remove_pizza(menu, pizza_id):
    return [pizza for pizza in menu if pizza["id"] != pizza_id]

