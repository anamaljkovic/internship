#!/usr/bin/env python3

import requests

BASE_URL="http://localhost:8000"

def admin_header(admin_token):
    if admin_token:
        return {"Authorization":f"Bearer {admin_token}"}

    return {}

def get_menu():
    response = requests.get(f"{BASE_URL}/menu")
    return response.status_code, response.json()

def create_order(items, address=None, user_id=None):
    body = {"items":items}
    if address is not None:
        body["address"]=address
    if user_id is not None:
        body["user_id"]=user_id

    response = requests.post(f"{BASE_URL}/order",json=body)
    return response.status_code, response.json()

def check_status(order_id):
    respone = requests.get(f"{BASE_URL}/{order_id}")
    return respone.status_code, respone.json()

def cancel_order(order_id, admin_token=None):
    headers = admin_header(admin_token)
    response = requests.delete(f"{BASE_URL}/order/{order_id}", headers=headers)

    return response.status_code, response.json()

def add_pizza(name, price, toppings, admin_token=None):
    body={"toppings": toppings}
    body["price"]=price
    body["name"]=name
    headers=admin_header(admin_token)

    response = requests.post(f"{BASE_URL}/menu",json=body,headers=headers)
    return response.status_code, response.json()

def delete_pizza(pizza_id, admin_token=None):
    headers=admin_header(admin_token)
    response = requests.delete(f"{BASE_URL}/menu/{pizza_id}")

    return response.status_code, response.json()

def get_order_status(order_id):
    response = requests.get(f"{BASE_URL}/order/{order_id}")
    return response.status_code, response.json()

def register(name, address, password):
    body={}
    body["name"]=name
    body["address"]=address
    body["password"]=password

    response = requests.post(f"{BASE_URL}/users",json=body)
    return response.status_code, response.json()


