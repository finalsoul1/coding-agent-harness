#!/usr/bin/env bash
# 서브모듈 실체는 워크트리마다 따로 필요하다(git dir 이 .git/worktrees/<이름>/modules/ 로 갈린다).
# 설정(.git/config)은 공유되지만 체크아웃은 공유되지 않아, 새 워크트리는 매번 비어 있다.
# 서브모듈 경로를 참조하는 빌드·타입 검사가 새 워크트리에서 조용히 깨지는 것을 막는다.
# 실패는 경고만 남기고 진행한다.

set -u

logfile="$HOME/.claude/submodule-init.log"

payload="$(cat 2>/dev/null || true)"
d="$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null)"
d="${d:-$PWD}"

git -C "$d" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0
[ -f "$d/.gitmodules" ] || exit 0
# status 의 `-` 접두사가 미초기화 표시다 - 이미 받은 워크트리에서는 아무 것도 하지 않는다
git -C "$d" submodule status 2>/dev/null | grep -q '^-' || exit 0

if err="$(git -C "$d" submodule update --init --depth 1 2>&1 >/dev/null)"; then
  line="[submodule] 미초기화 서브모듈 init 완료"
else
  line="[submodule] init 실패 - 서브모듈 경로를 참조하는 빌드가 깨질 수 있다: $(printf '%s' "$err" | tr '\n' ' ' | cut -c1-200)"
fi

printf '%s\n' "$line"
printf '[%s] %s d=%s\n' "$(date '+%F %T')" "$line" "$d" >> "$logfile"
exit 0
