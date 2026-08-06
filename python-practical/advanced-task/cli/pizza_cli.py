#!/usr/bin/env python3

import sys, argparse

from cli import api_client



def promptInt(prompt, min_value=None, allow_blank=False):
    """
    Repeatedly prompt until a valid integer is entered.

    Args:
        prompt: text shown to the user.
        min_value: if given, reject values below this.
        allow_blank: if True, an empty input returns None instead of retrying.

    Returns:
        The entered integer, or None if allow_blank and nothing was entered.
    """
    while True:
        raw = input(prompt).strip()

        if allow_blank and raw == "":
            return None

        try:
            value = int(raw)
        except ValueError:
            print(f"'{raw}' is not a valid whole number. Try again.")
            continue

        if min_value is not None and value < min_value:
            print(f"Must be {min_value} or greater. Try again.")
            continue

        return value


def positiveInt(value):
    """argparse type validator: must parse as an int > 0."""
    try:
        parsed = int(value)
    except ValueError:
        raise argparse.ArgumentTypeError(f"'{value}' is not a valid whole number")
    if parsed <= 0:
        raise argparse.ArgumentTypeError(f"'{value}' must be greater than 0")
    return parsed


def positiveFloat(value):
    """argparse type validator: must parse as a float > 0."""
    try:
        parsed = float(value)
    except ValueError:
        raise argparse.ArgumentTypeError(f"'{value}' is not a valid number")
    if parsed <= 0:
        raise argparse.ArgumentTypeError(f"'{value}' must be greater than 0")
    return parsed


def nonEmptyString(value):
    """argparse type validator: must not be blank after stripping whitespace."""
    stripped = value.strip()
    if not stripped:
        raise argparse.ArgumentTypeError("value cannot be empty")
    return stripped

def promptFloat(prompt, min_value=None):
    """
    Repeatedly prompt until a valid float is entered.

    Args:
        prompt: text shown to the user.
        min_value: if given, reject values below this.

    Returns:
        The entered float.
    """
    while True:
        raw = input(prompt).strip()

        try:
            value = float(raw)
        except ValueError:
            print(f"'{raw}' is not a valid number. Try again.")
            continue

        if min_value is not None and value < min_value:
            print(f"Must be {min_value} or greater. Try again.")
            continue

        return value


def promptNonEmptyString(prompt):
    """Repeatedly prompt until a non-blank string is entered."""
    while True:
        raw = input(prompt).strip()
        if raw:
            return raw
        print("This field can't be empty. Try again.")


def promptOptionalString(prompt):
    """Prompt for a string; returns None if left blank (no retry)."""
    raw = input(prompt).strip()
    return raw or None


def promptIntList(prompt):
    """
    Repeatedly prompt for a space-separated list of positive integers.

    Returns:
        A non-empty list of ints.
    """
    while True:
        raw = input(prompt).strip()
        if not raw:
            print("Please enter at least one ID.")
            continue

        parts = raw.split()
        values = []
        valid = True

        for part in parts:
            try:
                num = int(part)
            except ValueError:
                print(f"'{part}' is not a valid whole number. Try again.")
                valid = False
                break
            if num <= 0:
                print(f"'{part}' must be a positive number. Try again.")
                valid = False
                break
            values.append(num)

        if valid:
            return values



def cmdMenu(args):
    status, body = api_client.get_menu()
    printResult(status, body)

def cmdOrder(args):
    status, body = api_client.create_order(items=args.items, address=args.address, user_id=args.user_id)
    if status == 201:
        printOrder(body)
    else:
        printResult(status, body)

def cmdStatus(args):
    status, body = api_client.get_order_status(args.order_id)
    if status == 200:
        printOrder(body)
    else:
        printResult(status, body)

def cmdAddPizza(args):
    status, body = api_client.add_pizza(args.name, args.price, args.toppings, args.admin_token)
    printResult(status, body)

def cmdCancel(args):
    status, body = api_client.cancel_order(args.order_id, admin_token=args.admin_token)
    if status == 200:
        printOrder(body)
    else:
        printResult(status, body)

def cmdRemovePizza(args):
    status, body = api_client.remove_pizza(args.pizza_id, admin_token=args.admin_token)
    printResult(status, body)

def cmdRegister(args):
    status, body = api_client.register_user(args.name, args.address, args.password)
    printResult(status, body)


def printResult(status, body):
    if status is None:
        print(f"Error: {body}")
        return

    print(f"Status: {status}")
    print(body)

def printMenu(pizzas):
    """pizza menu in a formatted way"""
    if not pizzas:
        print("The menu is empty.")
        return

    print(f"\n{'ID':<5}{'Name':<20}{'Price':<10}Toppings")
    print("-" * 60)
    for pizza in pizzas:
        toppings_str = ", ".join(pizza.get("toppings", [])) or "-"
        print(f"{pizza['id']:<5}{pizza['name']:<20}${pizza['price']:<9.2f}{toppings_str}")
    print()

def printOrder(order):
    """order in a formatted way"""
    print(f"\nOrder #{order['id']}")
    print(f"  Status:  {order['status']}")
    print(f"  Items:   {', '.join(str(i) for i in order['items'])}")
    print(f"  Address: {order['address']}")
    if order.get("user_id") is not None:
        print(f"  User ID: {order['user_id']}")
    print()



