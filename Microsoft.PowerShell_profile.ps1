#[Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding #= [System.Text.Utf8Encoding]::new()

if ($env:WT_SESSION) {
	function prompt {
		$p = $pwd.ProviderPath
		if ($pwd.provider.name -eq "FileSystem") {
			Write-host "`e]9;9;`"$p`"`e\" -NoNewline
		}
		"`e[0mPS $($p)$('>' * ($nestedPromptLevel + 1)) ";
		# .Link
		# https://go.microsoft.com/fwlink/?LinkID=225750
		# .ExternalHelp System.Management.Automation.dll-help.xml
	}
}

# Import-Module posh-git
