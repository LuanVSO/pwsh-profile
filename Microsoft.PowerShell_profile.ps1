#[Console]::InputEncoding = [Console]::OutputEncoding = $OutputEncoding #= [System.Text.Utf8Encoding]::new()

if ($env:WT_SESSION) {
	function wt_osc99 {
		if ($pwd.provider.name -eq "FileSystem") {
			$p = $pwd.ProviderPath
			Write-host "`e]9;9;`"$p`"`e\" -NoNewline
		}
	}
	$prePrompt_functions += "wt_osc99"
}

# Import-Module posh-git
