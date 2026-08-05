"""
Factory functions for pizzas, orders, and users.

Every function builds a plain dict with an auto-generated ID
"""

import itertools


_user_id_counter = itertools.count(start=1)
_pizza_id_counter = itertools.count(start=1)
_order_id_counter = itertools.count(start=1)

ORDER_STATUS=["received", "preparing", "ready_to_be_delievered", "delivered", "cancelled"]

def makePizza(name, price, toppings):
    return {
        "id": next(_pizza_id_counter),
        "name": name,
        "price": price,
        "toppings": toppings,
    }


def makeOrder(items, address, user_id=None):
    return {
        "id": next(_order_id_counter),
        "items": items,
        "address": address,
        "user_id": user_id,
        "status": "received",
    }


def makeUser(user_id, name, address, password_hash):
    return {
        "id": user_id,
        "name": name,
        "address": address,
        "password_hash": password_hash,
    }