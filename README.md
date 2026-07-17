# coding-agent-harness

Claude Code와 Codex에서 재사용할 수 있는 개인용 코딩 에이전트 환경을 관리하는 저장소입니다.

## 상태

현재는 설계 검토 단계입니다. 상세 요구사항과 단계별 완료 조건은 [SPEC.md](./SPEC.md)를 참고하세요.

Phase 1 구현은 저장소 기본 구성에 대한 피드백을 반영한 뒤 시작합니다.

## 초기 범위

- 공통 개발 지침
- Claude Code와 Codex 설치 연결
- 프로젝트 초기화 템플릿
- 설치, 상태 확인, 진단, 업데이트, 제거 도구
- 직접 관리하는 Skills와 고정된 외부 Skill 원본의 분리

## 지원 환경

Phase 1은 macOS와 일반적인 POSIX shell 환경을 대상으로 합니다. CLI 런타임과 세부 지원 범위는 구현 전에 확정합니다.
