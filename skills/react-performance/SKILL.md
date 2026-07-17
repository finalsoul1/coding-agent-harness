---
name: react-performance
description: React와 Next.js의 waterfall, bundle size, server rendering, client data fetching, 불필요한 re-render, hydration, 긴 list, JavaScript hot path를 측정 근거로 진단하고 최소 변경으로 개선한다. 성능 저하를 조사하거나 performance review, Core Web Vitals 개선, render 횟수·bundle·요청 흐름 최적화를 명시적으로 요청할 때 사용한다. 일반 기능 구현이나 측정 가능한 성능 문제가 없는 단순 refactor에는 사용하지 않는다.
---

# React 성능

측정된 병목과 프로젝트의 React·Next.js 버전을 기준으로 영향이 큰 문제부터 수정한다. 모든 규칙을 기계적으로 적용하지 않는다.

## 작업 순서

1. 설치된 React와 Next.js 버전, router와 rendering 방식, 기존 성능 도구와 프로젝트 관례를 확인한다.
2. 사용자 증상과 성능 목표를 확인하고 요청 waterfall, bundle 분석, React Profiler, browser trace, Web Vitals 등 재현 가능한 근거를 찾는다.
3. 병목 범주를 정한 뒤 아래 표에서 관련 prefix만 선택한다.
4. 이 `SKILL.md`의 실제 경로를 resolve하고 두 단계 상위에서 저장소 root를 찾는다. 선택한 prefix와 일치하는 `<repo>/vendor/vercel-react-best-practices/rules/*.md`만 읽는다.
5. 영향도와 근거가 명확한 최소 변경을 적용한다.
6. 같은 측정 방법으로 전후 결과를 비교하고 기능 회귀를 확인한다.

## 규칙 선택

| 관찰한 문제 | 읽을 규칙 |
| --- | --- |
| 순차 요청, 늦은 `await`, 느린 route | `async-*` |
| 큰 client bundle, 무거운 import나 third-party | `bundle-*` |
| RSC, SSR, Server Action, serialization, server cache | `server-*` |
| client request 중복, 전역 listener, browser storage | `client-*` |
| 불필요한 render, Effect와 state 구독 | `rerender-*` |
| hydration, 긴 list, SVG, resource hint | `rendering-*` |
| 측정된 JavaScript hot path | `js-*` |
| 위 범주로 해결되지 않는 event/ref pattern | `advanced-*` |

여러 범주가 겹치면 `async`, `bundle`, `server`, `client`, `rerender`, `rendering`, `js`, `advanced` 순서로 영향이 큰 후보부터 확인한다. `_sections.md`, `_template.md`, vendor의 전체 `SKILL.md`는 개별 규칙을 찾는 데 필요할 때만 읽는다.

## 판단 기준

- profiler나 trace 없이 모든 component에 `memo`, `useMemo`, `useCallback`을 추가하지 않는다.
- 독립 요청은 병렬 실행을 검토하고, 실제로 필요해지는 branch까지 `await`를 미룬다.
- bundle 문제는 분석 결과와 import 경계를 확인한 뒤 direct import, dynamic import, 지연 로딩을 선택한다.
- Server Component와 Client Component 경계를 바꾸기 전에 serialization, cache scope, request isolation을 확인한다.
- derived value를 Effect로 state에 복사하지 않고 render 중 계산할 수 있는지 먼저 본다.
- React Compiler 사용 여부와 framework 지원 범위를 확인하고 수동 memoization과의 관계를 판단한다.
- 낮은 수준의 JavaScript 최적화는 hot path가 확인된 경우에만 적용한다.
- upstream 예시는 현재 프로젝트 버전과 다를 수 있으므로 API 지원 여부를 실제 dependency와 공식 문서에서 확인한다.

## 결과 보고

재현한 증상과 측정 기준, 선택한 규칙, 병목 원인, 적용한 최소 변경, 전후 결과와 남은 불확실성을 설명한다. 측정할 수 없었다면 최적화 효과를 단정하지 않는다.
