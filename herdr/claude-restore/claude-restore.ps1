# Claude Code SessionStart/SessionEnd hook: records which session each herdr terminal is running.
$ErrorActionPreference = 'Stop'

if (-not $env:HC_TERMINAL_ID -or $env:CLAUDE_CODE_ENTRYPOINT -ne 'cli' -or $env:HERDR_CLAUDE_RESTORE -eq 'off') { exit 0 }

$stateRoot = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } elseif ($env:XDG_STATE_HOME) { $env:XDG_STATE_HOME } else { Join-Path $HOME '.local/state' }
$stateDir = Join-Path $stateRoot 'herdr-claude-restore'
$state = Join-Path $stateDir "$($env:HC_TERMINAL_ID).session"

try {
    $hook = [Console]::In.ReadToEnd() | ConvertFrom-Json
} catch {
    [Console]::Error.WriteLine("claude-restore: could not read the hook input; terminal $($env:HC_TERMINAL_ID) keeps its previous record: $_")
    exit 1
}

switch ($hook.hook_event_name) {
    'SessionStart' {
        $dir = if ($env:CLAUDE_PROJECT_DIR) { $env:CLAUDE_PROJECT_DIR } else { $hook.cwd }
        try {
            New-Item -ItemType Directory -Force -Path $stateDir | Out-Null
            $tmp = "$state.$PID"
            Set-Content -LiteralPath $tmp -Value @($hook.session_id, $dir, $hook.transcript_path) -Encoding UTF8
            Move-Item -LiteralPath $tmp -Destination $state -Force
        } catch {
            [Console]::Error.WriteLine("claude-restore: could not write $state; this session will not reopen after a restart: $_")
            exit 1
        }
    }
    'SessionEnd' {
        # A killed Claude (reboot, logout, closed pane) ends with reason "other", so its record stays for the restore.
        if ($hook.reason -in 'prompt_input_exit', 'logout' -and (Test-Path -LiteralPath $state)) {
            $recorded = Get-Content -LiteralPath $state -TotalCount 1
            if ($recorded -eq $hook.session_id) { Remove-Item -LiteralPath $state }
        }
    }
}
