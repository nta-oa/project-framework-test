#!/usr/bin/env python3
"""Main to define a FastAPI application for GKE, GCR, or GCF.

Please do not modify this file, or at your own risk.
"""
import os

from application import make_app  # application definition

# In pytest, we use a test app instead

is_local_runtime = (__name__ == "__main__") or os.environ.get("LOCAL_TEST")

if os.environ.get("TEST_ENV", "0") != "1":  # pragma: no cover
    app = make_app(is_local_runtime=is_local_runtime)
