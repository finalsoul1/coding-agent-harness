#!/usr/bin/env bash
# PostToolUse(Edit|Write) hook: flag comment lines this edit newly ADDED so the
# model re-checks them against the "leave only WHY" rule. Uses the tool payload
# (Edit old/new_string, Write content vs HEAD) rather than a raw working-tree
# diff, so a legitimate comment is not re-flagged on every later edit to the file.
# Always exits 0; emits a nudge via hookSpecificOutput.additionalContext only when
# the edit introduced new comment lines.

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')
f=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ -n "$f" ] || exit 0

case "$f" in
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs) ;;
  *) exit 0 ;;
esac

CM='^[[:space:]]*(//|/\*|\*|\{/\*)'
comments() { grep -E "$CM" | sed 's/^[[:space:]]*//' | sort -u; }

dir=$(dirname "$f")
if [ "$tool" = "Edit" ]; then
  new=$(printf '%s' "$input" | jq -r '.tool_input.new_string // ""')
  old=$(printf '%s' "$input" | jq -r '.tool_input.old_string // ""')
else
  new=$(printf '%s' "$input" | jq -r '.tool_input.content // ""')
  base=$(basename "$f")
  prefix=$(git -C "$dir" rev-parse --show-prefix 2>/dev/null)
  old=$(git -C "$dir" show "HEAD:${prefix}${base}" 2>/dev/null)
fi

added=$(comm -23 <(printf '%s\n' "$new" | comments) <(printf '%s\n' "$old" | comments))
[ -n "$added" ] || exit 0

count=$(printf '%s\n' "$added" | grep -c .)
list=$(printf '%s\n' "$added" | head -30)
printf -v msg '방금 %s 로 %s 에 주석 %s줄을 새로 추가했다. 각 줄을 "왜만 남긴다" 규칙으로 재검토하라:\n- 코드가 이미 말하는 내용(무엇/어떻게)을 반복하면 삭제\n- 비직관적 결정, 트레이드오프, 우회한 버그, 지켜야 할 제약 같은 "왜"만 남긴다\n- 역할 설명·핸드오프·TODO는 코드가 아니라 이슈/PR로\n추가된 주석:\n%s' "$tool" "$f" "$count" "$list"

jq -n --arg c "$msg" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$c}}'
exit 0
