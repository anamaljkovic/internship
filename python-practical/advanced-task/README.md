# Pizza API

A pizza ordering system with an HTTP server (`http.server`) and a cli for interacting with it.

## Setup

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Set the admin token (required for admin endpoints/commands) before starting
the server:

```bash
export PIZZA_ADMIN_TOKEN="your-secret-token"
```

Start the server:

```bash
python -m server.main
```

The server runs on `http://localhost:8000`

## Project structure

```
advanced-task/
├── server/
│   ├── main.py       
│   ├── handlers.py   
│   ├── storage.py    
│   ├── model.py       
│   └── auth.py         
├── cli/
│   ├── pizza_cli.py    
│   └── api_client.py    
├── data/                
├── tests/
├── requirements.txt
├── README.md
└── DEPLOYMENT.md
```

---

## API Endpoints

All request/response bodies are JSON. Admin endpoints require an
`Authorization: Bearer <token>` header, where `<token>` matches the
server's `PIZZA_ADMIN_TOKEN` env variable.

### `GET /menu`

Returns the pizza menu.

**Response — `200 OK`**
```json
[
  {"id": 1, "name": "Margherita", "price": 9.99, "toppings": ["mozzarella", "basil"]}
]
```

---

### `POST /order`

Create a new order.

**Request body**
```json
{
  "items": [1, 2],
  "address": "BKA 17",
  "user_id": 5
}
```
- `items` (required) — list of pizza IDs, must exist on the menu.
- `address` (required, unless `user_id` is given and the user has a stored
  address)
- `user_id` (optional) — ID of a registered user. If given and `address` is
  not, the user's stored address is used.

**Response — `201 Created`**
```json
{"id": 3, "items": [1, 2], "address": "BKA 17", "user_id": 5, "status": "received"}
```

**Errors**
| Status | Cause |
|---|---|
| 400 | Invalid JSON body |
| 400 | Missing `items` |
| 400 | One or more pizza IDs in `items` don't exist |
| 400 | `user_id` doesn't match any registered user |
| 400 | Missing `address` (and no usable stored address) |

---

### `GET /order/{order_id}`

Return a single order by ID.

**Response — `200 OK`** — the order object 

**Errors**
| Status | Cause |
|---|---|
| 400 | `order_id` is not a valid integer |
| 404 | No order with that ID |

---

### `DELETE /order/{order_id}`

Cancel an order.

- Without a valid admin token: blocked if the order's status is
  `ready_to_be_delivered`.
- With a valid admin token: cancels regardless of status.

**Response — `200 OK`** — the updated order, with `status: "cancelled"`.

**Errors**
| Status | Cause |
|---|---|
| 400 | `order_id` is not a valid integer |
| 404 | No order with that ID |
| 409 | Order is `ready_to_be_delivered` and no valid admin token was provided |

---

### `POST /menu` — admin only

Add a pizza to the menu.

**Request body**
```json
{"name": "Hawaiian", "price": 10.5, "toppings": ["ham", "pineapple"]}
```
- `name` (required)
- `price` (required) — must be a positive number
- `toppings` (optional) — list of strings, defaults to `[]`

**Response — `201 Created`** — the created pizza object.

**Errors**
| Status | Cause |
|---|---|
| 401 | Missing/invalid admin token |
| 400 | Invalid JSON body |
| 400 | Missing `name` or `price` |
| 400 | `price` is not a number, or not greater than 0 |
| 400 | A pizza with that name already exists (case-insensitive) |

---

### `DELETE /menu/{pizza_id}` — admin only

Remove a pizza from the menu.

**Response — `200 OK`**
```json
{"message": "pizza 3 removed"}
```

**Errors**
| Status | Cause |
|---|---|
| 401 | Missing/invalid admin token |
| 400 | `pizza_id` is not a valid integer |
| 404 | No pizza with that ID |

---

### `POST /users`

Register a new user.

**Request body**
```json
{"name": "Ana", "address": "Nzm 12", "password": "secret123"}
```

**Response — `201 Created`** — the created user, **without** the password
hash.
```json
{"id": 1, "name": "Ana", "address": "Nzm 12"}
```

**Errors**
| Status | Cause |
|---|---|
| 400 | Invalid JSON body |
| 400 | Missing `name`, `address`, or `password` |

---

## CLI

Two ways to use the CLI: one-shot commands (scriptable) or an interactive
menu.

### Interactive mode

```bash
python -m cli.pizza_cli
```

Shows a numbered menu; prompts guide you through each action and validate
input as you type (retrying on bad input rather than crashing).

### One-shot commands

```bash
python -m cli.pizza_cli menu

python -m cli.pizza_cli order --items 1 2 --address "BKA 17"
python -m cli.pizza_cli order --items 1 2 --user-id 5

python -m cli.pizza_cli status --order-id 3

python -m cli.pizza_cli cancel --order-id 3
python -m cli.pizza_cli cancel --order-id 3 --admin-token TOKEN

python -m cli.pizza_cli register --name Ana --address "Nzm 12" --password secret123

python -m cli.pizza_cli add-pizza --name Margherita --price 9.99 --toppings mozzarella basil --admin-token TOKEN

python -m cli.pizza_cli remove-pizza --pizza-id 2 --admin-token TOKEN
```

All commands print the response status and body. On a connection failure
, the CLI prints a clear message instead of a raw
traceback.

---

## Security notes

- The admin token is never hardcoded — it's read from the
  `PIZZA_ADMIN_TOKEN` environment variable at server startup, and compared
  against incoming requests using a timing-safe comparison
  (`secrets.compare_digest`) to avoid leaking match information via
  response timing.
- User passwords are hashed with `bcrypt` before storage; the hash is
  never included in any API response.
- `.venv/`, `__pycache__/`, and transient data files are excluded from
  version control via `.gitignore`.
