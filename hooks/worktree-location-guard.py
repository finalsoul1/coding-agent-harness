#!/usr/bin/env python3
"""PreToolUse(Bash) hook: git worktree add 의 경로를 <저장소>/.claude/worktrees/ 아래로 제한한다.

여러 저장소를 담은 부모 디렉터리에서 세션을 띄우면 에이전트가 `../<저장소>-<브랜치>` 처럼
형제 폴더에 워크트리를 만들어, 저장소 목록 사이에 정리되지 않은 워크트리가 쌓였다.
네이티브 EnterWorktree, 서브에이전트 isolation 도 .claude/worktrees/ 를 쓰므로 위치를 하나로 맞춘다.
명령을 거절하면서 올바른 경로를 알려 주면 에이전트가 경로만 바꿔 다시 실행한다.

잡지 못하는 경우: 경로에 셸 변수나 명령 치환이 든 명령(payload 는 확장 전 문자열이다),
Claude 데스크톱 앱·Paseo 처럼 Bash 도구를 거치지 않고 만드는 워크트리, hook 이 없는 Codex.
WORKTREE_LOCATION_GUARD=off 로 끈다.
"""

import json
import os
import shlex
import subprocess
import sys

OPERATOR_CHARS = set("();<>|&")
ADD_VALUE_OPTIONS = {"-b", "-B", "--reason"}


def resolve(base, path):
    return os.path.realpath(os.path.join(base, os.path.expanduser(path)))


def split_segments(command):
    lexer = shlex.shlex(command, posix=True, punctuation_chars=True)
    lexer.whitespace_split = True
    segment = []
    for token in lexer:
        if token and set(token) <= OPERATOR_CHARS:
            if segment:
                yield segment
            segment = []
        else:
            segment.append(token)
    if segment:
        yield segment


def parse_worktree_add(args, cwd):
    i = 0
    while i < len(args) and args[i].startswith("-"):
        if args[i] == "-C" and i + 1 < len(args):
            cwd = resolve(cwd, args[i + 1])
            i += 2
        elif args[i] == "-c":
            i += 2
        else:
            i += 1
    if args[i:i + 2] != ["worktree", "add"]:
        return None
    rest = args[i + 2:]
    j = 0
    while j < len(rest):
        arg = rest[j]
        if arg == "--":
            j += 1
            break
        if not arg.startswith("-"):
            break
        j += 2 if arg in ADD_VALUE_OPTIONS else 1
    if j >= len(rest):
        return None
    return cwd, rest[j]


def find_worktree_add(command, cwd):
    for segment in split_segments(command):
        while segment and "=" in segment[0] and not segment[0].startswith("-"):
            segment = segment[1:]
        if not segment:
            continue
        if segment[0] == "cd" and len(segment) > 1:
            cwd = resolve(cwd, segment[1])
        elif segment[0] == "git":
            found = parse_worktree_add(segment[1:], cwd)
            if found:
                return found
    return None


def main_checkout(cwd):
    try:
        out = subprocess.run(
            ["git", "-C", cwd, "rev-parse", "--path-format=absolute", "--git-common-dir"],
            capture_output=True, text=True, timeout=5,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    common = out.stdout.strip()
    if out.returncode != 0 or os.path.basename(common) != ".git":
        return None
    return os.path.realpath(os.path.dirname(common))


def main():
    if os.environ.get("WORKTREE_LOCATION_GUARD") == "off":
        return
    try:
        payload = json.load(sys.stdin)
    except ValueError:
        return
    if payload.get("tool_name") != "Bash":
        return
    command = (payload.get("tool_input") or {}).get("command") or ""
    if "worktree" not in command:
        return
    try:
        found = find_worktree_add(command, payload.get("cwd") or os.getcwd())
    except ValueError:
        return
    if not found:
        return
    git_cwd, path = found
    if "$" in path or "`" in path:
        return
    repo = main_checkout(git_cwd)
    if not repo:
        return
    allowed = os.path.join(repo, ".claude", "worktrees")
    target = resolve(git_cwd, path)
    if target.startswith(allowed + os.sep):
        return
    suggested = os.path.join(allowed, os.path.basename(target))
    reason = (
        f"워크트리는 저장소 안 {allowed}/ 아래에 만든다. 요청한 경로 {target} 는 그 밖이다. "
        f"경로만 {suggested} 처럼 바꿔 같은 명령을 다시 실행한다."
    )
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason,
        }
    }, ensure_ascii=False))


if __name__ == "__main__":
    main()
