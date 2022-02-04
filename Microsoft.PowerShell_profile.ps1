#[Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding #= [System.Text.Utf8Encoding]::new()
#Requires -Version 7.2

[system.Collections.generic.list[scriptblock]] $prompt = @(
	{ [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'false flagging')]
		$global:promptColor = switch ($global:?) {
			$true { "`e[38;5;76m" }
			$false { "`e[38;5;196m" }
		}
		return $null
	 }
	{ "`e[0m" }
	{ if ($pwd.Provider.Name -eq 'FileSystem') {
			"`e]9;9;`"$($pwd.ProviderPath)`"`e\"
		} }
	{ "PS " }
	{ $PSStyle.Bold + $pwd.ProviderPath + $PSStyle.BoldOff }
	{
		if (-not (test-path .\.git)) { return; }
		try {
			$branch = git rev-parse --abbrev-ref HEAD

			if ($branch.Length -eq 0) { return $null }
			if ($branch -eq "HEAD") {
				# we're probably in detached HEAD state, so print the SHA
				$branch = git rev-parse --short HEAD
				if ($null -eq $branch) { throw }
				" $($PSStyle.Foreground.Red)($branch)$($PSStyle.Reset)"
			}
			else {
				# we're on an actual branch, so print it
				" $($PSStyle.Foreground.BrightBlue)($branch)$($PSStyle.Reset)"
			}
		}
		catch {
			# we'll end up here if we're in a newly initiated git repo
			" $($PSStyle.Foreground.Yellow)(no branches yet)$($PSStyle.Reset)"
		}
	}
	{ "`n" }
	{ "$global:promptColor$("❯"*($NestedPromptLevel +1))`e[0m " }
)
function prompt {
	-join $prompt.invoke()
}

#region helpers
function Clear-Host { write-host "`e[2J`e[3J`e[0;0H" -NoNewline }
function new-linkeditem([string[]]$files) {
	foreach ($file in $files) {
		$expanded = Convert-Path $file
		if (test-path $expanded -PathType Leaf) {
			new-item -path ".\$(Split-Path $expanded -Leaf)" -ItemType HardLink -Value $expanded
		}
		else {
			new-item -path ".\$(Split-Path $expanded -Leaf)" -ItemType SymbolicLink -Value $expanded
		}
	}
}
#endregion

#region psreadline options
$Local:PSReadLineOptions = @{
	ContinuationPrompt            = "❯❯";
	PredictionSource              = "historyAndPlugin";
	HistorySearchCursorMovesToEnd = $true;
	PredictionViewStyle           = "ListView";
	WordDelimiters                = " ;:,.[]{}()/\|^&*-=+'`"–—―_";
}
$local:historypath = "$($env:OneDriveConsumer)\settings\powershell\ConsoleHost_history.txt"
if (test-path $local:historypath) {
	Set-PSReadLineOption -HistorySavePath $local:historypath
}
Set-PSReadLineKeyHandler -Chord Ctrl+u -ScriptBlock {
	[Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
	[Microsoft.PowerShell.PSConsoleReadLine]::Insert('winget upgrade --all')
	[Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

#endregion

#endregion style
$PSStyle.Formatting.TableHeader = $PSStyle.Bold + $PSStyle.Foreground.Green
$PSStyle.FileInfo.Directory = $PSStyle.Foreground.Blue
$PSStyle.FileInfo.Extension.Item('.ps1') = $PSStyle.Foreground.BrightYellow
$PSStyle.FileInfo.Extension.Item('.psd1') = $PSStyle.Foreground.BrightYellow
$PSStyle.FileInfo.Extension.Item('.psm1') = $PSStyle.Foreground.BrightYellow
$PSStyle.FileInfo.Extension.Item('.ps1xml') = $PSStyle.Foreground.BrightYellow
$PSStyle.FileInfo.Extension.add('.pdf', $PSStyle.Foreground.BrightWhite + $PSStyle.Background.red)
$PSStyle.Formatting.FormatAccent = $PSStyle.Bold + $PSStyle.Foreground.Green
$PSStyle.Progress.MaxWidth = [console]::BufferWidth
if ($env:WT_PROFILE_ID) {
	$PSStyle.Progress.UseOSCIndicator = $true
}
#endregion

# workaround for https://github.com/git-for-windows/git/issues/3177
Set-Item "env:\TERM" -Value "xterm-256color"

if (test-path "~\Source\Repos\powershell-utils") { $env:path += ";$env:USERPROFILE\Source\Repos\powershell-utils" }

# vs code integration must "enable terminal.integrated.enableShellIntegration"
# and add "-noe" to pwsh profile on settings.json
if ($Env:TERM_PROGRAM -eq "vscode") {
	function Get-LastExitCodeVS {
		if ($? -eq $True) {
			return 0
		}
		return -1
	}
	$prompt.Insert(1,{
		$commandline = (Get-History -Count 1).commandline ?? ""
		$commandline = $commandline.ReplaceLineEndings("<LF>").Replace(";","<CL>")
		# OSC 633 ; A ; <CommandLine> ST
		"`e]633;A;$commandline`a"
	})
	$prompt.Insert(2, {
			# OSC 133 ; D ; <ExitCode> ST
			"`e]133;D;$(Get-LastExitCodeVS)`a"
		})
	$prompt.Insert(3, {
			# start of the prompt
			# OSC 133 ; A ST
			"`e]133;A`a" })
	$prompt.Insert(4, {
			# cwd
			if ($pwd.Provider.Name -eq 'FileSystem') {
				# OSC 1337 ; CurrentDir= ... ST
				"`e]1337;CurrentDir=$($pwd.ProviderPath)`a"
			}
		})
	$prompt.add({
			#commandline started
			"`e]133;B`a"
		})

	$PSReadLineOptions.PredictionViewStyle = "InlineView"

	function Global:PSConsoleHostReadLine {
		$lastRunStatus = $?
		Microsoft.PowerShell.Core\Set-StrictMode -Off
		$tmp = [Microsoft.PowerShell.PSConsoleReadLine]::ReadLine($host.Runspace, $ExecutionContext, $lastRunStatus)
		# Write command executed sequence directly to Console to avoid the new line from Write-Host
		[Console]::Write("`e]133;C`a")
		return $tmp
	}

	[console]::Write("`e]633;P;IsWindows=$($IsWindows)`a")
	Write-Host ($PSStyle.Bold + $PSStyle.Foreground.Green + "Shell integration activated! from profile" + $PSStyle.Reset)
}

Set-PSReadLineOption @PSReadLineOptions
