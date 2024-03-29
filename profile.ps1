#source completers
Get-ChildItem "$(Split-Path $profile -Parent)\completions\" |
ForEach-Object {
	. $_.FullName
}

function import-OrInstallModule([string[]]$module) {
	Import-Module -Global $module -ErrorAction SilentlyContinue ||
	Install-Module -Name $module -Scope CurrentUser -SkipPublisherCheck -Force &&
	Import-Module -Global $module
}

import-OrInstallModule 'CompletionPredictor'

if (Test-Path "~\.vcpkg\") {
	. "~\.vcpkg\vcpkg-init.ps1"
	Import-Module "~\.vcpkg\scripts\posh-vcpkg\"
}

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

	import-OrInstallModule 'VSSetup'

	Write-Verbose 'Searching for VC++ instances'
	$VSInfo = `
		Get-VSSetupInstance  -All -Prerelease:$Prerelease `
	| Select-VSSetupInstance `
		-Latest -Product * `
		-Require 'Microsoft.VisualStudio.VC.Ide.Core'

	$VSPath = $VSInfo.InstallationPath

	switch ($env:PROCESSOR_ARCHITECTURE) {
		"amd64" { $hostarch = "x64" }
		"x86" { $hostarch = "x86" }
		"arm64" { $hostarch = "arm64" }
		default { throw "Unknown architecture: $switch" }
	}

	$devShellModule = "$VSPath\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"

	Import-Module -Global -Name $devShellModule

	Write-Verbose 'Setting up environment variables'
	Enter-VsDevShell -VsInstanceId $VSInfo.InstanceId  -SkipAutomaticLocation `
		-devCmdArguments "-arch=$architecture -host_arch=$hostarch"

	Set-Item -Force -path "Env:\Platform" -Value $architecture

	remove-Module Microsoft.VisualStudio.DevShell, VSSetup
}
function la { Get-ChildItem @args | Format-Wide }
function which($c) {
 $a = get-command $c
	switch ($a.CommandType) {
		'Alias' { $a.Definition }
		'Application' { $a.Path }
		'ExternalScript' { $a.Source }
		Default { $a }
	}
}
function take([string]$path) { mkdir $path ; Set-Location $path }

function reset { [Console]::write("`ec`e]104`a`e[!p`e[?3;4l`e[4l`e>`e[?69l") }

function tabs($tabsize) {
	[console]::Write("`e[?25l`e[3g`r`eH")
	for ($i = 0; $i -lt [System.Console]::BufferWidth; $i += $tabsize) {
		[console]::Write("`e[${tabsize}C`eH")
	}
	[Console]::write("`r`e[?25h")
}

function Search-Alias([String] $name) {
	(get-Alias).DisplayName | Select-String $name
}
#endregion

#region aliases
set-Alias sral search-Alias
Set-Alias grep Select-String
Set-Alias sudo elevate
set-Alias vim "C:\Program Files\Git\usr\bin\vim.exe"
# set-Alias "ping" "Test-NetConnection"
# set-Alias "ipconfig" "Get-NetIPConfiguration"
#endregion

#region keybindings
Set-PSReadLineKeyHandler -Key "Ctrl+f" -Function ForwardWord
Set-PSReadLineKeyHandler -Key "Ctrl+RightArrow" -Function ForwardWord
Set-PSReadLineKeyHandler -key "Ctrl+d" -Function DeleteCharOrExit
<#Set-PSReadLineKeyHandler -Key "UpArrow" -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key "DownArrow" -Function HistorySearchForward #>
set-PSReadLineKeyHandler -Key "tab" -Function MenuComplete
#endregion
