"""
Pytest configuration and fixtures for CAPS tests.
"""

import sys
import os
from pathlib import Path

# Add src directory to Python path BEFORE any other imports
_src_dir = str(Path(__file__).parent.parent / "src")
if _src_dir not in sys.path:
    sys.path.insert(0, _src_dir)
os.environ["PYTHONPATH"] = _src_dir + os.pathsep + os.environ.get("PYTHONPATH", "")
