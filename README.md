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
├─ evals/
│  └─ skills.json
└─ vendor/
   └─ lock.json
```

`instructions/global.md`가 전역 지침 원본입니다. `skills/` 바로 아래에서 유효한 `SKILL.md`를 가진 디렉터리는 별도 설치 목록 없이 자동으로 발견됩니다. `ADDONS.md`에는 기본 설치에 포함되지 않는 선택 항목의 이름, 설명과 공식 source만 기록합니다.

| 에이전트 | 설치 경로 | 링크 대상 |
| --- | --- | --- |
| Claude Code | `~/.claude/CLAUDE.md` | `instructions/global.md` |
| Codex | `~/.codex/AGENTS.md` | `instructions/global.md` |
| Claude Code Skill | `~/.claude/skills/<name>` | `skills/<name>` |
| Codex Skill | `~/.agents/skills/<name>` | `skills/<name>` |

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
- 저장소에 의도하지 않은 로컬 변경이 없다.

직접 확인하려면 다음 명령을 사용할 수 있습니다.

```sh
readlink ~/.claude/CLAUDE.md
readlink ~/.codex/AGENTS.md
find skills -mindepth 2 -maxdepth 2 -name SKILL.md -print
git -C ~/Desktop/Projects/coding-agent-harness status --short --branch
```

공통 지침은 이미 열린 대화에 소급 적용되지 않을 수 있습니다. 설치 후 새 Codex 작업 또는 Claude Code 세션에서 확인합니다.

## 범위

Phase 2는 convention 기반 Skill 발견과 `typescript-type-design`, `frontend-testing`, `tanstack-query`, `react-performance`, `pull-request-writing`을 포함합니다. `evals/skills.json`은 자동 실행기가 아니라 Skill 선택 경계를 점검하는 최소 사례 모음입니다. `react-performance`가 참조하는 Vercel 규칙은 `vendor/lock.json`의 revision으로 고정하며 `vendor/` 자체는 설치하지 않습니다. `ADDONS.md`는 최초 설치 때 선택을 돕는 목록이며 add-on 설치법은 공식 source를 따릅니다. 프로젝트 템플릿, 진단 CLI, CI는 현재 범위에 포함하지 않습니다.
