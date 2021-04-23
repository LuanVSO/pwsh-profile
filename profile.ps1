#region helpers
function Enter-VsDevEnv {
	[CmdletBinding()]
	param(
		[Parameter()]
		[switch]$Prerelease,
		[Parameter()]
		[string]$architecture = "x64"
	)

	$ErrorActionPreference = 'Stop'

	try {
		Import-Module -Name 'VSSetup'
	}
	catch {
		Install-Module -Name 'VSSetup' -SkipPublisherCheck -Force
		Import-Module -Name 'VSSetup'
	}


	Write-Verbose 'Searching for VC++ instances'
	$vsinfo = `
		Get-VSSetupInstance  -All -Prerelease:$Prerelease `
	| Select-VSSetupInstance `
		-Latest -Product * `
		-Require 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64'

	$vspath = $vsinfo.InstallationPath

	switch ($env:PROCESSOR_ARCHITECTURE) {
		"amd64" { $hostarch = "x64" }
		"x86" { $hostarch = "x86" }
		"arm" { $hostarch = "arm" }
		"arm64" { $hostarch = "arm64" }
		default { throw "Unknown architecture: $switch" }
	}

	$devShellModule = "$vspath\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"

	Import-Module -Global -Name $devShellModule

	Write-Verbose 'Setting up environment variables'
	Enter-VsDevShell -VsInstanceId $vsinfo.InstanceId  -SkipAutomaticLocation `
		-devCmdArguments "-arch=$architecture -host_arch=$hostarch"

	Set-Item -Force -path "Env:\Platform" -Value $architecture

	remove-Module Microsoft.VisualStudio.DevShell, VSSetup
}
function la { Get-ChildItem @args | Format-Wide }
function which($c) { (get-command $c).path }
function clear-host { write-host "`e[2J`e[3J`e[0;0H" -NoNewline }
function take([string]$path) { mkdir $path ; Set-Location $path }

#endregion

#region aliases
# set-Alias "ping" "Test-NetConnection"
Set-Alias sudo elevate
# set-Alias "ipconfig" "Get-NetIPConfiguration"
#endregion

#region keybindings
Set-PSReadLineKeyHandler -Key "Ctrl+f" -Function ForwardWord
Set-PSReadLineKeyHandler -Key "Ctrl+RightArrow" -Function ForwardWord
Set-PSReadlineKeyHandler -key "Ctrl+d" -Function DeleteCharOrExit
<#Set-PSReadLineKeyHandler -Key "UpArrow" -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key "DownArrow" -Function HistorySearchForward #>
set-psreadlinekeyhandler -Key "tab" -Function MenuComplete
#endregion

#region psreadline options
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
#endregion

#source completers
. "$(Split-Path $profile -Parent)\completion.ps1"
