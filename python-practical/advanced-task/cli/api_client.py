#!/usr/bin/env python3

import requests

BASE_URL="http://localhost:8000"

def _request(method, path, **kwargs):
    """
    Make an HTTP request and return (status_code, body), or (None, error_message)
    if the request itself failed (server not running).
    """
    try:
        response = requests.request(method, f"{BASE_URL}{path}", **kwargs)
    except requests.exceptions.ConnectionError:
        return None, "Could not connect to the server. Is it running?"
    except requests.exceptions.RequestException as e:
        return None, f"Request failed: {e}"

    try:
        return response.status_code, response.json()
    except ValueError:
        return response.status_code, {"error": "Server returned a non-JSON response"}


def get_menu():
    return _request("GET", "/menu")


def create_order(items, address=None, user_id=None):
    body = {"items": items}
    if address is not None:
        body["address"] = address
    if user_id is not None:
        body["user_id"] = user_id
    return _request("POST", "/order", json=body)


def get_order_status(order_id):
    return _request("GET", f"/order/{order_id}")


def cancel_order(order_id, admin_token=None):
    headers = admin_header(admin_token)
    return _request("DELETE", f"/order/{order_id}", headers=headers)


def register_user(name, address, password):
    body = {"name": name, "address": address, "password": password}
    return _request("POST", "/users", json=body)


def add_pizza(name, price, toppings, admin_token):
    body = {"name": name, "price": price, "toppings": toppings}
    headers = admin_header(admin_token)
    return _request("POST", "/menu", json=body, headers=headers)


def remove_pizza(pizza_id, admin_token):
    headers = admin_header(admin_token)
    return _request("DELETE", f"/menu/{pizza_id}", headers=headers)


def admin_header(admin_token):
    if admin_token:
        return {"Authorization": f"Bearer {admin_token}"}
    return {}
