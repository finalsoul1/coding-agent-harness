# coding-agent-harness Specification

Status: Draft v0.4 (reconstructed)

## 1. 목적

`coding-agent-harness`는 Claude Code와 Codex에서 재사용할 수 있는 개인용 코딩 에이전트 환경이다.

다음을 한 저장소에서 관리한다.

- 공통 개발 지침
- 에이전트별 연결 설정
- 직접 관리하는 Skills
- 외부 Skills의 고정된 원본
- 프로젝트 초기화 템플릿
- 설치, 상태 확인, 진단, 업데이트, 제거 도구
- Skill 선택과 동작을 검증하는 evals

최우선 목표는 정확하고 유지보수하기 좋은 결과다. 토큰 절약은 결과 품질을 제한하는 고정 한도가 아니라, 중복되거나 관련 없는 컨텍스트를 줄이는 방식으로 달성한다.

## 2. 성공 기준

- 한 번의 설치로 Claude Code와 Codex가 같은 공통 지침과 Skills를 사용할 수 있다.
- 설치를 반복해도 설정이 중복되거나 손상되지 않는다.
- 기존 사용자 설정은 덮어쓰지 않고 백업하거나 충돌을 보고한다.
- 직접 관리하는 파일과 외부에서 가져온 파일이 분리된다.
- 외부 Skill 업데이트가 사용자 수정을 덮어쓰지 않는다.
- 특정 에이전트에 종속되지 않은 지식과 예제를 재사용할 수 있다.
- 프로젝트별 설정은 필요한 경우에만 선택적으로 생성한다.
- 실제 사용 중 발견한 실패 사례를 eval로 추가하고 Skill을 개선할 수 있다.
- 컨텍스트 사용량을 진단할 수 있지만, 토큰 한도가 필요한 자료의 로딩을 막지 않는다.

## 3. 설계 원칙

### 3.1 우선순위

원칙이 충돌하면 다음 순서로 판단한다.

1. 사용자의 명시적인 요청
2. 정확성, 보안, 데이터 무결성
3. 프로젝트에 명시된 규칙과 제약
4. 기존 동작과 변경 범위 보존
5. 현재 버전의 공식 문서와 권장 방식
6. 검증된 기존 프로젝트 패턴
7. 공통 지침의 일반 원칙
8. 일반적인 베스트 프랙티스

기존 코드에 존재한다는 이유만으로 좋은 패턴이나 프로젝트 규칙으로 간주하지 않는다.

명백한 안티패턴은 새 코드에 복제하지 않되, 요청 범위를 넘어 주변 코드를 리팩터링하지 않는다.

### 3.2 Quality-first Context Efficiency

- 정확하고 완전한 결과를 토큰 절약보다 우선한다.
- 가장 관련성이 높은 자료부터 점진적으로 읽는다.
- 충분한 판단 근거가 확보되면 추가 자료를 읽지 않는다.
- 근거가 부족하거나 규칙이 충돌하면 필요한 자료를 더 읽는다.
- 결과 품질에 필요한 reference 개수에는 고정 제한을 두지 않는다.
- 전체 통합 문서, 중복 문서, 관련 없는 문서의 로딩을 피한다.
- 토큰 기준은 차단 규칙이 아니라 진단 지표로 사용한다.

### 3.3 소유권 분리

- `skills/`: 사용자가 직접 작성하고 수정하는 Skills와 curated adapters
- `vendor/skills/`: 수정하지 않는 외부 Skill 원본
- `instructions/`: 항상 적용할 짧은 공통 지침
- `templates/`: 프로젝트에 선택적으로 복사할 진입 문서
- `evals/`: Skill 선택과 결과 품질을 검증하는 사례

## 4. 범위

### Phase 1 — Core Harness

- 저장소 기본 구조
- 공통 전역 지침
- Claude Code와 Codex 설치 연결
- 프로젝트 초기화 템플릿
- `install`, `status`, `doctor`, `init`, `update`, `uninstall` 명령
- 기존 파일 백업과 멱등 설치
- macOS와 일반적인 POSIX shell 환경 지원

### Phase 2 — Skill Management

- Vercel React Best Practices 원본 버전 고정
- `react-performance` curated adapter
- `tanstack-query` Skill
- `frontend-testing` Skill
- `typescript-type-design` Skill
- Skill lock과 vendor 업데이트 흐름
- Skill 구조 검증
- routing 및 selection evals
- 토큰 사용 진단

