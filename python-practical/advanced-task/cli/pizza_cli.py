#!/usr/bin/env python3

import sys, argparse

from cli import api_client

def cmdMenu(args):
    status, body = api_client.get_menu()
    printResult(status, body)

def cmdOrder(args):
    status, body = api_client.create_order(items=args.items, address=args.address, user_id=args.user_id)
    printResult(status, body)

def cmdStatus(args):
    status, body = api_client.get_order_status(args.order_id)
    printResult(status, body)

def cmdAddPizza(args):
    status, body = api_client.add_pizza(args.name, args.price, args.toppings, args.admin_token)
    printResult(status, body)

def cmdCancel(args):
    status, body = api_client.cancel_order(args.order_id, admin_token=args.admin_token)
    printResult(status, body)

def cmdRemovePizza(args):
    status, body = api_client.delete_pizza(args.pizza_id)
    printResult(status, body)

def cmdRegister(args):
    status, body = api_client.register(args.name, args.address, args.password)
    printResult(status, body)


def printResult(status, body):
    """print the response, and exit with a non-zero code on client/server errors"""
    print(f"Status: {status}")
    print(body)
    if status == 401:
        sys.exit(1)
    elif status >= 400:
        sys.exit(1)

def buildParser():
    parser = argparse.ArgumentParser(description="Pizza ordering CLI")
    subparsers = parser.add_subparsers(dest="command", required=True)

    menu_parser = subparsers.add_parser("menu", help="List the pizza menu")
    menu_parser.set_defaults(func=cmdMenu)

    order_parser = subparsers.add_parser("order", help="Create a new order")
    order_parser.add_argument("--items", type=int, nargs="+", required=True, help="Pizza IDs to order")
    order_parser.add_argument("--address", type=str, help="Delivery address")
    order_parser.add_argument("--user-id", type=int, dest="user_id", help="Registered user ID (for address reuse)")
    order_parser.set_defaults(func=cmdOrder)

    status_parser = subparsers.add_parser("status", help="Check an order's status")
    status_parser.add_argument("--order-id", type=int, required=True, dest="order_id")
    status_parser.set_defaults(func=cmdStatus)

    cancel_parser = subparsers.add_parser("cancel", help="Cancel an order")
    cancel_parser.add_argument("--order-id", type=int, required=True, dest="order_id")
    cancel_parser.add_argument("--admin-token", type=str, dest="admin_token", help="Admin token (bypasses status check)")
    cancel_parser.set_defaults(func=cmdCancel)

    register_parser = subparsers.add_parser("register", help="Register a new user")
    register_parser.add_argument("--name", type=str, required=True)
    register_parser.add_argument("--address", type=str, required=True)
    register_parser.add_argument("--password", type=str, required=True)
    register_parser.set_defaults(func=cmdRegister)

    add_pizza_parser = subparsers.add_parser("add-pizza", help="Add a pizza to the menu (admin)")
    add_pizza_parser.add_argument("--name", type=str, required=True)
    add_pizza_parser.add_argument("--price", type=float, required=True)
    add_pizza_parser.add_argument("--toppings", type=str, nargs="*", default=[])
    add_pizza_parser.add_argument("--admin-token", type=str, required=True, dest="admin_token")
    add_pizza_parser.set_defaults(func=cmdAddPizza)

    remove_pizza_parser = subparsers.add_parser("remove-pizza", help="Remove a pizza from the menu (admin)")
    remove_pizza_parser.add_argument("--pizza-id", type=int, required=True, dest="pizza_id")
    remove_pizza_parser.add_argument("--admin-token", type=str, required=True, dest="admin_token")
    remove_pizza_parser.set_defaults(func=cmdRemovePizza)

    return parser

def main():
    parser = buildParser()
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()