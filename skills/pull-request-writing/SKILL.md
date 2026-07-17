---
name: pull-request-writing
description: Git merge-base diff, commit, 실제 검증 결과, 저장소 PR template을 근거로 Pull Request 제목과 본문을 작성하거나 갱신한다. 사용자가 PR 작성, PR description·body·title 정리, 기존 PR 본문 갱신, review용 변경 요약을 요청할 때 사용한다. branch 생성, commit, push, merge 자체가 주목적인 작업에는 단독으로 사용하지 않고 저장소 운영 규칙을 따른다.
---

# Pull Request 작성

reviewer가 변경 목적, 범위, 검증 결과와 주의사항을 빠르게 이해하도록 사실에 근거한 PR 제목과 본문을 작성한다. Git 작업이나 공개 상태 변경은 저장소 운영 규칙에 맡긴다.

## 작업 순서

1. 저장소 지침, 현재 branch와 base branch, 기존 PR 여부를 확인한다.
2. 저장소의 PR template과 제목 관례를 먼저 찾는다.
3. merge-base 기준 commit과 diff, 변경된 test와 문서, 실제 검증 결과를 읽는다.
4. 변경 유형과 규모에 맞는 최소 구조로 제목과 본문을 작성한다.
5. 기존 PR을 갱신할 때 현재 본문의 사용자 작성 내용과 새 내용의 충돌을 확인한다.
6. 요청받은 경우에만 PR을 생성하거나 갱신하고 결과를 다시 읽어 확인한다.

## 근거 수집

- 기존 PR이 있으면 해당 PR의 base, remote head, title, body를 기준으로 삼는다. 아직 push하지 않은 commit은 같은 작업에서 publish할 것이 확인된 경우에만 포함한다.
- 기존 PR이 없으면 remote default branch나 명시된 target에서 base를 정한다.
- `git log <base>..HEAD`, `git diff --stat <base>...HEAD`, `git diff <base>...HEAD`로 PR에 포함될 변경만 확인한다.
- working tree 변경은 commit된 PR 범위와 구분한다. 포함되지 않은 변경을 PR 내용으로 서술하지 않는다.
- 실행된 test, type check, lint, build 결과는 실제 출력에서 확인한다. 실행하지 않은 검증은 성공했다고 쓰지 않는다.
- issue, ticket, 성능 수치, 사용자 영향은 확인된 근거가 있을 때만 적는다.

## Template과 제목

- `.github/`, 저장소 root, `docs/`의 `pull_request_template.md`와 `PULL_REQUEST_TEMPLATE/`을 확인한다.
- 대상 저장소 base branch에 template이 있으면 section과 필수 항목을 보존하고 내용을 채운다.
- 여러 template이 목적에 따라 나뉘고 선택이 결과를 크게 바꾸면 사용자에게 묻는다.
- title은 저장소 관례를 우선하고, 없으면 핵심 변경을 명령형으로 간결하게 쓴다.
- 저장소가 사용하지 않는 Conventional Commit prefix나 ticket 번호를 임의로 붙이지 않는다.

## 기본 본문

Template이 없으면 다음 항목에서 필요한 것만 선택한다.

```markdown
## 요약

- 핵심 변경과 사용자 또는 개발자 영향

## 배경

변경이 필요한 이유와 해결하려는 문제

## 검증

- `실행한 명령`: 확인된 결과
```

- bug fix에는 증상과 root cause, 해결 방식의 관계를 포함한다.
- 동작이나 interface가 바뀌면 호환성, migration, rollback 주의를 필요한 만큼 포함한다.
- UI 변경은 가능하면 같은 viewport의 Before/After와 관찰할 차이를 포함한다.
- 변경 파일이 많거나 검토 순서가 중요하면 reviewer가 먼저 볼 위치를 안내한다.
- 관련 issue가 확인되면 실제 reference와 `Closes` 같은 의도된 keyword만 사용한다.
- 검증하지 못한 경우 `미실행`과 이유를 명시한다.

작은 PR에는 짧은 문단과 검증 항목만으로 충분하다. 빈 section, 의미 없는 checkbox, diff의 파일 목록 복사, 개발 과정의 시간순 기록은 넣지 않는다.

## 생성과 갱신

- PR 작성만 요청받았으면 title과 body 초안을 제시하고 외부 상태를 바꾸지 않는다.
- 생성 또는 갱신을 명시적으로 요청받았을 때 저장소 운영 규칙에 따라 target repo, base, head와 권한을 확인한다.
- CLI를 사용할 때 Markdown body를 임시 파일에 작성하고 `--body-file`로 전달한다.
- 기존 PR의 수동 설명, issue link, reviewer note를 삭제하거나 의미를 바꿔야 하면 먼저 사용자에게 선택을 요청한다.
- draft와 ready 상태는 사용자 요청과 저장소 정책을 따르며 PR 본문 갱신만으로 상태를 바꾸지 않는다.

## 완료 보고

사용한 base와 변경 범위, 적용한 template, 기록한 검증, 생략하거나 확인하지 못한 항목, 생성·갱신한 PR URL을 필요한 만큼 보고한다.
