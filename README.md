# coding-agent-harness

Claude Code와 Codex가 같은 개인용 개발 지침을 사용하도록 연결하는 저장소입니다.

별도 CLI나 패키지는 없습니다. AI 에이전트가 [OPERATIONS.md](./OPERATIONS.md)의 규칙에 따라 설치, push, pull, 제거를 수행합니다.

## 구성

```text
coding-agent-harness/
├─ README.md
├─ SPEC.md
├─ OPERATIONS.md
├─ ADDONS.md
├─ instructions/
│  └─ global.md
├─ skills/
│  └─ <skill-name>/
│     ├─ SKILL.md
│     └─ agents/
│        └─ openai.yaml
├─ hooks/
│  ├─ claude-settings.json
│  └─ <hook-file>
├─ evals/
│  └─ skills.json
└─ vendor/
   └─ lock.json
```

`instructions/global.md`가 전역 지침 원본입니다. `skills/` 바로 아래에서 유효한 `SKILL.md`를 가진 디렉터리는 별도 설치 목록 없이 자동으로 발견됩니다. `ADDONS.md`에는 기본 설치에 포함되지 않는 선택 항목의 이름, 설명과 공식 source만 기록합니다.

`hooks/`에는 Claude Code hook 스크립트와, 그 스크립트를 등록하는 `settings.json` 조각인 `claude-settings.json`이 있습니다. 스크립트는 파일 단위로 링크하고, 조각은 사용자 동의를 받아 `~/.claude/settings.json`에 병합합니다.

| 에이전트 | 설치 경로 | 링크 대상 |
| --- | --- | --- |
| Claude Code | `~/.claude/CLAUDE.md` | `instructions/global.md` |
| Codex | `~/.codex/AGENTS.md` | `instructions/global.md` |
| Claude Code Skill | `~/.claude/skills/<name>` | `skills/<name>` |
| Codex Skill | `~/.agents/skills/<name>` | `skills/<name>` |
| Claude Code Hook | `~/.claude/hooks/<file>` | `hooks/<file>` |
| Claude Code Hook 등록 | `~/.claude/settings.json`의 `hooks` | `hooks/claude-settings.json` (병합) |

Codex에는 대응하는 hook 기능이 없어 Skill과 전역 지침만 연결됩니다.

## Hook

| 파일 | 이벤트 | 하는 일 |
| --- | --- | --- |
| `korean-writing-guard.py` | PreToolUse · Stop · UserPromptSubmit | 한글이 든 출력(파일, 명령, 쓰기 계열 MCP, 질문, 채팅 답변) 전에 `korean-writing` Skill을 거치게 한다. 마지막 압축 이후 한 번 불렀으면 통과하고, 매 턴 한 줄 알림으로 다시 점검하게 한다. |
| `comment-guard.sh` | PostToolUse(Edit\|Write) | JS/TS 편집이 새로 추가한 주석을 찾아 「왜만 남긴다」 규칙으로 재검토하게 한다. |
| `memory-index-size.sh` | PostToolUse(Edit\|Write) | `~/.agent-memory/MEMORY.md` 항목이 150개를 넘으면 인덱스 계층화를 안내한다([MEMORY.md](./MEMORY.md)). |
| `worktree-base-refresh.sh` | PreToolUse(Bash · EnterWorktree) | 워크트리를 만들기 직전에 `origin/<base>`를 fetch한다. base는 `CLAUDE_BASE_BRANCH`, `git config claude.baseBranch`, `origin/HEAD` 순으로 정한다. |
| `mr-review-gate.sh` | PreToolUse(Bash · GitLab/GitHub MR·PR 생성 MCP) | `glab mr create`·`gh pr create`나 MR/PR 생성 MCP 호출 전에 리뷰 서브에이전트를 거치게 한다. 통과 기록은 `<git-dir>/agent-review/<branch>`에 브랜치 단위로 남긴다. 저장소에 `.claude/skills/code-review`가 있으면 그 기준으로 리뷰한다. |
| `submodule-init.sh` | SessionStart (선택) | 새 워크트리에서 비어 있는 서브모듈을 받는다. |

`submodule-init.sh`는 세션을 시작할 때마다 네트워크로 서브모듈을 받으므로 `claude-settings.json`에 넣지 않았습니다. 쓰려면 직접 등록합니다.

```json
{ "hooks": { "SessionStart": [ { "hooks": [ { "type": "command", "command": "bash \"$HOME/.claude/hooks/submodule-init.sh\"", "timeout": 180 } ] } ] } }
```

`korean-writing-guard.py`는 `KOREAN_WRITING_GUARD=off` 환경변수로 잠시 끌 수 있습니다.

hook은 `jq`와 `python3`가 PATH에 있어야 동작합니다. macOS 15 이상은 `jq`를 기본으로 제공하고, `python3`는 Xcode Command Line Tools나 Homebrew로 설치합니다. 등록한 hook은 새 Claude Code 세션부터 적용됩니다.

## AI 에이전트에게 요청하기

