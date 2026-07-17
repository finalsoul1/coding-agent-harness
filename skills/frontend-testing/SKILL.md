---
name: frontend-testing
description: 프런트엔드 변경에 필요한 최소 테스트 수준을 선택하고 Testing Library 또는 Playwright 테스트를 사용자 관점에서 작성, 수정, 진단한다. 사용자가 테스트를 요청하거나 관찰 가능한 동작이 바뀌거나 회귀 또는 flaky test를 다룰 때 사용한다. 구현 세부사항만 바뀌고 동작 위험이 없는 일반 수정에는 사용하지 않는다.
---

# 프런트엔드 테스트

변경 위험을 다루는 가장 낮은 수준의 테스트를 선택하고 사용자가 관찰하는 동작을 검증한다.

## 작업 순서

1. package manager, 설치된 test runner와 library 버전, config, 기존 test 명령과 관례를 확인한다.
2. 변경된 사용자 동작, 회귀 위험, 실패 조건을 한 문장으로 명시한다.
3. 가장 좁은 테스트 수준을 선택한다.
   - 순수 로직은 기존 unit test 관례를 따른다.
   - component의 DOM 출력과 상호작용은 Testing Library를 우선한다.
   - navigation, 여러 화면의 통합, 실제 browser 경계는 Playwright를 사용한다.
4. 기존 helper, fixture, render 함수, test data를 먼저 재사용한다.
5. 한 test에서 하나의 의미 있는 사용자 흐름을 검증한다.
6. 대상 test를 먼저 실행하고 필요할 때만 관련 범위로 넓힌다.

## Testing Library

- `screen`과 `getByRole`의 accessible name을 우선하고 form control에는 label query를 사용한다.
- `data-testid`는 사용자 관점 query로 안정적으로 식별할 수 없고 명시적인 test contract가 필요할 때만 사용한다.
- 사용자 상호작용에는 `user-event`를 우선하고 저수준 event 자체가 대상일 때만 `fireEvent`를 사용한다.
- 현재 존재해야 하면 `getBy*`, 비동기로 나타나면 `findBy*`, 부재를 확인하면 `queryBy*`를 선택한다.
- `waitFor`에는 재시도할 assertion을 넣고 callback 안에서 부작용을 만들지 않는다.
- component 내부 state, 함수 호출 순서, CSS class보다 화면에 보이는 결과와 접근 가능한 상태를 검증한다.

## Playwright

- `getByRole`, `getByLabel`, `getByText` 같은 사용자 관점 locator를 우선한다.
- 긴 CSS, XPath, DOM 순서, 무분별한 `first`, `last`, `nth`에 의존하지 않는다.
- locator action과 auto-retrying web-first assertion을 `await`한다.
- `waitForTimeout`이나 고정 sleep 대신 locator의 auto-waiting과 기대 상태를 사용한다.
- 각 test가 독립적인 browser context와 통제된 data를 사용하게 하고 실행 순서나 이전 test 상태에 의존하지 않는다.
- 외부 서비스는 직접 검증하지 말고 필요한 경계에서 통제 가능한 응답을 사용한다.

## Flaky Test 진단

1. 실패를 대상 test에서 반복 실행해 재현 조건을 좁힌다.
2. trace, error log, DOM 상태로 누락된 `await`, 불안정한 locator, 공유 상태, 변동 data, network 경계를 확인한다.
3. 원인을 고친 뒤 반복 실행과 관련 test로 확인한다.

원인 없이 timeout이나 retry 횟수만 늘리지 않는다.

## 제약

- 명확한 이점과 사용자 동의 없이 새 test framework나 의존성을 추가하지 않는다.
- 변경과 관계없는 test를 함께 다시 작성하지 않는다.
- 넓은 DOM snapshot을 기본 검증으로 사용하지 않는다.
- test를 맞추기 위해 제품 동작을 바꾸지 않는다. 필요한 경우 accessibility나 안정적인 test contract 개선을 별도 변경으로 설명한다.
- 모든 구현 세부사항을 검증하지 말고 중요한 동작과 실패 경로에 집중한다.

## 결과 보고

선택한 테스트 수준, 검증한 사용자 동작, 실행한 명령과 결과, 남은 검증 공백을 설명한다.