### 초기 범위에서 제외

- 범용 TypeScript 문서
- 웹 접근성 Skill
- 조직별 또는 프로젝트별 아키텍처 규칙의 강제 제공
- 비밀정보와 MCP 인증정보 관리
- 모든 운영체제와 모든 에이전트 지원
- 외부 Skill의 무조건적인 자동 업데이트

## 5. 저장소 구조

```text
coding-agent-harness/
├─ README.md
├─ SPEC.md
├─ install.sh
├─ uninstall.sh
├─ bin/
│  └─ harness
├─ instructions/
│  ├─ global.md
│  ├─ claude.md
│  └─ codex.md
├─ templates/
│  ├─ AGENTS.md
│  └─ CLAUDE.md
├─ skills/
│  ├─ react-performance/
│  │  ├─ SKILL.md
│  │  ├─ routing.yaml
│  │  └─ references/
│  ├─ tanstack-query/
│  │  ├─ SKILL.md
│  │  ├─ references/
│  │  ├─ examples/
│  │  └─ evals/
│  ├─ frontend-testing/
│  │  ├─ SKILL.md
│  │  ├─ references/
│  │  ├─ examples/
│  │  └─ evals/
│  └─ typescript-type-design/
│     ├─ SKILL.md
│     ├─ references/
│     ├─ examples/
│     └─ evals/
├─ vendor/
│  ├─ skills/
│  │  └─ vercel-react-best-practices/
│  ├─ lock.json
│  └─ rule-index.md
├─ evals/
│  ├─ routing/
│  └─ selection/
└─ scripts/
   ├─ build-rule-index.*
   ├─ check-skills.*
   └─ token-report.*
```

스크립트 언어와 실제 파일 확장자는 구현 시 저장소의 런타임 정책을 결정한 뒤 확정한다.

## 6. 공통 지침

공통 지침의 원본은 `instructions/global.md`다. 항상 로드되는 문서이므로 짧고 안정적인 원칙만 포함한다.

### 권장 내용

```md
# Coding Agent Guidelines

## 목표

쉽고 정확하게 설명하고, 최소 변경으로 유지보수하기 좋은 코드를 작성한다.

## 우선순위

정확성 > 단순함 > 유지보수성 > 성능 > 편의성

## 원칙

- 먼저 이해하고 그다음 수정한다.
- 작은 변경으로 문제를 해결한다.
- 요청하지 않은 변경은 하지 않는다.
- 의도가 명확하지 않으면 기존 의도를 보존한다.
- 코드는 작성하기보다 이해하기 쉬워야 한다.

## 설명

- 결론부터 설명한다.
- 목표, 요구사항, 제약은 명확히 작성한다.
- 코드명, 함수명, API 필드명, 에러 메시지, 데이터 모델은 원문 그대로 쓴다.
- 쉬운 단어를 사용하고 필요한 전문 용어만 짧게 설명한다.
- 사용법뿐 아니라 필요한 원리와 이유를 설명한다.
- 예시는 이해를 높일 때만 사용한다.
- 질문과 관계없는 내용, 반복, 불필요한 서론과 마무리는 생략한다.
- 확실하지 않으면 추측하지 않고 사실과 추측을 구분한다.

## 코드

- 기존 코드의 의도, 공개 인터페이스, 유효한 프로젝트 규칙을 존중한다.
- 기존 코드에 있다는 이유만으로 안티패턴을 새 코드에 복제하지 않는다.
- 변경 범위를 최소화한다.
- 불필요한 추상화, 리팩터링, 최적화는 하지 않는다.
- 실제 프로젝트에서 사용할 수 있는 코드를 작성한다.
- 코드와 설명을 일치시킨다.
- 프로젝트의 언어, 프레임워크, 공식 문서와 기존 관례를 우선한다.

## 문제 해결

- 원인을 먼저 찾고 수정한다.
- 한 번에 하나씩 변경하고 적절한 수준으로 검증한다.
- 관찰한 사실과 추측을 구분한다.
- 중요한 정보가 부족하고 안전한 가정이 불가능하면 확인한다.
- 버그 수정과 리팩터링은 별개의 작업으로 다룬다.

## 판단

- 기존 구현이 충분히 좋다면 변경하지 않는다.
- 새로운 의존성은 명확한 이점이 있을 때만 추가한다.
- 영리한 코드보다 읽기 쉬운 코드를 선택한다.
- DRY보다 명확성을 우선한다.
- 조기 추상화보다 작은 중복을 허용한다.

## 소통

- 여러 선택지가 있으면 비교 후 추천안과 근거를 제시한다.
- 확신 정도를 명확히 표현한다.
- 필요한 만큼만 답하고, 목록과 표는 가독성을 높일 때만 사용한다.
- 강조는 꼭 필요한 부분에만 사용한다.
```

