#!/bin/sh
# Claude Code SessionStart/SessionEnd hook: records which session each herdr terminal is running.
set -u

[ -n "${HC_TERMINAL_ID:-}" ] || exit 0
[ "${CLAUDE_CODE_ENTRYPOINT:-}" = cli ] || exit 0
[ "${HERDR_CLAUDE_RESTORE:-}" != off ] || exit 0

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/herdr-claude-restore"
state="$state_dir/$HC_TERMINAL_ID.session"

if ! fields=$(jq -r '.hook_event_name, (.reason // ""), .session_id, (.transcript_path // ""), (.cwd // "")'); then
	echo "claude-restore: could not read the hook input; terminal $HC_TERMINAL_ID keeps its previous record" >&2
	exit 1
fi
{
	IFS= read -r event
	IFS= read -r reason
	IFS= read -r session
	IFS= read -r transcript
	IFS= read -r cwd
} <<EOF
$fields
EOF

case "$event" in
SessionStart)
	mkdir -p "$state_dir" || exit 1
	printf '%s\n' "$session" "${CLAUDE_PROJECT_DIR:-$cwd}" "$transcript" >"$state.$$" && mv "$state.$$" "$state" || {
		echo "claude-restore: could not write $state; this session will not reopen after a restart" >&2
		exit 1
	}
	;;
SessionEnd)
	# A killed Claude (reboot, logout, closed pane) ends with reason "other", so its record stays for the restore.
	case "$reason" in
	prompt_input_exit | logout)
		[ -f "$state" ] || exit 0
		IFS= read -r recorded <"$state"
		[ "$recorded" != "$session" ] || rm -f "$state"
		;;
	esac
	;;
esac
