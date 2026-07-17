---
name: typescript-type-design
description: 잘못된 상태를 표현하기 어렵도록 TypeScript 타입 모델을 검토하고 개선한다. 도메인 상태 모델링, discriminated union, 외부 데이터 경계, 위험한 any 또는 타입 단언, generic 입출력 관계, exhaustive handling, optional, undefined, null 의미 구분이 필요한 작업에 사용한다. 타입 설계 문제가 없는 일반적인 TypeScript 수정에는 사용하지 않는다.
---

# TypeScript 타입 설계

의도한 런타임 불변조건을 강제하는 가장 작은 변경으로 타입 모델을 개선한다.

## 작업 순서

1. 설치된 TypeScript 버전, 관련 compiler option, 기존 모델, 공개 API 제약을 확인한다.
2. 현재 모델이 표현하지 못하는 불변조건이나 허용하는 잘못된 상태를 명시한다.
3. 데이터가 생성, parse, narrowing, 소비되는 경계를 찾는다.
4. 불변조건을 강제하는 가장 작은 타입 변경과 런타임 변경을 선택한다.
5. 관련 생성부와 소비부만 수정하고 관계없는 refactoring은 하지 않는다.
6. 가장 좁은 범위의 type check와 test를 실행한다.

## 패턴 선택

- 특정 상태에서만 일부 field가 유효하면 `discriminated union`을 사용한다.
- 모든 union member를 처리해야 하면 exhaustive checking을 사용한다.
- 외부 데이터는 `unknown`으로 받고 신뢰할 수 있는 타입에 할당하기 전에 경계에서 검증하거나 narrowing한다.
- `any`, type assertion, non-null assertion이 실제 불변조건 위반을 숨기면 제거하거나 대체한다.
- 값을 widening하지 않고 검증해야 하면 `satisfies`로 inference를 보존한다.
- generic은 입력, 출력, member 사이의 실제 관계를 표현할 때만 사용한다.
- optional, `undefined`, `null`은 편의가 아니라 도메인 의미에 따라 구분한다.
- 건전한 기존 validation library와 타입 관례가 있으면 재사용한다.

## 제약

- `interface`와 `type` 중 하나를 일괄적으로 선호하지 않는다.
- identity나 validation에 필요하지 않으면 branded type을 도입하지 않는다.
- 직접적인 모델이 더 명확하면 복잡한 type-level programming을 추가하지 않는다.
- 국소적인 문제를 해결하기 위해 저장소 전체 compiler option을 변경하지 않는다.
- 런타임 validation을 compile-time 타입으로 대체하지 않는다.
- 요청에 필요하지 않으면 공개 API나 serialized shape를 변경하지 않는다.
- 영향받는 모든 호출부에 올바른 narrowing 경로가 생기기 전에는 assertion을 제거하지 않는다.

## 결과 보고

잘못된 상태 또는 안전하지 않은 경계, 최소 수정 내용, 호환성 tradeoff, 수행한 검증을 설명한다.
