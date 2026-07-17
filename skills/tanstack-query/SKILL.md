---
name: tanstack-query
description: TanStack Query의 server state, query key, query function, cache policy, mutation, invalidation, optimistic update, prefetch, dependent query, infinite query를 설계하고 진단한다. TanStack Query를 사용하는 data fetching이나 cache 동작을 구현, 수정, review, migration할 때 사용한다. client-only local state나 TanStack Query와 관계없는 요청에는 사용하지 않는다.
---

# TanStack Query

설치된 버전과 프로젝트 관례를 기준으로 server state의 소유권, freshness, 갱신 경계를 명확하게 만든다.

## 작업 순서

1. 설치된 TanStack Query package와 major version, framework adapter, `QueryClient` default, query key factory, API layer를 확인한다.
2. 대상 data가 server state인지, 누가 갱신하는지, 언제 stale해져도 되는지 명시한다.
3. query key와 query function의 입력 관계를 먼저 고정한다.
4. cache 갱신 방식과 mutation 이후 일관성 범위를 선택한다.
5. loading, error, empty, refetch 상태와 동시 요청을 확인한다.
6. 대상 type check와 test를 실행하고 필요한 경우 Devtools나 request log로 cache 동작을 확인한다.

## Query 설계

- query key는 최상위 array로 만들고 해당 data를 유일하게 식별할 수 있는 JSON-serializable 값만 포함한다.
- query function이 사용하는 가변 값은 모두 query key에 포함한다.
- 프로젝트에 query key factory나 `queryOptions` 관례가 있으면 재사용하고 새 추상화를 중복해서 만들지 않는다.
- 여러 위치에서 같은 query를 사용할 때 `queryOptions`로 `queryKey`와 `queryFn`을 함께 재사용한다.
- query function은 성공 data를 반환하고 실패를 throw하며 지원되는 경우 전달받은 cancellation signal을 경계에 연결한다.
- 일반 query와 infinite query가 같은 cache entry를 공유하지 않도록 key를 구분한다.

## Cache 정책

- `staleTime`은 data가 fresh로 간주되는 시간이고 `gcTime`은 inactive cache가 유지되는 시간이라는 차이를 보존한다.
- 기본값을 바꾸기 전에 mount, focus, reconnect에서 stale query가 background refetch될 수 있음을 확인한다.
- 불필요한 refetch는 자동 동작을 모두 끄기보다 data의 실제 freshness에 맞는 `staleTime`으로 조절한다.
- `initialData`, `placeholderData`, prefetch는 서로 다른 생명주기와 cache 의미를 가지므로 화면 깜빡임만 보고 교체하지 않는다.
- dependent query의 `enabled`를 사용하기 전에 독립 요청을 병렬화하거나 상위 경계에서 prefetch할 수 있는지 확인한다.

## Mutation과 Invalidation

- server side effect에는 mutation을 사용하고 영향을 받는 query key 범위를 명시한다.
- mutation 응답이 최신 entity를 충분히 포함하면 `setQueryData`로 정확한 entry를 갱신하는 방식을 검토한다.
- server에서 파생 data가 함께 바뀌면 관련 prefix 또는 정확한 key를 invalidate한다.
- mutation의 pending 상태가 refetch 완료까지 유지되어야 하면 invalidation Promise를 반환하거나 `await`한다.
- 관계없는 cache 전체를 넓게 invalidate하지 않는다.

## Optimistic Update

- 한 화면에서만 임시 결과를 보여주면 mutation `variables`를 사용한 UI update를 우선한다.
- 여러 화면이 같은 optimistic data를 봐야 할 때만 cache 직접 수정을 선택한다.
- cache를 수정할 때는 관련 query를 cancel하고 이전 값을 snapshot한 뒤 immutable하게 갱신한다.
- 실패 시 snapshot으로 rollback하고 완료 후 server state와 일치하도록 필요한 query를 invalidate한다.
- 동시 mutation의 순서, 임시 ID, 중복 반영 가능성을 확인한다.

## 제약

- 설치된 major version과 다른 API나 option 이름을 섞지 않는다.
- 명확한 이점 없이 새 query key library나 cache abstraction을 추가하지 않는다.
- form input, modal 상태 같은 client-only state를 query cache에 넣지 않는다.
- query 결과를 불필요하게 component state로 복사하지 않는다.
- render마다 새 `QueryClient`를 만들지 않는다.
- cache 문제를 숨기기 위해 무조건 refetch하거나 `staleTime: Infinity`를 기본값으로 사용하지 않는다.

## 결과 보고

확인한 version과 기존 관례, query key와 cache 정책, mutation 일관성 범위, 수행한 검증을 설명한다.
