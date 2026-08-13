"""Entry point Nautilus loads directly. Its hyphenated name makes it
non-importable, so the real implementation -- MyComputerExtension, all app
state, and the Nautilus integration -- lives in nautilus_my_computer/main.py.
This file only resolves that package on sys.path and re-exports the provider
class; nautilus-python discovers it by introspecting this module's globals,
so the import below is all Nautilus needs to find it.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from nautilus_my_computer.main import MyComputerExtension  # noqa: E402,F401
