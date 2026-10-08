#!/usr/bin/env python3
# ~/.claude/settings.json に、dotfiles のフックが入っていなければ足す。
# ほかの設定（permissions・model など）には触らない。何度実行しても同じ結果になる。
import json
import os
import sys

path = os.path.expanduser("~/.claude/settings.json")
HOOKS = [
    # (イベント, コマンドに含まれていれば設定済みとみなす文字列, フック)
    ("UserPromptSubmit", "japanese-reply.py",
     {"type": "command", "command": 'python3 "$HOME/.claude/hooks/japanese-reply.py" 2>/dev/null || true', "timeout": 5}),
    ("SessionStart", "check-setup.sh",
     {"type": "command", "command": 'sh "$HOME/.claude/hooks/check-setup.sh"', "timeout": 5}),
]

settings = {}
if os.path.exists(path):
    with open(path) as f:
        settings = json.load(f)

changed = False
for event, key, hook in HOOKS:
    groups = settings.setdefault("hooks", {}).setdefault(event, [])
    if any(key in h.get("command", "") for g in groups for h in g.get("hooks", [])):
        print(f"  - {event}: {key}（設定済み）")
        continue
    groups.append({"matcher": "*", "hooks": [hook]})
    changed = True
    print(f"  ✓ {event}: {key} を追加")

if changed:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(settings, f, ensure_ascii=False, indent=2)
        f.write("\n")
