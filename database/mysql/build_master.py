"""
Combine all database/combined/_*.sql files into one master DDL file:
    database/combined/ddl_ver_<version>.sql

Run combine_folders.py first so the _*.sql files are up to date.

Usage:
    python database/build_master.py 0_5     # version as argument
    python database/build_master.py         # prompts for version
"""

import re
import sys
from datetime import datetime, timezone
from pathlib import Path

DATABASE_DIR = Path(__file__).resolve().parent
COMBINED_DIR = DATABASE_DIR / "combined"

# Dependency order: tables first, then routines, views, triggers.
# Any other _*.sql file is appended afterwards in alphabetical order.
ORDER = ["schemas", "functions", "stored_procedures", "views", "triggers"]


def get_version() -> str:
    raw = sys.argv[1] if len(sys.argv) > 1 else input("Version (e.g. 0_5 or 0.5): ")
    version = raw.strip().replace(".", "_")
    if not re.fullmatch(r"[0-9A-Za-z_\-]+", version):
        sys.exit(f"Invalid version: {raw!r}")
    return version


def ordered_parts() -> list[Path]:
    parts = {p.stem[1:]: p for p in COMBINED_DIR.glob("_*.sql")}
    ordered = [parts.pop(name) for name in ORDER if name in parts]
    ordered += [parts[name] for name in sorted(parts)]
    return ordered


def main() -> None:
    version = get_version()
    parts = ordered_parts()
    if not parts:
        sys.exit("No _*.sql files in database/combined. Run combine_folders.py first.")

    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
    chunks = [f"-- WisBar DDL version {version.replace('_', '.')}\n-- Generated {timestamp}\n"]
    for part in parts:
        content = part.read_text(encoding="utf-8").strip()
        if content:
            chunks.append(f"-- ##### {part.name} #####\n{content}\n")

    output = COMBINED_DIR / f"ddl_ver_{version}.sql"
    output.write_text("\n".join(chunks), encoding="utf-8")
    print(f"wrote {output.relative_to(DATABASE_DIR).as_posix()} from: {', '.join(p.name for p in parts)}")


if __name__ == "__main__":
    main()
