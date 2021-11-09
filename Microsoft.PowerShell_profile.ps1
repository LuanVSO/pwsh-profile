﻿#[Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding #= [System.Text.Utf8Encoding]::new()

[system.Collections.generic.list[scriptblock]] $prompt = @(
	{ [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '', Justification = 'false flagging')]
		$global:promptColor = switch ($global:?) {
			$true { "`e[38;5;76m" }
			$false { "`e[38;5;196m" }
		} }
	{ if ($pwd.Provider.Name -eq 'FileSystem') {
			"`e]9;9;`"$($pwd.ProviderPath)`"`e\"
		} }
	{ "`e[0m" }
	{ "PS " }
	{ $pwd.ProviderPath }
	{ "`n" }
	{ "$global:promptColor$('❯'*($NestedPromptLevel +1))`e[0m " }
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
	HistorySavePath               = "C:\Users\luanv\OneDrive\settings\powershell\ConsoleHost_history.txt";
	PredictionSource              = "historyAndPlugin";
	HistorySearchCursorMovesToEnd = $true;
	PredictionViewStyle           = "ListView";
	WordDelimiters                = " ;:,.[]{}()/\|^&*-=+'`"–—―_";
}
Set-PSReadLineOption @PSReadLineOptions
#endregion

#endregion style
$PSStyle.Formatting.TableHeader = $PSStyle.Bold + $PSStyle.Foreground.Yellow
$PSStyle.FileInfo.Directory = $PSStyle.Foreground.Blue
$PSStyle.FileInfo.Extension.Item('.ps1') = $PSStyle.Foreground.BrightYellow
$PSStyle.FileInfo.Extension.Item('.psd1') = $PSStyle.Foreground.BrightYellow
$PSStyle.FileInfo.Extension.Item('.psm1') = $PSStyle.Foreground.BrightYellow
$PSStyle.FileInfo.Extension.Item('.ps1xml') = $PSStyle.Foreground.BrightYellow
$PSStyle.FileInfo.Extension.add('.pdf', $PSStyle.Foreground.BrightWhite + $PSStyle.Background.red)
$PSStyle.Formatting.FormatAccent = $PSStyle.Bold + $PSStyle.Foreground.Yellow
$PSStyle.Progress.MaxWidth = [console]::BufferWidth
if ($env:WT_PROFILE_ID) {
	$PSStyle.Progress.UseOSCIndicator = $true
}
#endregion
# same as tabs 4
& {
	Write-host "`e[?25l`e[3g`r`eH" -NoNewline
	for ($i = 0; $i -lt [System.Console]::BufferWidth; $i += 4) {
		Write-Host "`e[4C`eH" -NoNewline
	}
	Write-Host "`r`e[?25h" -NoNewline
}

# workaround for https://github.com/git-for-windows/git/issues/3177
Set-Item "env:\TERM" -Value "xterm-256color"

if (test-path "~\Source\Repos\powershell-utils") { $env:path += ";$env:USERPROFILE\Source\Repos\powershell-utils" }
