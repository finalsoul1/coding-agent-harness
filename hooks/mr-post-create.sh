#!/usr/bin/env bash
# PostToolUse hook: MR/PR 이 실제로 만들어진 직후, 리뷰 후속 절차를 지시한다.
# mr-review-gate.sh 는 생성 전 한 번만 리뷰하므로, 그 리뷰를 반영하며 새로 쓴 주석과
# 생성 뒤 달리는 리뷰 코멘트는 볼 수 없다. 이 hook 이 그 두 구간을 맡는다.
# 리뷰 코멘트는 생성 시점에 아직 없으므로 Paseo 의 MR 구독으로 도착을 기다린다.
# 사람 리뷰에만 답글을 초안으로 두는 이유는, 사람에게 남기는 글은 관계와 맥락이 걸려 있어
# 사용자가 직접 확인해야 해서다.
# 생성 명령 감지 정규식은 mr-review-gate.sh 와 같게 유지한다. 한쪽만 고치면 게이트를
# 거친 MR 인데 후속 지시가 안 뜨거나, 그 반대가 된다.
# 잡지 못하는 경우: UI 로 만든 MR/PR, hook 이 없는 Codex, Paseo 밖의 세션(구독 불가),
# 리뷰 알림이 오기 전에 대화가 압축돼 이 지시가 요약에서 빠진 경우.

command -v jq >/dev/null 2>&1 || exit 0

input=$(cat)
tool=$(printf '%s' "$input" | jq -r '.tool_name // empty')

case "$tool" in
  mcp__gitlab__create_merge_request|mcp__github__create_pull_request) ;;
  Bash)
    cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
    if ! printf '%s' "$cmd" | grep -Eq '(glab[[:space:]]+mr|gh[[:space:]]+pr)[[:space:]]+create'; then
      printf '%s' "$cmd" | grep -Eq '(glab[[:space:]]+api|curl)[[:space:]].*merge_requests([?"'"'"'[:space:]]|$)|gh[[:space:]]+api[[:space:]].*/pulls([?"'"'"'[:space:]]|$)' || exit 0
      method=$(printf '%s' "$cmd" | sed -nE 's/.*(-X|--method|--request)[[:space:]=]*["'"'"']?([A-Za-z]+).*/\2/p' | tr '[:lower:]' '[:upper:]')
      if [ -z "$method" ]; then
        printf '%s' "$cmd" | grep -Eq '[[:space:]](-f|-F|--field|--raw-field|--input|-d|--data[a-z-]*|--form|--json)([[:space:]=]|$)' && method=POST
      fi
      [ "$method" = POST ] || exit 0
    fi
    printf '%s' "$cmd" | grep -Eq '(^|[[:space:]])--?h(elp)?([[:space:]]|$)' && exit 0
    ;;
  *) exit 0 ;;
esac

# 생성 실패 응답에는 MR/PR URL 이 없다.
# JSON 응답은 description 이 web_url 보다 앞에 오므로, 본문 속 다른 MR 링크를 잡지 않게
# web_url/html_url 키를 먼저 찾는다.
resp=$(printf '%s' "$input" | jq -r '.tool_response // empty | if type == "string" then . else tojson end')
pat='https://[^"[:space:]\\]+(/-/merge_requests|/pull)/[0-9]+'
url=$(printf '%s' "$resp" | grep -oE "(web_url|html_url)\\\\?\"[[:space:]]*:[[:space:]]*\\\\?\"$pat" | grep -oE "$pat" | head -1)
url=${url:-$(printf '%s' "$resp" | grep -oE "$pat" | head -1)}
[ -n "$url" ] || exit 0

msg="MR/PR 이 생성됐다: $url
다른 후속 단계(예: 해설 자료 작성)보다 아래 1~2 를 먼저 끝낸다.

1. 리뷰 확인: 리뷰 서브에이전트를 띄워 base 대비 이 브랜치의 diff 를 보게 하고, 서브에이전트는 지적만 보고하게 한다.
   - \`<git-dir>/agent-review/<브랜치, / 는 __ 로>\` 기록이 없으면 전체를 리뷰한다. 기준은 저장소에 \`.claude/skills/code-review\` 가 있으면 그 스킬, 없으면 정확성 버그·보안·기존 동작 회귀·저장소 규칙(CLAUDE.md/AGENTS.md) 위반과 주석이다. 끝나면 그 기록 파일을 만든다.
   - 기록이 있으면 주석만 다시 본다. 게이트 리뷰 뒤 그 지적을 반영하며 주석이 새로 생기거나 바뀌었을 수 있어서다.
   - 주석은 diff 가 추가·변경한 것과 바뀐 코드 주변의 기존 주석을 \"왜만 남긴다\" 규칙으로 보고, 코드를 되풀이하거나 바뀐 코드와 맞지 않거나 역할 설명·핸드오프·TODO 인 것을 지적하게 한다.
   - 타당한 지적만 고쳐 커밋·push 하고, 고치지 않은 지적은 이유와 함께 보고한다.
2. 리뷰 구독: mcp__paseo__subscribe_change_request 로 이 URL 을 구독한다. 도구 목록에 이름만 있으면 ToolSearch 로 불러와 쓴다. ToolSearch 로도 찾을 수 없으면(Paseo 밖) 자동 감시를 못 한다고 사용자에게 한 줄 알리고 끝낸다.

구독 알림으로 새 리뷰 코멘트가 오면, 알림 요약 대신 API(glab/gh)로 미해결 토론을 다시 읽고 각각 다음을 한다. 이미 처리한 토론은 건너뛴다.
- 지적이 타당한지 코드에서 검증한다. superpowers:receiving-code-review 스킬이 있으면 그 기준을 따른다.
- 타당하면 고치고, 커밋 전에 리뷰 서브에이전트에게 고친 diff 의 코드와 주변 주석을 재검토하게 한다. 지적을 반영한 뒤 커밋하고 push 한다.
- 봇 리뷰(작성자 username 이 GitLab \`GitLabDuo\` 이거나 \`_bot\` 을 포함, GitHub login 이 \`[bot]\` 으로 끝나거나 \`Copilot\`): 해당 토론에 반영 내용이나 반영하지 않은 이유를 답글로 남기고 resolve 한다. 본문은 파일로 넘긴다(-F body=@파일).
- 사람 리뷰: 커밋·push 까지 하고, 답글은 초안만 사용자에게 보여 준다. 사용자가 확인한 뒤에만 답글을 남기고, resolve 는 하지 않는다.
- 처리 결과를 토론별로 짧게 보고한다.
리뷰 코멘트가 아닌 알림(CI 실패, 승인 등)은 사용자에게 알리기만 한다. MR/PR 이 머지되거나 닫히면 구독을 해제한다.
사용자가 명시적으로 건너뛰라고 한 단계만 생략한다."

jq -n --arg c "$msg" '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$c}}'
exit 0
