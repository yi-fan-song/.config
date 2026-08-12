#!/usr/bin/env bash
# Timestamps each prompt/response.
# - Appends a line to ~/.claude/timestamps.log (persistent per-session record)
# - Emits a JSON `systemMessage` so a stamp appears inline in the Claude Code UI
input=$(cat)

event=$(printf '%s' "$input" | jq -r '.hook_event_name // "?"')
session=$(printf '%s' "$input" | jq -r '.session_id // "?"')
session="${session:0:8}"
cwd=$(printf '%s' "$input" | jq -r '.cwd // ""')

cwd_short="${cwd/#$HOME\/repo\//}"
cwd_short="${cwd_short/#$HOME\/repo/repo}"
cwd_short="${cwd_short/#$HOME/~}"

ts_log=$(date '+%Y-%m-%d %H:%M:%S')
ts_ui=$(date '+%H:%M:%S')

case "$event" in
  UserPromptSubmit) label="▶ prompt  "; ui="⏱ prompt   $ts_ui" ;;
  Stop)             label="■ response"; ui="⏱ response $ts_ui" ;;
  *)                label="$event";     ui="⏱ $event $ts_ui" ;;
esac

printf '%s  %s  [%s] %s\n' "$ts_log" "$label" "$session" "$cwd_short" \
  >> "$HOME/.claude/timestamps.log"

jq -nc --arg msg "$ui" '{systemMessage: $msg}'
exit 0
