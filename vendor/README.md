# Vendor sources

이 디렉터리는 Skill이 참조하는 외부 원본을 재현 가능한 revision으로 보관한다. 설치 대상이 아니며 `OPERATIONS.md`의 convention 기반 발견은 최상위 `skills/`만 처리한다.

`vercel-react-best-practices`는 Vercel의 `vercel-labs/agent-skills` 중 `skills/react-best-practices`에서 가져왔다. upstream `SKILL.md`가 MIT license를 선언한다. 정확한 source, path, revision은 `lock.json`에 기록한다.

보관한 파일은 revision과 비교할 수 있도록 원문을 수정하지 않는다. 이 때문에 upstream의 Markdown hard break를 포함한 공백은 `.gitattributes`에서 vendor 경로의 whitespace 검사를 제외해 보존한다.

생성된 전체 문서인 upstream `AGENTS.md`는 개별 `rules/`와 내용이 중복되어 포함하지 않는다. 갱신할 때는 현재 변경사항을 덮어쓰지 말고 새 revision의 diff와 license를 먼저 확인한 뒤 사용자 승인을 받는다.
