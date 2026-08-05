
"""
- Validating admin tokens sent with requests, against a hardcoded/env-configured token
- Hashing and verifying user passwords securely using bcrypt
"""

import os
import secrets
import bcrypt


ADMIN_TOKEN = os.environ.get("PIZZA_ADMIN_TOKEN")


def is_valid_admin_token(token):
    """
    Compare a given token against the configured admin token.

    Uses a timing-safe comparison (secrets.compare_digest) rather
    than `==`, since a plain equality check can cause a leak 

    Returns False if no admin token is configured at all 
    (PIZZA_ADMIN_TOKEN env var was never set)
    """
    if not ADMIN_TOKEN:
        return False
    return secrets.compare_digest(token or "", ADMIN_TOKEN)


def hash_password(password):
    hashed = bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt())
    return hashed.decode("utf-8")


def verify_password(password, stored_hash):
    return bcrypt.checkpw(password.encode("utf-8"), stored_hash.encode("utf-8"))