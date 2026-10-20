#!/usr/bin/env python3
# Enforce the korean-writing skill on every Korean output (files, commands,
# MCP writes, user questions, chat replies). CLAUDE.md alone kept getting skipped.
#
# The skill counts as loaded from its invocation until the next compaction.
# Re-invoking per turn would re-inject ~35KB every turn; once loaded it stays in
# context, so a one-line per-turn reminder drives the per-revision re-check instead.
#
# Fails open (no output) on anything unexpected so it never wedges a session.
import json
import os
import re
import sys

HANGUL = re.compile("[%s-%s]" % (chr(0xAC00), chr(0xD7A3)))
SKILL = "korean-writing"
# One-line `node ...` call with the marker at the end. Quoted args may hold Korean, but
# pipes, redirects, and substitutions are refused so the marker cannot carry prose.
SEARCH_INPUT = re.compile(
    r'node(?: +(?:"[^"\n`$]*"|[^\s"|;&<>`$()]+))* +# korean-writing: search-input\s*'
)

READ_ONLY_TOOLS = {
    "Read", "Grep", "Glob", "Skill", "ToolSearch", "WebSearch", "WebFetch",
    "ListAgents", "ListMcpResourcesTool", "ReadMcpResourceTool", "ReadMcpResourceDirTool",
}
MCP_WRITE = re.compile(
    r"(create|update|send|schedule|comment|write|push|edit|batch|reply|add_|upload|fill|type|prompt|rename|assign|change)"
)

LOAD = ("Skill 도구로 korean-writing 을 먼저 호출하고, 그 체크리스트로 한글 문구를 점검한 뒤 "
        "같은 작업을 다시 시도하라. 개발 용어는 우리말로 풀지 않는다.")


def is_skill_call(block):
    if block.get("type") != "tool_use" or block.get("name") != "Skill":
        return False
    s = (block.get("input") or {}).get("skill") or ""
    return s == SKILL or s.endswith(":" + SKILL)


def user_text(entry):
    if entry.get("type") != "user" or entry.get("isMeta"):
        return ""
    content = (entry.get("message") or {}).get("content")
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return "".join(b.get("text") or "" for b in content
                       if isinstance(b, dict) and b.get("type") == "text")
    return ""


def load_entries(path):
    with open(path, encoding="utf-8") as f:
        return f.readlines()


def parsed_reversed(lines, needles):
    # Runs on every tool call over multi-MB transcripts: substring-filter before json.loads.
    for line in reversed(lines):
        if not any(n in line for n in needles):
            continue
        try:
            yield json.loads(line)
        except ValueError:
            pass


def skill_loaded(entries):
    needles = ("compact_boundary", '"Skill"', "<command-name>/" + SKILL)
    for e in parsed_reversed(entries, needles):
        if e.get("type") == "system" and e.get("subtype") == "compact_boundary":
            return False
        content = (e.get("message") or {}).get("content")
        if e.get("type") == "assistant" and isinstance(content, list):
            if any(is_skill_call(b) for b in content if isinstance(b, dict)):
                return True
        if "<command-name>/" + SKILL in user_text(e):
            return True
    return False


def last_turn_reply(entries):
    parts = []
    for e in parsed_reversed(entries, ('"type":"user"', '"type":"assistant"')):
        if user_text(e):
            break
        content = (e.get("message") or {}).get("content")
        if e.get("type") == "assistant" and isinstance(content, list):
            parts.extend(b.get("text") or "" for b in content
                         if isinstance(b, dict) and b.get("type") == "text")
    return "".join(parts)


def emit(obj):
    print(json.dumps(obj, ensure_ascii=False))


def pre_tool_use(data, entries):
    tool = data.get("tool_name") or ""
    if tool in READ_ONLY_TOOLS:
        return
    if tool.startswith("mcp__") and not MCP_WRITE.search(tool.split("__", 2)[-1]):
        return
    # Search keywords passed to a script are input, not prose a reader sees.
    if tool == "Bash" and SEARCH_INPUT.fullmatch((data.get("tool_input") or {}).get("command") or ""):
        return
    text = json.dumps(data.get("tool_input") or {}, ensure_ascii=False)
    if not HANGUL.search(text) or skill_loaded(entries):
        return
    emit({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": "한글이 든 출력인데 korean-writing 스킬이 아직 이 컨텍스트에 없다. " + LOAD,
    }})


def stop(data, entries):
    if data.get("stop_hook_active"):
        return
    if not HANGUL.search(last_turn_reply(entries)) or skill_loaded(entries):
        return
    emit({"decision": "block", "reason": (
        "방금 답변에 한글이 있는데 korean-writing 스킬을 거치지 않았다. Skill 도구로 korean-writing 을 "
        "호출해 그 답변을 점검하라. 고칠 것이 있으면 고친 답변 전체를 다시 쓰고, 없으면 '점검 완료' 한 줄만 쓴다."
    )})


def user_prompt_submit(data, entries):
    if skill_loaded(entries):
        msg = ("[korean-writing] 이번 턴의 한글 출력(답변·주석·문서·명령)도 이미 불러온 korean-writing "
               "체크리스트로 점검한다. 한 줄 수정도 같다. 개발 용어는 그대로 둔다.")
    else:
        msg = "[korean-writing] 이번 턴에 한글을 출력하면 그 전에 Skill 도구로 korean-writing 을 먼저 호출한다."
    emit({"hookSpecificOutput": {"hookEventName": "UserPromptSubmit", "additionalContext": msg}})


def main():
    if os.environ.get("KOREAN_WRITING_GUARD") == "off":
        return
    data = json.load(sys.stdin)
    transcript = data.get("transcript_path")
    if not transcript or not os.path.exists(transcript):
        return
    entries = load_entries(transcript)
    handler = {
        "PreToolUse": pre_tool_use,
        "Stop": stop,
        "UserPromptSubmit": user_prompt_submit,
    }.get(data.get("hook_event_name"))
    if handler:
        handler(data, entries)


try:
    main()
except Exception:
    pass
