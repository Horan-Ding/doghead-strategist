#!/usr/bin/env python3
"""Convert WeChat-style chat CSV to normalized.jsonl (see schemas/message-line.schema.json)."""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
from pathlib import Path

TZ = "+08:00"

# WeChat export 消息类型 → kind / placeholder text
TYPE_MAP: dict[str, tuple[str, str]] = {
    "1": ("text", ""),
    "10000": ("system", ""),
    "3": ("image", "[图片]"),
    "47": ("sticker", "[表情包]"),
    "244813135921": ("sticker", "[表情包]"),
    "43": ("image", "[图片]"),
    "141733920817": ("image", "[图片]"),
    "81604378673": ("image", "[图片]"),
    "21474836529": ("system", "[系统消息]"),
    "154618822705": ("image", "[图片]"),
    "73014444081": ("image", "[图片]"),
}

BINARY_PREFIX = re.compile(r"""^b['\"]""")


def line_id(ts: str, from_: str, text: str) -> str:
    raw = f"{ts}|{from_}|{text[:200]}"
    return hashlib.sha256(raw.encode()).hexdigest()[:16]


def parse_ts(raw: str) -> str | None:
    raw = raw.strip()
    if not raw:
        return None
    # 2026-09-07 21:45:19
    if " " in raw:
        date, time = raw.split(" ", 1)
        return f"{date}T{time}{TZ}"
    return None


def normalize_row(row: dict, import_id: str) -> dict | None:
    is_me = row.get("是否本人", "").strip() == "是"
    from_ = "me" if is_me else "them"
    msg_type = row.get("消息类型", "1").strip()
    content = (row.get("内容") or "").strip()

    kind, default_text = TYPE_MAP.get(msg_type, ("text", "[未知消息类型]"))

    if msg_type == "10000" or content == "以上是打招呼的消息":
        from_ = "system"
        kind = "system"

    if BINARY_PREFIX.match(content) or (
        len(content) > 80 and "\\x" in content and "b'" in content[:3]
    ):
        text = default_text or "[媒体]"
        if kind == "text":
            kind = "image"
    elif msg_type != "1" and not content:
        text = default_text or "[媒体]"
    elif msg_type != "1" and default_text and (not content or BINARY_PREFIX.match(content)):
        text = default_text
    else:
        text = content if content else (default_text or "[空消息]")

    ts = parse_ts(row.get("时间", ""))

    obj: dict = {
        "id": line_id(ts or "", from_, text),
        "from": from_,
        "text": text,
        "kind": kind,
        "source": {"type": "export", "import_id": import_id},
    }
    if ts:
        obj["ts"] = ts
    return obj


def load_existing_ids(path: Path) -> set[str]:
    ids: set[str] = set()
    if not path.is_file():
        return ids
    with path.open(encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                ids.add(json.loads(line)["id"])
            except (json.JSONDecodeError, KeyError):
                continue
    return ids


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("csv_path", type=Path)
    ap.add_argument("out_jsonl", type=Path)
    ap.add_argument("--import-id", default="csv-import")
    args = ap.parse_args()

    args.out_jsonl.parent.mkdir(parents=True, exist_ok=True)
    existing_ids = load_existing_ids(args.out_jsonl)

    added = 0
    skipped = 0
    with args.csv_path.open(newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    with args.out_jsonl.open("a", encoding="utf-8") as out:
        for row in rows:
            obj = normalize_row(row, args.import_id)
            if obj is None:
                continue
            if obj["id"] in existing_ids:
                skipped += 1
                continue
            out.write(json.dumps(obj, ensure_ascii=False) + "\n")
            existing_ids.add(obj["id"])
            added += 1

    print(f"wrote {added} lines to {args.out_jsonl} (skipped {skipped} duplicates)")


if __name__ == "__main__":
    main()
