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

# same as tabs 4
Write-host `e[?25l`e[3g`r`eH -NoNewline
for ($i = 0; $i -lt [math]::Floor([System.Console]::BufferWidth / 4); $i++) {
	Write-Host "    `eH" -NoNewline
}
Write-Host `e[?25h`r -NoNewline

# workaround for https://github.com/git-for-windows/git/issues/3177
Set-Item env:\TERM -Value "xterm-256color"

# Import-Module posh-git
