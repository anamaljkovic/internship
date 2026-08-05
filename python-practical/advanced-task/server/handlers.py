from http.server import BaseHTTPRequestHandler
import json
from server import storage,model

class PizzaRequestHandler(BaseHTTPRequestHandler):
    def _send_json(self, status_code, data):
        
        body = json.dumps(data).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _readJsonBody(self):
        content_length = int(self.headers.get("Content-Length", 0))
        raw_body = self.rfile.read(content_length)
        return json.loads(raw_body)


    def do_GET(self):
        if self.path=="/menu":
            self.handle_getMenu()
        elif self.path.startswith("/order/"):
            self.handle_getOrderStatus()
        else:
            self._send_json(404, {"error": f"Unknown path: {self.path}"})

    def handle_getMenu(self):
        """return the menu"""
        menu = storage.loadMenu()
        self._send_json(200,menu)

    def findOrder(self, orders, order_id):
        for order in orders:
            if(order["id"]==order_id):
                return order
        return None

    def handle_getOrderStatus(self):
        order_id_str = self.path.removeprefix("/order/")

        try:
            order_id = int(order_id_str)
        except ValueError:
            self._send_json(400,{"error":f"invalid order ID -> {order_id_str}"})
            return

        orders = storage.loadOrders()
        order = self.findOrder(orders, order_id)

        if order is None:
            self._send_json(404, {"error":f"no order with ID -> {order_id}"})
            return

        self._send_json(200, order)
        

    def do_POST(self):
        if self.path=="/order":
            self.handle_createOrder()
        else:
            self._send_json(404, {"error": f"Unknown path: {self.path}"})

    def handle_createOrder(self):
        try:
            body = self._readJsonBody()
        except json.JSONDecodeError:
            self._send_json(400, {"error": "Invalid JSON in request body"})
            return

        items = body.get("items")
        address = body.get("address")
        user_id = body.get("user_id")

        if not items:
            self._send_json(400, {"error":"Missing mandatory field: items"})
            return
        if not address:
            self._send_json(400, {"error":"Missing mandatory field: address"})
            return

        orders = storage.loadOrders()
        order = model.makeOrder(orders, items=items, address=address, user_id=user_id)

        orders.append(order)
        storage.saveOrders(orders)

        self._send_json(201, order)

    def do_DELETE(self):
        if self.path.startswith("/order/"):
            self.handle_cancelOrder()
        else:
            self._send_json(404, {"error": f"Unknown path: {self.path}"})

    def handle_cancelOrder(self):
        order_id_str = self.path.removeprefix("/order/")
        
        try:
            order_id = int(order_id_str)
        except ValueError:
            self._send_json(400,{"error":f"invalid order ID -> {order_id_str}"})
            return
        
        orders = storage.loadOrders()
        order = self.findOrder(orders, order_id)
        
        if order is None:
            self._send_json(404, {"error":f"no order with ID -> {order_id}"})
            return

        if order["status"] == "ready_to_be_delivered":
            self._send_json(
                409,
                {"error": "Cannot cancel an order that is ready to be delivered"},
            )
            return

        order["status"] = "cancelled"
        storage.saveOrders(orders)

        self._send_json(200, order)