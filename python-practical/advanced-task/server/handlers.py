from http.server import BaseHTTPRequestHandler
import json
from server import storage,model,auth

class PizzaRequestHandler(BaseHTTPRequestHandler):
    def _send_json(self, status_code, data):
        
        body = json.dumps(data).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _read_json_body(self):
        content_length = int(self.headers.get("Content-Length", 0))
        raw_body = self.rfile.read(content_length)
        return json.loads(raw_body)


    def do_GET(self):
        if self.path=="/menu":
            self.handle_get_menu()
        elif self.path.startswith("/order/"):
            self.handle_get_order_status()
        else:
            self._send_json(404, {"error": f"Unknown path: {self.path}"})

    def handle_get_menu(self):
        """return the menu"""
        menu = storage.load_menu()
        self._send_json(200,menu)

    def find_order(self, orders, order_id):
        for order in orders:
            if(order["id"]==order_id):
                return order
        return None

    def find_user(self, users, user_id):
        for u in users:
            if(u["id"]==user_id):
                return u
        return None

    def is_admin_request(self):
        """
        check whether the current request carries a valid admin token
        expectes token in the form"Bearer <token>" and validates it
        """
        auth_header = self.headers.get("Authorization", "")
        print("received header --> ", repr(auth_header))
        print("admin token --> :", repr(auth.ADMIN_TOKEN))
        if not auth_header.startswith("Bearer "):
            return False
        token = auth_header.removeprefix("Bearer ")
        return auth.is_valid_admin_token(token)

    def require_admin(self):
        """
        admin-only endpoint

        Sends a 401 response and returns False if the request isn't a
        valid admin request. Callers must check the return value and
        `return` immediately if False — this only sends the response,
        it doesn't stop execution on its own.
        """
        if not self.is_admin_request():
            self._send_json(401, {"error":"valid admin token required"})
            return False
        return True

    def handle_get_order_status(self):
        order_id_str = self.path.removeprefix("/order/")

        try:
            order_id = int(order_id_str)
        except ValueError:
            self._send_json(400,{"error":f"invalid order ID -> {order_id_str}"})
            return

        orders = storage.load_orders()
        order = self.find_order(orders, order_id)

        if order is None:
            self._send_json(404, {"error":f"no order with ID -> {order_id}"})
            return

        self._send_json(200, order)
        

    def do_POST(self):
        if self.path=="/order":
            self.handle_create_order()
        elif self.path=="/menu":
            self.handle_add_pizza()
        elif self.path=="/users":
            self.handle_register_user()
        else:
            self._send_json(404, {"error": f"Unknown path: {self.path}"})




    def handle_create_order(self):
        """
        Handle POST /order 

        Validation order matters here:
        1. items must be present and reference pizzas that actually exist
        on the menu
        2. If user_id is given, it's validated against users.json
        3. address is required unless a valid user_id supplies a stored one.
        """
        try:
            body = self._read_json_body()
        except json.JSONDecodeError:
            self._send_json(400, {"error": "Invalid JSON in request body"})
            return

        items = body.get("items")
        address = body.get("address")
        user_id = body.get("user_id")

        if not items:
            self._send_json(400, {"error": "Missing mandatory field: items"})
            return

        menu = storage.load_menu()
        menu_ids = {pizza["id"] for pizza in menu}
        invalid_ids = [item_id for item_id in items if item_id not in menu_ids]

        if invalid_ids:
            self._send_json(
                400,
                {"error": f"No pizza(s) found with ID(s): {invalid_ids}"},
            )
            return

        if user_id is not None:
            users = storage.load_users()
            user = self.find_user(users, user_id)
            if user is None:
                self._send_json(400, {"error": f"No user found with ID {user_id}"})
                return
            if not address:
                address = user["address"]

        if not address:
            self._send_json(400, {"error": "Missing mandatory field: address"})
            return

        orders = storage.load_orders()
        order = model.make_order(orders, items=items, address=address, user_id=user_id)

        orders.append(order)
        storage.save_orders(orders)

        self._send_json(201, order)

    def handle_add_pizza(self):
        if not self.require_admin():
            return

        try:
            body = self._read_json_body()
        except json.JSONDecodeError:
            self._send_json(400, {"error": "Invalid JSON in request body"})
            return

        name = body.get("name")
        price = body.get("price")
        toppings = body.get("toppings", [])

        if not name:
            self._send_json(400, {"error": "Missing required field: name"})
            return
        if price is None:
            self._send_json(400, {"error": "Missing required field: price"})
            return

        if not isinstance(price, (int, float)) or isinstance(price, bool):
            self._send_json(400, {"error": "price must be a number"})
            return
        if price <= 0:
            self._send_json(400, {"error": "price must be greater than 0"})
            return

        menu = storage.load_menu()

        existing_names = {pizza["name"].strip().lower() for pizza in menu}
        if name.strip().lower() in existing_names:
            self._send_json(400, {"error": f"A pizza named '{name}' already exists"})
            return
        
        pizza = model.make_pizza(menu, name=name, price=price, toppings=toppings)
        menu.append(pizza)
        storage.save_menu(menu)

        self._send_json(201, pizza)

    def handle_register_user(self):

        try:
            body = self._read_json_body()
        except json.JSONDecodeError:
            self._send_json(400, {"error": "Invalid JSON in request body"})
            return

        name = body.get("name")
        address = body.get("address")
        password = body.get("password")

        if not name:
            self._send_json(400, {"error": "Missing required field: name"})
            return
        if not address:
            self._send_json(400, {"error": "Missing required field: address"})
            return
        if not password:
            self._send_json(400, {"error": "Missing required field: password"})
            return

        password_hash = auth.hash_password(password)

        users = storage.load_users()
        user = model.make_user(users, name=name, address=address, password_hash=password_hash)
        users.append(user)
        storage.save_users(users)

        response_user = {k: v for k, v in user.items() if k != "password_hash"}
        self._send_json(201, response_user)


    def do_DELETE(self):
        if self.path.startswith("/order/"):
            self.handle_cancel_order()
        elif self.path.startswith("/menu/"):
            self.handle_remove_pizza()
        else:
            self._send_json(404, {"error": f"Unknown path: {self.path}"})

    def handle_cancel_order(self):

        """
        DELETE /order/{order_id} 

        a non-admin request is blocked (409) if the order's
        status is exactly "ready_to_be_delivered". A valid admin token
        bypasses this check entirely and can cancel any order regardless
        of status.
        """
        
        order_id_str = self.path.removeprefix("/order/")
        
        try:
            order_id = int(order_id_str)
        except ValueError:
            self._send_json(400,{"error":f"invalid order ID -> {order_id_str}"})
            return
        
        orders = storage.load_orders()
        order = self.find_order(orders, order_id)
        
        if order is None:
            self._send_json(404, {"error":f"no order with ID -> {order_id}"})
            return

        is_admin = self.is_admin_request()


        if not is_admin and order["status"] == "ready_to_be_delivered":
            self._send_json(
                409,
                {"error": "Cannot cancel an order that is ready to be delivered"},
            )
            return

        order["status"] = "cancelled"
        storage.save_orders(orders)

        self._send_json(200, order)

    def handle_remove_pizza(self):
        if not self.require_admin():
            return

        pizza_id_str = self.path.removeprefix("/menu/")
        try:
            pizza_id = int(pizza_id_str)
        except ValueError:
            self._send_json(400, {"error": f"invalid pizza ID -> {pizza_id_str}"})
            return

        menu = storage.load_menu()
        edited_menu = model.remove_pizza(menu, pizza_id)

        if len(edited_menu) == len(menu):
            self._send_json(404, {"error": f"no pizza found with ID -> {pizza_id}"})
            return

        storage.save_menu(edited_menu)
        self._send_json(200, {"message": f"pizza {pizza_id} removed"})