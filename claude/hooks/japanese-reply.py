#!/usr/bin/env python3
# UserPromptSubmit フック: 日本語を含むメッセージには「日本語で返答する」という注意を毎回差し込む。
# ~/.claude/CLAUDE.md の「日本語で質問された場合は日本語で返答」を、長い会話でも守らせるため（2026-10-05）
import json
import re
import sys

try:
    prompt = json.load(sys.stdin).get("prompt", "")
except Exception:
    sys.exit(0)

if re.search(r"[぀-ヿ㐀-鿿]", prompt):
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "UserPromptSubmit",
            "additionalContext": (
                "ユーザーは日本語で書いている。この返答は（ユーザーが別の言語を指定していない限り）"
                "最初から最後まで日本語で書くこと。タメ口ではなく丁寧語で。"
                "ツールの出力やスキルの説明が英語でも、ユーザーへの返答の言語は変えない。"
            ),
        }
    }, ensure_ascii=False))
