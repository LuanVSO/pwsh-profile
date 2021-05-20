#[Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding #= [System.Text.Utf8Encoding]::new()

if ($env:WT_SESSION) {
	<# 	function prompt {
		$s = $Global:?
		$p = $pwd.ProviderPath
		if ($pwd.provider.name -eq "FileSystem") {
			Write-host "`e]9;9;`"$p`"`e\" -NoNewline
		}
		"`e[0mPS $p$(switch ($s) {
			$true {"`e[38;5;76m" }
			$false {"`e[38;5;196m"}
		})`n$('❯' * ($nestedPromptLevel + 1))`e[0m ";
	} #>
	Import-Module oh-my-posh
	Set-PoshPrompt -Theme C:\Users\luanv\Documents\PowerShell\profile.omp.json
}

#region helpers
function Clear-Host { write-host "`e[2J`e[3J`e[0;0H" -NoNewline }
#endregion

#region psreadline options
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -HistorySearchCursorMovesToEnd
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