React, TanStack Query, 테스트 같은 상세 지식은 공통 지침에 중복하지 않는다. 해당 Skill이 필요할 때만 로드한다.

## 7. 에이전트 연결

### 7.1 원본과 노출 위치

저장소의 파일은 원본이다. 설치 과정에서 에이전트가 탐색하는 위치에 심볼릭 링크를 생성한다.

예상 연결:

```text
Claude Code
~/.claude/CLAUDE.md
~/.claude/skills/<skill-name>

Codex
~/.codex/AGENTS.md
~/.agents/skills/<skill-name>
```

실제 지원 경로는 구현 시 각 제품의 현재 공식 문서와 설치 환경을 확인한다. 사용자 정의 경로가 있으면 이를 존중한다.

### 7.2 vendor는 직접 노출하지 않음

`vendor/skills/`는 외부 원본과 버전을 보관하는 내부 위치다. 이 경로를 Claude Code나 Codex의 Skill 탐색 경로에 직접 연결하지 않는다.

에이전트에는 `skills/` 아래의 직접 관리 Skill과 curated adapter만 노출한다.

```text
vendor/skills/vercel-react-best-practices
                 ↑ 필요한 원문 규칙만 참조
skills/react-performance
                 ↓ symlink
~/.claude/skills/react-performance
~/.agents/skills/react-performance
```

이 구조는 외부 업데이트와 사용자 수정의 충돌을 막고, 너무 넓은 upstream Skill이 불필요하게 호출되는 것을 줄인다.

## 8. 프로젝트 초기화

프로젝트 공통 문서는 미리 많은 내용을 채워 두지 않는다.

`harness init <project>`는 기본적으로 다음 파일만 선택적으로 생성한다.

- `AGENTS.md`
- `CLAUDE.md`

이 파일들의 역할은 다음과 같다.

- 프로젝트의 실제 명령, 제약, 기준 구현을 기록할 자리 제공
- 관련 Skills를 언제 사용할지 안내
- 프로젝트 내부의 상세 문서가 생기면 그 문서로 라우팅

`docs/engineering/`은 실제 프로젝트 규칙이 생겼을 때만 생성한다. 빈 디렉터리나 내용 없는 문서를 기본 구조로 강제하지 않는다.

이미 파일이 있으면 기본 동작은 건너뛰고 상태를 보고한다. 명시적인 병합 또는 교체 옵션은 구현 단계에서 별도로 설계한다.

## 9. Skill 설계

### 9.1 공통 원칙

- Skill은 하나의 일관된 판단 능력이나 반복 워크플로를 표현한다.
- `SKILL.md`는 호출 조건, 판단 순서, reference 라우팅 중심으로 짧게 유지한다.
- 상세 설명과 예제는 작은 reference 파일로 분리한다.
- 같은 내용을 전역 지침과 Skill에 중복하지 않는다.
- description은 필요한 작업에서만 호출되도록 구체적으로 작성한다.
- reference는 관련성이 높은 것부터 읽고, 판단에 충분하면 멈춘다.
- 품질에 필요하면 추가 reference를 제한 없이 읽을 수 있다.
- scripts는 긴 성공 로그보다 실패 원인과 다음 행동을 요약한다.

### 9.2 `react-performance`

Vercel React Best Practices 전체를 그대로 노출하지 않는 curated adapter다.

활성화 대상:

- waterfall
- bundle size
- 비싼 렌더링
- 불필요한 re-render
- 명시적인 React 또는 Next.js 성능 개선과 리뷰

평범한 컴포넌트 수정만으로 자동 호출하지 않도록 description을 좁게 작성한다.

예시 description:

```yaml
description: >
  Review React and Next.js code for performance problems.
  Use for waterfalls, bundle size, expensive rendering,
  unnecessary re-renders, or explicit performance optimization.
  Do not use for routine component edits without a performance concern.
```

