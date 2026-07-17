# coding-agent-harness Specification

Status: v1

## 1. 목적

Claude Code와 Codex에서 같은 개인용 개발 지침을 사용한다. 운영은 별도 프로그램이 아니라 AI 에이전트가 읽고 수행할 수 있는 명시적인 규칙으로 관리한다.

## 2. 설계 원칙

- `instructions/global.md`를 유일한 지침 원본으로 사용한다.
- 설치, push, pull, 제거는 `OPERATIONS.md`의 규칙을 따른다.
- 기존 사용자 파일은 사용자 자산으로 취급한다.
- 충돌은 임의로 해결하지 않고 사용자에게 선택을 요청한다.
- 백업은 명시적인 선택이 있을 때만 만들며 자동 삭제하지 않는다.
- Git의 기존 기능을 감싸는 별도 CLI를 만들지 않는다.
- 결과는 명령 실행 여부가 아니라 확인된 최종 상태로 판단한다.

## 3. 저장소 구조

```text
coding-agent-harness/
├─ README.md
├─ SPEC.md
├─ OPERATIONS.md
└─ instructions/
   └─ global.md
```

## 4. 설치 대상

| 에이전트 | 사용자 경로 | 원본 |
| --- | --- | --- |
| Claude Code | `~/.claude/CLAUDE.md` | `<repo>/instructions/global.md` |
| Codex | `~/.codex/AGENTS.md` | `<repo>/instructions/global.md` |

`<repo>`는 AI 에이전트가 현재 저장소의 절대 경로로 확인한다. 사용자 이름이나 고정된 홈 경로를 문서 또는 원본 지침에 기록하지 않는다.

## 5. 운영 계약

설치, push, pull, 제거, 충돌, 백업의 상세 조건과 중단 기준은 [OPERATIONS.md](./OPERATIONS.md)를 단일 운영 계약으로 사용한다.

AI 에이전트는 다음 순서를 공통으로 따른다.

1. 저장소와 대상 경로의 현재 상태를 읽는다.
2. 예정된 변경과 충돌을 식별한다.
3. 충돌이 없으면 최소 변경만 수행한다.
4. 충돌이 있으면 변경 전에 사용자에게 선택을 요청한다.
5. 완료 후 실제 파일, 링크, Git 상태를 다시 읽어 결과를 보고한다.

## 6. 완료 조건

- 두 사용자 경로가 같은 `instructions/global.md`를 가리킨다.
- 반복 설치해도 추가 변경이나 백업이 생기지 않는다.
- 다른 파일이나 링크가 있으면 사용자 선택 전에는 변경하지 않는다.
- 백업 이름이 충돌하지 않고 원본 내용이 보존된다.
- pull은 깨끗한 작업 트리에서 fast-forward 방식으로만 수행된다.
- push는 사용자가 요청한 변경만 포함하며 force push를 사용하지 않는다.
- 제거는 현재 저장소가 소유한 링크만 삭제한다.
- 사용자 파일, 백업, 저장소 원본은 제거되지 않는다.

## 7. 현재 제외 범위

- 설치·진단·업데이트·제거 CLI
- 프로젝트 초기화 템플릿
- Skills와 vendor 관리
- evals와 토큰 진단
- CI
- 인증정보 관리
