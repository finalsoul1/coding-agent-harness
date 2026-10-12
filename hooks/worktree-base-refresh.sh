#!/usr/bin/env bash
# 워크트리를 새로 만들기 직전에 base의 원격 ref를 최신화한다.
# 분기는 전부 origin/<base> 기준이라 fetch만 하면 최신 상태로 체크아웃된다.
# 실패는 경고만 남기고 진행한다.
# 대상 저장소: 인자 1 > stdin JSON의 .cwd > $PWD

set -u

logfile="$HOME/.claude/branch-sync.log"

d="${1:-}"
event=""
if [ -z "$d" ]; then
  payload="$(cat 2>/dev/null || true)"
  get() { printf '%s' "$payload" | jq -r "$1" 2>/dev/null; }
  d="$(get '.cwd // empty')"
  event="$(get '.hook_event_name // empty')"
  case "$(get '.tool_name // empty')" in
    # Bash 훅은 모든 명령에 붙으므로 워크트리 생성 명령만 걸러낸다.
    # settings.json의 if 필터는 명령 접두사만 봐서 `cd x && git worktree add ...`를 놓친다.
    Bash)
      cmd="$(get '.tool_input.command // empty')"
      # 명령 위치의 git만 본다 - echo·grep 인자로 들어간 문자열에 오탐하지 않게
      printf '%s' "$cmd" | grep -Eq '(^|[;&|])[[:space:]]*git( +[^ ;&|]+)* +worktree +add' || exit 0
      # 세션 cwd가 저장소가 아니면(부모 디렉토리 세션) 명령의 `cd <dir>`에서 대상을 얻는다
      if ! git -C "${d:-$PWD}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        cd_dir="$(printf '%s' "$cmd" | sed -nE 's/.*(^|[;&|] *)cd +"?([^"&;|]+)"? *.*/\2/p' | head -1)"
        cd_dir="${cd_dir%% }"
        [ -n "$cd_dir" ] && [ -d "$cd_dir" ] && d="$cd_dir"
      fi
      ;;
    # name=생성, path=기존 워크트리 진입(최신화 불필요)
    EnterWorktree)
      [ -n "$(get '.tool_input.name // empty')" ] || exit 0
      ;;
  esac
fi
d="${d:-$PWD}"

emit() {
  if [ "$event" = "PreToolUse" ]; then
    jq -n --arg c "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",additionalContext:$c}}'
  else
    printf '%s\n' "$1"
  fi
}

if ! git -C "$d" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # 워크트리 생성인 건 이미 확인됐으니 조용히 넘기지 않는다.
  # 명령 안의 경로가 셸 변수면(payload는 미확장 문자열) 대상 저장소를 알 수 없다.
  [ -n "$event" ] && emit "[base-refresh] 대상 저장소를 찾지 못해 fetch 생략 (cwd=$d) - origin/base가 낡았을 수 있으니 직접 fetch할 것"
  exit 0
fi
git -C "$d" remote get-url origin >/dev/null 2>&1 || exit 0

base="${CLAUDE_BASE_BRANCH:-$(git -C "$d" config --get claude.baseBranch 2>/dev/null)}"
if [ -z "$base" ]; then
  rbase="$(git -C "$d" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)"
  if [ -z "$rbase" ]; then
    git -C "$d" remote set-head origin -a >/dev/null 2>&1
    rbase="$(git -C "$d" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)"
  fi
  base="${rbase#origin/}"
fi
[ -n "$base" ] || exit 0

if err="$(git -C "$d" fetch origin "$base" 2>&1 >/dev/null)"; then
  line="[base-refresh] origin/$base 최신화 완료 ($(git -C "$d" rev-parse --short "origin/$base" 2>/dev/null)) - 분기는 origin/$base 기준으로 할 것"
else
  line="[base-refresh] origin/$base fetch 실패 - 낡은 ref로 분기될 수 있음: $(printf '%s' "$err" | tr '\n' ' ' | cut -c1-200)"
fi

emit "$line"
printf '[%s] %s d=%s\n' "$(date '+%F %T')" "$line" "$d" >> "$logfile"
exit 0