### 9.3 `tanstack-query`

TanStack Query의 서버 상태 모델링과 캐시 동작을 다룬다.

주요 범위:

- 현재 설치 버전 확인
- query key와 query function 의존성
- `queryOptions`
- mutations
- invalidation 범위
- optimistic update와 rollback
- prefetching, dependent query, infinite query
- 기본 cache 정책의 의미

프로젝트의 query key factory, API layer, DTO 정책은 프로젝트 규칙으로 취급하며 Skill의 일반 지식과 분리한다.

### 9.4 `frontend-testing`

테스트를 무조건 추가하는 규칙이 아니라, 변경에 맞는 테스트 수준과 최소 검증을 판단하는 Skill이다.

주요 범위:

- Testing Library의 사용자 관점 query
- 구현 세부사항보다 관찰 가능한 동작 검증
- `data-testid`의 후순위 사용
- Playwright의 안정적인 locator와 자동 대기
- 테스트 독립성
- 명시적인 sleep 회피
- regression과 flaky test 진단

사용자가 테스트를 요청하거나, 관찰 가능한 동작이 바뀌거나, 회귀 및 flaky test를 다룰 때 활성화한다.

### 9.5 `typescript-type-design`

범용 TypeScript 문법 가이드가 아니라 타입 설계 실패를 찾아 최소 변경으로 교정하는 Skill이다.

주요 범위:

- 불가능하거나 모순된 상태를 허용하는 모델
- discriminated union과 exhaustive checking
- 외부 데이터의 `unknown` 처리와 런타임 검증
- 위험한 타입 단언과 non-null assertion
- 경계를 넘어 전파되는 `any`
- 입력과 출력의 관계를 표현하지 않는 제네릭
- optional, `undefined`, `null`의 의미 구분
- `satisfies` 등을 통한 추론 보존

초기 Skill에서 제외할 내용:

- `interface`와 `type` 중 하나를 무조건 선호
- 모든 타입 단언 또는 `any`의 기계적인 금지
- branded type의 무조건적인 사용
- 복잡한 type-level programming 권장
- `tsconfig` 엄격 옵션의 일괄 활성화
- 프로젝트 전체 DTO 구조 변경

## 10. Vendor 규칙 선택

### 10.1 원칙

vendor 발췌는 원문을 미리 요약해 복사하는 방식이 아니다. 작업과 코드 증거에 따라 관련 upstream 원문 규칙을 선택하는 방식이다.

### 10.2 규칙 색인

vendor 업데이트 시 개별 규칙의 메타데이터를 파싱하여 `vendor/rule-index.md`를 생성한다.

색인 항목:

- rule id
- title
- impact
- tags
- source path
- source commit 또는 고정 버전
- routing 상태

색인에는 규칙 본문을 복사하지 않는다.

### 10.3 `routing.yaml`

사람이 작업 신호와 upstream 카테고리의 관계를 정의한다.

```yaml
routes:
  waterfalls:
    signals:
      - sequential awaits
      - independent requests executed serially
    prefixes:
      - async-

  bundle:
    signals:
      - large initial bundle
      - barrel imports
      - heavy module loaded eagerly
    prefixes:
      - bundle-

  rerender:
    signals:
      - unnecessary re-render
      - effect-derived state
      - expensive component update
    prefixes:
      - rerender-
```

`routing.yaml`은 개별 요청에서 읽을 파일을 고정하지 않는다. 후보 범위를 좁히는 역할만 한다.

### 10.4 실제 선택 순서

1. 사용자의 작업 의도
2. 대상 코드에서 관찰한 문제
3. 설치된 프레임워크와 라이브러리
4. 프로젝트 제약
5. rule tags와 코드 증거의 일치
6. impact

실제 문제와 관련된 원문부터 읽는다. 판단에 충분하면 멈추며, 근거가 부족하거나 규칙이 충돌하면 더 읽는다.

다음은 기본적으로 읽지 않는다.

- vendor 전체 `SKILL.md`
- vendor 전체 통합 `AGENTS.md`
- 모든 rules 파일
- 이미 읽은 내용과 중복되는 문서

### 10.5 프로젝트 제약

외부 규칙이 새 의존성이나 특정 라이브러리를 전제로 하면 자동 적용하지 않는다.

예:

```yaml
constraints:
  - rule: client-swr-dedup
    deny_when:
      - project uses TanStack Query for the same server state

  - rule: async-dependencies
    allow_when:
      - dependency is already installed
      - user explicitly accepts a new dependency
```