저장소 경로가 다르면 요청문의 경로만 바꿉니다.

### 설치

```text
~/Desktop/Projects/coding-agent-harness의 README.md와 OPERATIONS.md를 읽고 설치해줘.
변경 전에 대상 경로를 확인하고, 충돌이 있으면 임의로 처리하지 말고 선택을 물어봐.
백업을 선택하면 문서의 백업 규칙을 따르고, 완료 후 링크와 Git 상태를 확인해줘.
```

최초 설치라면 AI 에이전트가 `ADDONS.md`의 목록과 설명을 보여주고 함께 설치할 항목을 묻습니다. 선택한 add-on의 설치법은 공식 source에서 확인합니다.

### Pull

```text
~/Desktop/Projects/coding-agent-harness를 업데이트해줘.
README.md와 OPERATIONS.md를 읽고 pull 규칙을 따라 진행해.
로컬 변경이나 브랜치 분기가 있으면 임의로 처리하지 말고 선택을 물어봐.
완료 후 설치 상태도 다시 확인해줘.
```

### Push

```text
~/Desktop/Projects/coding-agent-harness의 변경사항을 push해줘.
README.md와 OPERATIONS.md를 읽고 push 규칙을 따라 진행해.
관련 변경만 커밋하고, 원격 변경이나 충돌이 있으면 임의로 해결하지 말고 알려줘.
```

### 제거

```text
~/Desktop/Projects/coding-agent-harness 설치를 제거해줘.
README.md와 OPERATIONS.md를 읽고 제거 규칙을 따라 진행해.
이 저장소가 소유한 링크만 제거하고 사용자 파일과 백업은 보존해줘.
```

## 설치 확인

AI 에이전트는 설치 후 다음 조건을 확인하고 실제 경로를 출력해야 합니다.

- `~/.claude/CLAUDE.md`가 이 저장소의 `instructions/global.md`를 가리킨다.
- `~/.codex/AGENTS.md`가 이 저장소의 `instructions/global.md`를 가리킨다.
- 두 링크의 원본 파일을 읽을 수 있다.
- 발견된 모든 Skill이 Claude Code와 Codex의 Skill 경로에 연결된다.
- 발견된 모든 hook 파일이 `~/.claude/hooks/`에 연결되고, `claude-settings.json`의 항목이 `~/.claude/settings.json`에 들어 있다.
- 저장소에 의도하지 않은 로컬 변경이 없다.

직접 확인하려면 다음 명령을 사용할 수 있습니다.

```sh
readlink ~/.claude/CLAUDE.md
readlink ~/.codex/AGENTS.md
find skills -mindepth 2 -maxdepth 2 -name SKILL.md -print
ls -l ~/.claude/hooks
jq '.hooks | keys' ~/.claude/settings.json
git -C ~/Desktop/Projects/coding-agent-harness status --short --branch
```

## 권장 설정 (설치 대상 아님)

이 저장소는 hook 등록 항목을 빼면 에이전트 설정 파일을 소유하지 않습니다. 아래는 사용자가 직접 적용하는 선택 항목입니다.

| 에이전트 | 설정 | 값 | 이유 |
| --- | --- | --- | --- |
| Claude Code | `~/.claude/settings.json`의 `outputStyle` | `Concise` | 결론부터, 서론·재요약 없이 답하게 합니다. `instructions/global.md`의 분량 규칙과 같은 방향이며 충돌하지 않습니다. |

`/config outputStyle=Concise`로도 설정할 수 있고, 이때 Claude Code가 프로젝트의 `.claude/settings.local.json`에 기록합니다. 전역으로 두려면 `~/.claude/settings.json`에 직접 적습니다. 자세한 내용은 [Output styles](https://code.claude.com/docs/en/output-styles) 문서를 참고합니다.

Codex에는 대응 기능이 없으므로 분량 규칙은 `instructions/global.md`가 단독으로 담당합니다. 이 설정이 없어도 지침은 그대로 동작합니다.

공통 지침은 이미 열린 대화에 소급 적용되지 않을 수 있습니다. 설치 후 새 Codex 작업 또는 Claude Code 세션에서 확인합니다.

## 범위

Phase 2는 convention 기반 Skill 발견과 `typescript-type-design`, `frontend-testing`, `tanstack-query`, `react-performance`, `pull-request-writing`을 포함합니다. Phase 3은 `korean-writing`, `technical-concept-deep-dive` Skill과 Claude Code hook 설치를 더합니다. `evals/skills.json`은 자동 실행기가 아니라 Skill 선택 경계를 점검하는 최소 사례 모음입니다. `react-performance`가 참조하는 Vercel 규칙은 `vendor/lock.json`의 revision으로 고정하며 `vendor/` 자체는 설치하지 않습니다. `ADDONS.md`는 최초 설치 때 선택을 돕는 목록이며 add-on 설치법은 공식 source를 따릅니다. 프로젝트 템플릿, 진단 CLI, CI는 현재 범위에 포함하지 않습니다.
