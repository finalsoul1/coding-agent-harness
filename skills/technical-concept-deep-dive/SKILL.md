---
name: technical-concept-deep-dive
description: >
  Build a practical mental model for unfamiliar technical concepts,
  libraries, APIs, platform features, protocols, CLI tools, architecture
  concepts, cloud services, security features, and AI/ML terms.
  Trigger even for short questions such as "SBOM?", "KEDA?",
  "GitLab Dependency Scanning?", or "RAG?".
---

# Technical Concept Deep Dive

## Mandatory companion skill

Before composing the final answer, load and apply `/korean-writing`
if it is available in the current environment.

Use:
- this skill for explanation structure and technical depth
- `/korean-writing` for final Korean prose

Do not replace `/korean-writing` with a local "write in Korean" rule
when the skill is available.

---

## Trigger

Use this skill when the user asks about an unfamiliar:

- technical concept or acronym
- library or framework feature
- API or protocol
- CLI or developer tool
- cloud / CI/CD / security feature
- AI/ML concept

Short questions are sufficient triggers.

Examples:

- `GitLab Dependency Scanning?`
- `Opaque?`
- `KEDA?`
- `peerDependenciesMeta?`
- `RAG?`

If the user provides only a technical noun followed by `?`,
do not ask what they want to know.

Assume they want a practical mental model.

---

## Core principle

Use progressive disclosure.

The explanation should work at three depths:

1. 10-second understanding
2. 1-minute mental model
3. deeper technical explanation

The user should understand the core idea without reading the full answer.

---

# Response structure

## 1. 한눈에 보기

Start with 2-4 sentences covering:

- what it is
- why it exists
- where it fits in the system

End with a plain, intuitive summary when useful.

---

## 2. 전체 그림

Show where the concept sits in the surrounding system.

Prefer a simple flow or relationship diagram.

Example:

```text
package-lock.json
      ↓
GitLab Pipeline
      ↓
Dependency Scanning Job
      ↓
Scanner
      ↓
Vulnerability Report
      ↓
Merge Request / Security UI
```

Prioritize relationships over implementation details.

---

## 3. 왜 필요한가

Explain:

```text
기존 문제
→ 기존 해결 방식
→ 한계
→ 이 개념이 해결하는 부분
```

Include historical background only when it materially improves understanding.

---

## 4. 실제 동작 흐름

Follow one concrete event through the system.

Answer:

- what triggers it?
- where does it run?
- who actually executes it?
- what goes in?
- what happens?
- what comes out?
- what happens next?

Prefer runtime flow over abstract description.

---

## 5. 핵심 구성요소

Explain only the abstractions necessary to understand the mental model.

For each important component, clarify:

- responsibility
- relationship to other components
- whether the developer interacts with it directly

Do not start with implementation trivia.

---

## 6. 인접 개념과 비교

Compare the concepts users are most likely to confuse.

Focus on the distinguishing axis rather than giving independent definitions.

Example:

```text
SAST
→ 내가 작성한 코드

Dependency Scanning
→ 외부 dependency

Container Scanning
→ container image

Secret Detection
→ 노출된 credential / secret
```

---

## 7. 실제 프로젝트 예시

Provide one realistic example when useful.

Prefer examples involving:

- frontend applications
- web architecture
- CI/CD
- cloud infrastructure

Connect the abstract concept to files, processes, or runtime behavior
the developer would actually encounter.

---

## 8. 흔한 오해

Call out important misconceptions only when they are likely to occur.

Keep this section short.

---

## 9. 내부 원리

Go deeper when the question concerns implementation or internals.

Prefer:

```text
Public API
→ core abstraction
→ state / data structure
→ runtime flow
→ side effect
→ result
```

For libraries, connect the public API to source-level abstractions when possible.

Do not state version-specific internals as fact without verification.

---

# Type-specific guidance

## Libraries

When the subject is a library or framework, emphasize:

- the problem it abstracts away
- its core abstraction
- what happens after a public API is called
- important state or data structures
- why the API has its current shape

A small conceptual reimplementation may be used when it clarifies the design.

## Platform features

For GitLab, GitHub, AWS, Kubernetes, and similar platforms,
clearly separate:

```text
where it is configured
where it is executed
where data is stored
where results are presented
```

Pay special attention to the actual execution agent.

For example, distinguish:

```text
GitLab
→ orchestrates / stores / presents

GitLab Runner
→ executes the job

Scanner
→ performs the actual analysis
```

## Terminology

If the name itself makes the concept harder to understand,
briefly explain why that term is used.

Do this only when the naming helps build the mental model.

---

# Freshness and verification

For version-sensitive or recently introduced behavior,
verify current official documentation or source code when possible.

Distinguish clearly between:

- general concept
- current product behavior
- implementation detail

---

# Completion criteria

Before finishing, check that:

- the first section is enough to grasp the concept
- the concept's position in the system is visible
- the actual execution flow is clear
- neighboring concepts are distinguishable
- deeper implementation detail appears only after the mental model
