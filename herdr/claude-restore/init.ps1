# Reopens the Claude Code session a herdr terminal was running before a restart. Dot-source it last in $PROFILE.
& {
    if (-not $env:HC_TERMINAL_ID -or $env:CLAUDECODE -or $env:HERDR_CLAUDE_RESTORE -eq 'off') { return }

    $stateRoot = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } elseif ($env:XDG_STATE_HOME) { $env:XDG_STATE_HOME } else { Join-Path $HOME '.local/state' }
    $state = Join-Path $stateRoot "herdr-claude-restore/$($env:HC_TERMINAL_ID).session"
    if (-not (Test-Path -LiteralPath $state)) { return }

    $session, $dir, $transcript = Get-Content -LiteralPath $state -TotalCount 3
    Remove-Item -LiteralPath $state
    if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
        Write-Warning "claude-restore: claude is not on PATH; session $session was not reopened"
        return
    }
    Write-Host "claude-restore: reopening session $session (ctrl+c to skip)"
    # Every pane restores at once after a reboot; spread the starts out.
    Start-Sleep -Milliseconds (($PID % 150) * 100)
    if ($dir) {
        if (Test-Path -LiteralPath $dir) { Set-Location -LiteralPath $dir }
        else { Write-Warning "claude-restore: folder $dir is gone; starting from $PWD" }
    }
    if ($transcript -and (Test-Path -LiteralPath $transcript) -and (Get-Item -LiteralPath $transcript).Length -gt 0) {
        claude --resume $session
    } else {
        claude
    }
}