### 10.6 업데이트 흐름

1. 고정된 vendor 버전을 명시적으로 업데이트한다.
2. 규칙 색인을 다시 생성한다.
3. 추가, 삭제, 변경된 규칙을 비교한다.
4. 새 규칙은 `unmapped` 상태로 둔다.
5. 사용 중인 mapped 규칙이 삭제되면 업데이트를 실패 처리하거나 명확히 경고한다.
6. routing과 selection evals를 실행한다.
7. 검토 후 새 규칙을 활성화한다.

upstream 업데이트만으로 에이전트 동작이 조용히 바뀌어서는 안 된다.

## 11. CLI 명세

실행 인터페이스는 `bin/harness`를 기준으로 한다.

### `harness install`

- 필요한 상위 디렉터리를 생성한다.
- 공통 지침과 Skills를 에이전트 탐색 위치에 연결한다.
- vendor Skills는 직접 연결하지 않는다.
- 기존 대상이 같은 원본을 가리키면 성공으로 처리한다.
- 다른 파일이나 링크가 있으면 덮어쓰지 않고 백업 또는 충돌을 보고한다.
- 중간 실패 시 가능한 범위에서 이전 상태를 보존한다.

### `harness status`

- 설치된 에이전트별 연결 상태를 표시한다.
- 누락, 정상, 충돌, 끊어진 링크를 구분한다.
- Skill 원본과 vendor lock 상태를 요약한다.

### `harness doctor`

- 필수 파일과 `SKILL.md` 구조를 검사한다.
- 링크가 올바른 원본을 가리키는지 검사한다.
- vendor lock과 실제 원본이 일치하는지 검사한다.
- routing 대상이 존재하는지 검사한다.
- 비밀정보나 사용자 환경에 종속된 경로의 포함 여부를 가능한 범위에서 검사한다.

옵션:

```text
harness doctor --tokens
```

토큰 진단은 다음을 보고한다.

- 항상 로드되는 공통 지침의 예상 크기
- Skill descriptions의 누적 크기
- 각 `SKILL.md`와 reference의 예상 크기
- 중복 가능성이 높은 문서
- 지나치게 넓은 description 후보

경고 기준은 진단용이며 설치나 작업 수행을 차단하지 않는다.

### `harness init [project]`

- 대상 프로젝트를 확인한다.
- `AGENTS.md`, `CLAUDE.md`를 선택적으로 생성한다.
- 기존 파일은 덮어쓰지 않는다.
- 빈 `docs/engineering/`을 기본 생성하지 않는다.

### `harness update`

- 하네스 저장소 자체 업데이트와 vendor 업데이트를 구분한다.
- vendor는 lock에 기록된 버전을 기본으로 유지한다.
- vendor 업데이트는 diff, 색인 재생성, eval 통과 후 반영한다.
- 직접 관리하는 `skills/` 파일은 vendor 업데이트로 덮어쓰지 않는다.

### `harness uninstall`

- 하네스가 생성한 것으로 확인되는 링크만 제거한다.
- 실제 사용자 파일이나 링크 대상 원본은 삭제하지 않는다.
- 백업 파일은 자동 삭제하지 않는다.
- 제거 결과와 남은 파일을 보고한다.

## 12. 설치 안전성

- 모든 명령은 반복 실행 가능해야 한다.
- 광범위한 경로를 재귀적으로 삭제하지 않는다.
- 대상 경로를 명시적으로 확인한 뒤 변경한다.
- 기존 파일은 사용자 자산으로 취급한다.
- 백업 이름에는 충돌하지 않는 timestamp 또는 고유 식별자를 사용한다.
- 저장소에는 API 키, 토큰, MCP 인증정보, 사내 경로, 비공개 코드 예제를 넣지 않는다.
- 심볼릭 링크를 지원하지 않는 환경의 fallback은 구현 단계에서 별도로 결정한다.

## 13. Evals

Evals는 실제 사용 중 발견한 실패 사례를 축적하는 회귀 방지 장치다.

### Routing eval

- 요청에 맞는 Skill이 선택되는가
- 관련 없는 Skill이 선택되지 않는가
- 여러 Skill이 필요한 복합 요청을 올바르게 구분하는가

### Selection eval

