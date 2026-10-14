#!/usr/bin/env bash
# PreToolUse hook: MR/PR 을 만들기 전에 리뷰 서브에이전트를 한 번 거치게 한다.
# 통과 기록은 커밋이 아니라 브랜치 단위다. 커밋 단위면 리뷰 지적을 고쳐 커밋할 때마다
# 기록이 무효가 돼 리뷰가 끝없이 반복된다.
# 기록은 git-dir 안에 두어 작업 트리를 더럽히지 않고, 워크트리를 지우면 같이 사라진다.

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty')
cwd=${cwd:-$PWD}
branch=

case "$tool" in
  mcp__gitlab__create_merge_request)
    branch=$(printf '%s' "$input" | jq -r '.tool_input.source_branch // empty') ;;
  mcp__github__create_pull_request)
    branch=$(printf '%s' "$input" | jq -r '.tool_input.head // empty') ;;
  Bash)
    cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
    printf '%s' "$cmd" | grep -Eq '(glab[[:space:]]+mr|gh[[:space:]]+pr)[[:space:]]+create' || exit 0
    printf '%s' "$cmd" | grep -Eq '(^|[[:space:]])--?h(elp)?([[:space:]]|$)' && exit 0
    # payload 의 cwd 는 명령 실행 전 위치라 "cd <워크트리> && glab mr create" 를 놓친다.
    pre=$(printf '%s' "$cmd" | sed -E 's/(glab[[:space:]]+mr|gh[[:space:]]+pr)[[:space:]]+create.*//')
    d=$(printf '%s' "$pre" | sed -nE 's/^(.*[;&|[:space:]])?cd[[:space:]]+("[^"]+"|'"'"'[^'"'"']+'"'"'|[^[:space:];&|]+).*/\2/p' | tr -d "\"'")
    case "$d" in
      '') ;;
      '~'*) cwd="$HOME${d#\~}" ;;
      /*) cwd=$d ;;
      *) cwd="$cwd/$d" ;;
    esac
    ;;
  *) exit 0 ;;
esac

gitdir=$(git -C "$cwd" rev-parse --absolute-git-dir 2>/dev/null) || exit 0
branch=${branch:-$(git -C "$cwd" branch --show-current 2>/dev/null)}
[ -n "$branch" ] || exit 0

marker="$gitdir/agent-review/$(printf '%s' "$branch" | sed 's#/#__#g')"
[ -f "$marker" ] && exit 0

root=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)
skill="$root/.claude/skills/code-review/SKILL.md"
if [ -f "$skill" ]; then
  criteria="리뷰 기준은 저장소 스킬($skill)을 따르게 한다."
else
  criteria="리뷰 기준은 정확성 버그, 보안, 기존 동작 회귀, 저장소 규칙(CLAUDE.md/AGENTS.md) 위반이다."
fi

printf -v msg '%s 브랜치는 아직 MR/PR 전 리뷰를 거치지 않았다. 생성 전에 다음을 한다.\n1. Agent 도구로 리뷰 서브에이전트를 띄워 base 브랜치 대비 이 브랜치의 diff 를 리뷰하게 한다. %s 서브에이전트는 코드를 고치지 않고 지적만 보고한다.\n2. 지적을 검토해 타당한 것만 고친다. 고치지 않은 지적은 이유와 함께 사용자에게 보고한다.\n3. mkdir -p "%s" && touch "%s" 로 통과를 기록하고 MR/PR 생성을 다시 호출한다.\n사용자가 리뷰를 건너뛰라고 명시한 경우에만 1~2 를 생략한다.' \
  "$branch" "$criteria" "$(dirname "$marker")" "$marker"

jq -n --arg r "$msg" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
exit 0
