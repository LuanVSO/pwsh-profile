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
	{
		$path = if ($pwd.Provider.Name -eq "FileSystem") {
			try {
				$PSStyle.FormatHyperlink($pwd.ProviderPath, "file://localhost/$($pwd.ProviderPath)")
			}
			catch {
				$pwd.ProviderPath
			}
		}
		else {
			$pwd.Path
		}
		$PSStyle.FileInfo.Directory + $PSStyle.Bold + $path + $PSStyle.Reset + ' '
	}
	{
		if (-not (test-path .\.git)) { return; }
		try {
			$branch = git rev-parse --abbrev-ref HEAD

			if ($branch.Length -eq 0) { return $null }
			if ($branch -eq "HEAD") {
				# we're probably in detached HEAD state, so print the SHA
				$branch = git rev-parse --short HEAD
				if ($null -eq $branch) { throw }
				"$($PSStyle.Foreground.Red)($branch)$($PSStyle.Reset)"
			}
			else {
				# we're on an actual branch, so print it
				"$($PSStyle.Foreground.BrightBlue)($branch)$($PSStyle.Reset)"
			}
		}
		catch {
			# we'll end up here if we're in a newly initiated git repo
			"$($PSStyle.Foreground.Yellow)(no branches yet)$($PSStyle.Reset)"
		}
	}
	{ "`n" }
	{ "$global:promptColor$("❯"*($NestedPromptLevel +1))`e[0m " }
)
function prompt {
	-join $prompt.invoke()
}

#region helpers
function Clear-Host { [console]::write("`e[0m`e[2J`e[3J`e[0;0H") }
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
	HistorySearchCursorMovesToEnd = $true;
	WordDelimiters                = " ;:,.[]{}()/\|^&*-=+'`"–—―_";
}
if ((get-module psreadline).Version -gt 2.2) {
	$PSReadLineOptions.PredictionSource = "HistoryAndPlugin"
	if ($Env:TERM_PROGRAM -ne "vscode") { $PSReadLineOptions.PredictionViewStyle = "ListView" }
	else { $PSReadLineOptions.PredictionViewStyle = "inline" }
}
else { $PSReadLineOptions.PredictionSource = "History" }

$local:historypath = "$($env:OneDriveConsumer ?? "~\OneDrive\")\settings\powershell\ConsoleHost_history.txt"
if (test-path $local:historypath) {
	$Local:PSReadLineOptions.HistorySavePath = $local:historypath
}
Set-PSReadLineOption @PSReadLineOptions
Set-PSReadLineKeyHandler -Chord Ctrl+u -ScriptBlock {
	[Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
	[Microsoft.PowerShell.PSConsoleReadLine]::Insert('winget upgrade --all')
	[Microsoft.PowerShell.PSConsoleReadLine]::AcceptLine()
}

. "$(Split-Path $profile -Parent)\PSReadLineProfile.ps1"

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
$PSStyle.Progress.UseOSCIndicator = $true

#endregion

# workaround for https://github.com/git-for-windows/git/issues/3177
Set-Item "env:\TERM" -Value "xterm-256color"

if (test-path "~\Source\Repos\powershell-utils") {
	if ($env:path[$env:path.Length - 1] -ne ';') {
		$env:path += ';'
	}
	$env:path += "$env:USERPROFILE\Source\Repos\powershell-utils;"
}
