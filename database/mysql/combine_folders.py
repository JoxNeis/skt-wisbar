"""
Combine every .sql file inside each folder of database/ into one file per folder.

Output goes to database/combined/_<folder>.sql, e.g.
    database/schemas/*.sql            -> database/combined/_schemas.sql
    database/stored_procedures.sql/*  -> database/combined/_stored_procedures.sql

Files are concatenated in name order (00_, 01_, ... 99_).

Usage:
    python database/combine_folders.py
"""

from pathlib import Path

DATABASE_DIR = Path(__file__).resolve().parent
COMBINED_DIR = DATABASE_DIR / "combined"


def folder_label(folder: Path) -> str:
    # "stored_procedures.sql" -> "stored_procedures"
    name = folder.name
    return name[:-4] if name.lower().endswith(".sql") else name


def combine_folder(folder: Path) -> Path | None:
    sql_files = sorted(p for p in folder.glob("*.sql") if p.is_file())
    if not sql_files:
        print(f"skip  {folder.name}/ (no .sql files)")
        return None

    output = COMBINED_DIR / f"_{folder_label(folder)}.sql"
    parts = []
    for sql_file in sql_files:
        content = sql_file.read_text(encoding="utf-8").strip()
        if not content:
            continue
        rel = sql_file.relative_to(DATABASE_DIR).as_posix()
        parts.append(f"-- ===== {rel} =====\n{content}\n")

    output.write_text("\n".join(parts), encoding="utf-8")
    print(f"wrote {output.relative_to(DATABASE_DIR).as_posix()} ({len(sql_files)} files)")
    return output


def main() -> None:
    COMBINED_DIR.mkdir(exist_ok=True)
    for folder in sorted(p for p in DATABASE_DIR.iterdir() if p.is_dir()):
        if folder == COMBINED_DIR:
            continue
        combine_folder(folder)


if __name__ == "__main__":
    main()