def buildParser():
    parser = argparse.ArgumentParser(description="Pizza ordering CLI")
    subparsers = parser.add_subparsers(dest="command", required=False)

    menu_parser = subparsers.add_parser("menu", help="List the pizza menu")
    menu_parser.set_defaults(func=cmdMenu)

    order_parser = subparsers.add_parser("order", help="Create a new order")
    order_parser.add_argument(
        "--items", type=positiveInt, nargs="+", required=True,
        help="Pizza IDs to order (positive integers)"
    )
    order_parser.add_argument("--address", type=nonEmptyString, help="Delivery address")
    order_parser.add_argument(
        "--user-id", type=positiveInt, dest="user_id",
        help="Registered user ID (for address reuse)"
    )
    order_parser.set_defaults(func=cmdOrder)

    status_parser = subparsers.add_parser("status", help="Check an order's status")
    status_parser.add_argument("--order-id", type=positiveInt, required=True, dest="order_id")
    status_parser.set_defaults(func=cmdStatus)

    cancel_parser = subparsers.add_parser("cancel", help="Cancel an order")
    cancel_parser.add_argument("--order-id", type=positiveInt, required=True, dest="order_id")
    cancel_parser.add_argument(
        "--admin-token", type=nonEmptyString, dest="admin_token",
        help="Admin token (bypasses status check)"
    )
    cancel_parser.set_defaults(func=cmdCancel)

    register_parser = subparsers.add_parser("register", help="Register a new user")
    register_parser.add_argument("--name", type=nonEmptyString, required=True)
    register_parser.add_argument("--address", type=nonEmptyString, required=True)
    register_parser.add_argument("--password", type=nonEmptyString, required=True)
    register_parser.set_defaults(func=cmdRegister)

    add_pizza_parser = subparsers.add_parser("add-pizza", help="Add a pizza to the menu (admin)")
    add_pizza_parser.add_argument("--name", type=nonEmptyString, required=True)
    add_pizza_parser.add_argument("--price", type=positiveFloat, required=True)
    add_pizza_parser.add_argument("--toppings", type=str, nargs="*", default=[])
    add_pizza_parser.add_argument(
        "--admin-token", type=nonEmptyString, required=True, dest="admin_token"
    )
    add_pizza_parser.set_defaults(func=cmdAddPizza)

    remove_pizza_parser = subparsers.add_parser("remove-pizza", help="Remove a pizza from the menu (admin)")
    remove_pizza_parser.add_argument("--pizza-id", type=positiveInt, required=True, dest="pizza_id")
    remove_pizza_parser.add_argument(
        "--admin-token", type=nonEmptyString, required=True, dest="admin_token"
    )
    remove_pizza_parser.set_defaults(func=cmdRemovePizza)

    return parser

def interactiveMenu():
    """Run an interactive, menu-driven version of the CLI."""
    options = {
        "1": ("List the menu", interactiveListMenu),
        "2": ("Create an order", interactiveCreateOrder),
        "3": ("Check order status", interactiveOrderStatus),
        "4": ("Cancel an order", interactiveCancelOrder),
        "5": ("Register a new user", interactiveRegister),
        "6": ("Add a pizza to the menu (admin)", interactiveAddPizza),
        "7": ("Remove a pizza from the menu (admin)", interactiveRemovePizza),
        "0": ("Exit", None),
    }

    while True:
        print("\nPizza CLI")
        for key, (label, _) in options.items():
            print(f"  {key}) {label}")

        try:
            choice = input("Choose an option: ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nGoodbye!")
            break

        if choice == "0":
            print("Goodbye!")
            break

        if choice not in options:
            print(f"'{choice}' is not a valid option. Try again.")
            continue

        _, action = options[choice]
        try:
            action()
        except (EOFError, KeyboardInterrupt):
            print("\nCancelled.")



def interactiveListMenu():
    status, body = api_client.get_menu()
    if status == 200:
        printMenu(body)
    else:
        printResult(status, body)


def interactiveCreateOrder():
    items = promptIntList("Pizza IDs to order (space-separated): ")
    user_id = promptInt("User ID (leave blank for guest order): ", min_value=1, allow_blank=True)

    if user_id is None:
        address = promptNonEmptyString("Delivery address: ")
    else:
        address = promptOptionalString("Delivery address (leave blank to use your stored address): ")

    status, body = api_client.create_order(items=items, address=address, user_id=user_id)
    if status == 201:
        printOrder(body)
    else:
        printResult(status, body)


def interactiveOrderStatus():
    order_id = promptInt("Order ID: ", min_value=1)
    status, body = api_client.get_order_status(order_id)
    if status == 200:
        printOrder(body)
    else:
        printResult(status, body)


def interactiveCancelOrder():
    order_id = promptInt("Order ID: ", min_value=1)
    admin_token = promptOptionalString("Admin token (leave blank if not an admin): ")
    status, body = api_client.cancel_order(order_id, admin_token=admin_token)
    if status == 200:
        printOrder(body)
    else:
        printResult(status, body)


def interactiveRegister():
    name = promptNonEmptyString("Name: ")
    address = promptNonEmptyString("Address: ")
    password = promptNonEmptyString("Password: ")
    status, body = api_client.register_user(name, address, password)
    printResult(status, body)


def interactiveAddPizza():
    name = promptNonEmptyString("Pizza name: ")
    price = promptFloat("Price: ", min_value=0.01)
    toppings_str = input("Toppings (space-separated, optional): ").strip()
    toppings = toppings_str.split() if toppings_str else []
    admin_token = promptNonEmptyString("Admin token: ")

    status, body = api_client.add_pizza(name, price, toppings, admin_token)
    printResult(status, body)


def interactiveRemovePizza():
    pizza_id = promptInt("Pizza ID to remove: ", min_value=1)
    admin_token = promptNonEmptyString("Admin token: ")

    status, body = api_client.remove_pizza(pizza_id, admin_token)
    printResult(status, body)

def main():
    if len(sys.argv) == 1:
        interactiveMenu()
        return

    parser = buildParser()
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()