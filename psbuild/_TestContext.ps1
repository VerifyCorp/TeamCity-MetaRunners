$sut = $PSItem.Name -replace ".Tests.", "."
. "$(Join-Path $PSScriptRoot $sut)"

function Scenario {
	param(
		[String]$Scenario,
		[ScriptBlock]$Action
	)
	
	Describe $('=== {0} ===' -f $Scenario) {
		& $Action
	}
}

function Given {
	param(
		[String]$Given,
		[ScriptBlock]$Action,
		[String]$WorkingDirectory = $TestDrive,
		[ScriptBlock]$Before = {}
	)

	Context $("given {0}" -f $Given) {
		In $WorkingDirectory {						
			& $Before
			& $Action			
		}
	}
}

function Then {
	param(
		[String]$Then,
		[ScriptBlock]$Action,
		[ScriptBlock]$After = {},
		[ScriptBlock]$When = {When}
	)	
	
	It $('then {0}' -f $Then) {
		& $When
		& $Action
	}
	& $After
}

function And {
	param(
		[String]$And,
		[ScriptBlock]$Action,
		[ScriptBlock]$After = {},
		[ScriptBlock]$Before = {},
		[ScriptBlock]$When = {When},
		[Switch]$Then
	)
	& $Before
	$message = $("and {0}" -f $And)	
	
	if($Then) {
		
		It $message {
			& $When
			& $Action
		}
	} else {
		$margin = " " * $pester.results.TestDepth
		Write-Host -ForegroundColor:Yellow "$($margin)$message"
		& $Action
		& $After
		Reset-MockCallHistory
	}
	
	

}

function Or {
	param(
		[String]$Or,
		[ScriptBlock]$Action,
		[ScriptBlock]$After = {},
		[ScriptBlock]$Before = {}
	)
	& $Before
	$message = $("or {0}" -f $Or)
	$margin = " " * $pester.results.TestDepth
	Write-Host -ForegroundColor:Yellow "$($margin)$message" 
	
	& $Action
	& $After
	Reset-MockCallHistory
}

function Reset-MockCallHistory {
	$global:mockCallHistory = @()
}

function When {}






