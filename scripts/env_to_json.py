#!/usr/bin/env python3
"""Converts .env (KEY=VALUE lines) into env.json for --dart-define-from-file.

Usage:
    python scripts/env_to_json.py
"""

import json
import re
from pathlib import Path

ENV_FILE = Path(".env")
OUT_FILE = Path("env.json")


def main():
    pairs = {}
    for line in ENV_FILE.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        m = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)=(.*)$", line)
        if m:
            key, val = m.group(1), m.group(2).strip().strip('"').strip("'")
            pairs[key] = val

    OUT_FILE.write_text(json.dumps(pairs, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"{OUT_FILE} atualizado com as chaves: {list(pairs.keys())}")


if __name__ == "__main__":
    main()