- 코드 증거에 맞는 vendor 규칙이 선택되는가
- 관련성이 낮은 통합 문서를 불필요하게 읽지 않는가
- 더 많은 근거가 필요한 경우 추가 reference를 읽는가
- 프로젝트 제약과 충돌하는 규칙을 제외하는가

### Near-miss eval

표면적인 키워드는 유사하지만 Skill 또는 규칙이 필요하지 않은 사례를 포함한다. description과 routing이 과도하게 넓어지는 것을 방지한다.

### Expected behavior

각 eval은 최소한 다음을 기록한다.

- 입력 요청
- 최소 프로젝트 맥락
- 선택되어야 하는 Skill
- 선택되지 않아야 하는 Skill
- 필요한 reference 또는 판단 근거
- 기대 결과의 핵심 조건

## 14. 버전과 외부 원본 관리

`vendor/lock.json`은 최소한 다음 정보를 기록한다.

```json
{
  "skills": {
    "vercel-react-best-practices": {
      "source": "vercel-labs/agent-skills",
      "path": "skills/react-best-practices",
      "revision": "<commit-or-release>",
      "installedAt": "<iso-date>"
    }
  }
}
```

정확한 commit 또는 release를 사용하고, floating branch만 기록하지 않는다.

라이선스와 재배포 조건을 확인하고, 필요한 attribution과 원본 링크를 README에 포함한다.

## 15. Acceptance Criteria

### Phase 1 완료 조건

- 깨끗한 환경에서 `harness install`이 성공한다.
- Claude Code와 Codex의 공통 지침 및 직접 관리 Skills 연결을 확인할 수 있다.
- 같은 설치를 다시 실행해도 중복 백업이나 잘못된 링크가 생기지 않는다.
- 기존 설정이 있을 때 사용자 데이터가 덮어써지지 않는다.
- `status`와 `doctor`가 정상, 누락, 충돌 상태를 구분한다.
- `init`이 기존 프로젝트 문서를 보존한다.
- `uninstall`이 하네스가 만든 링크만 제거한다.

### Phase 2 완료 조건

- 네 개의 초기 Skills가 서로 구분되는 trigger와 reference routing을 가진다.
- vendor Skill은 직접 노출되지 않는다.
- 고정된 Vercel 원본에서 규칙 색인을 재현할 수 있다.
- 새 vendor 규칙은 자동 활성화되지 않고 `unmapped`로 표시된다.
- routing, selection, near-miss evals가 실행된다.
- 토큰 진단이 중복과 과도한 컨텍스트 후보를 보고하지만 품질에 필요한 로딩을 막지 않는다.
- 실제 실패 사례를 eval로 추가하고 다시 검증하는 흐름이 문서화된다.

## 16. 구현 전 확인할 미정 사항

- CLI 구현 언어: shell, Node.js 또는 다른 최소 런타임
- Windows 지원 여부와 심볼릭 링크 fallback
- Claude Code와 Codex의 최신 사용자 지침 및 Skill 탐색 경로
- `CLAUDE.md`에서 공통 원본을 연결하는 방식: import 또는 생성된 파일
- vendor 다운로드와 lock 갱신 방식
- token 추정 도구와 기준
- eval 실행 형식과 assertion 도구
- 프로젝트 템플릿 병합 옵션 제공 여부

이 항목들은 구현 시 현재 공식 문서와 실제 대상 환경을 확인한 뒤 결정한다.

## 17. 구현 순서

1. 저장소 구조와 공통 지침 확정
2. 설치 대상 경로를 공식 문서와 실제 환경에서 확인
3. 안전하고 멱등적인 `install`, `status`, `doctor`, `uninstall` 구현
4. 프로젝트 `init` 구현
5. 기본 테스트와 임시 HOME을 사용하는 설치 검증
6. vendor lock과 규칙 색인 구현
7. `react-performance` adapter 구현
8. `tanstack-query`, `frontend-testing`, `typescript-type-design` 구현
9. routing, selection, near-miss evals 구현
10. token 진단과 업데이트 흐름 구현

## 18. 복원 메모

이 문서는 2026-07-17에 제공된 ChatGPT 대화의 v0.1~v0.4 변경 이력을 바탕으로 복원했다. 원본 v0.4 파일 자체는 작업 환경에 제공되지 않았으므로, 대화에서 확인되지 않은 세부 구현은 임의로 확정하지 않고 미정 사항으로 표시했다.
