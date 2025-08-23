#!/bin/bash
set -euo pipefail

################################################################################################
# File: 0 bash symbols.sh
# Author: Andreas
# Date: 20250822
# Purpose:  Reference to possbile symbols in bash
#
################################################################################################
exit 0

################################################################################################
Handy symbols you can print

Status: ✅ ❌ ⚠️ ℹ️ 💡 ⏳ 🔄 🔧 🔒 🚀 ❓

Arrows: → ← ↑ ↓ ➜ ▶
Bullets/separators: • — …
Box drawing: ┌─┐ │ │ └─┘ (great for simple UIs)
Spinner frames (Unicode): ⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏


OK="✅"; ERR="❌"; WARN="⚠️"; INFO="ℹ️"

################################################################################################
Question
❓ (U+2753, red question mark)
❔ (U+2754, white question mark)
⁉️ (U+2049, exclamation question)
？ (U+FF1F, full-width question mark)
Ⓠ (U+24C6, circled Q)
Answer / Reply
💬 (U+1F4AC, speech balloon)
↩️ (U+21A9, reply arrow)
✅ (U+2705, correct answer/accepted)
Ⓐ (U+24B6, circled A)
🅰️ (U+1F170, A button)
Quick pairing examples:
❓ Question / 💬 Answer
Ⓠ / Ⓐ
❓ / ✅ (for Q / accepted answer)
ASCII fallback (logs, non-UTF8): Q: / A:.


################################################################################################
# Detect Unicode capability (very simple check)
case ${LANG:-} in *UTF-8*|*utf8*) unicode_ok=1;; *) unicode_ok=0;; esac

if ((unicode_ok)); then
  OK="✅"; ERR="❌"; WARN="⚠️"; INFO="ℹ️"
else
  OK="[OK]"; ERR="[X]"; WARN="[!]" ; INFO="[i]"
fi

printf '%s Starting…\n'  "$INFO"
printf '%s All good.\n'   "$OK"
printf '%s Heads up.\n'   "$WARN"
printf '%s Something failed.\n' "$ERR"