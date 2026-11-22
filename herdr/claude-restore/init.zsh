# Reopens the Claude Code session a herdr terminal was running before a restart.
if [[ -o interactive && -n $HC_TERMINAL_ID && -z $CLAUDECODE && $HERDR_CLAUDE_RESTORE != off ]]; then
  _herdr_claude_restore() {
    add-zsh-hook -d precmd _herdr_claude_restore
    local state=${XDG_STATE_HOME:-$HOME/.local/state}/herdr-claude-restore/$HC_TERMINAL_ID.session
    [[ -f $state ]] || return 0
    local -a record=("${(@f)$(<$state)}")
    local session=$record[1] dir=$record[2] transcript=$record[3]
    rm -f $state
    if (( ! $+commands[claude] )); then
      print -u2 "claude-restore: claude is not on PATH; session $session was not reopened"
      return 1
    fi
    print "claude-restore: reopening session $session (ctrl+c to skip)"
    # Every pane restores at once after a reboot; spread the starts out.
    sleep $(( $$ % 150 / 10.0 )) || return 130
    if [[ -n $dir ]] && ! cd -- $dir; then
      print -u2 "claude-restore: folder $dir is gone; starting from $PWD"
    fi
    if [[ -n $transcript && -s $transcript ]]; then
      claude --resume $session
    else
      claude
    fi
  }
  autoload -Uz add-zsh-hook && add-zsh-hook precmd _herdr_claude_restore
fi
