#!/usr/bin/env bash
# PostToolUse(Edit|Write) hook: nudge to tier ~/.agent-memory/MEMORY.md once the
# always-loaded index passes the item threshold. The nudge carries the Phase 1
# rules inline because the session that trips it will not have the design
# discussion in context.

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
f=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')
[ "$f" = "$HOME/.agent-memory/MEMORY.md" ] || exit 0

THRESHOLD=150
items=$(grep -c '^- \[' "$f" 2>/dev/null) || exit 0
[ "$items" -ge "$THRESHOLD" ] || exit 0

# Installed as a symlink into ~/.claude/hooks, so resolve back to the repo for the doc path.
repo=$(cd "$(dirname "$(readlink "${BASH_SOURCE[0]}" || echo "${BASH_SOURCE[0]}")")/.." && pwd)

msg="MEMORY.md 항목이 ${items}개다(임계 ${THRESHOLD}). 상시 로드 인덱스가 커졌으니 계층화 Phase 1을 실행하라.
- 카테고리별 ~/.agent-memory/index/<카테고리>.md 로 항목 줄을 옮긴다
- MEMORY.md 에는 상시 적용 규칙(핫셋)과 카테고리 키워드 라우팅만 남긴다
- 본문 메모리 파일은 루트에서 이동하지 않는다(링크·경로가 깨진다)
- 하위 인덱스를 @ 로 import 하지 않는다(재귀 로드라 절감이 사라진다)
전체 설계는 ${repo}/MEMORY.md 의 '인덱스 계층화' 절을 읽어라."

jq -n --arg c "$msg" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$c}}'
exit 0
