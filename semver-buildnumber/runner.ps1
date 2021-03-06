function Update-BuildNumber {
	param(
		[Parameter(ValueFromPipeline=$true)]
		[String]$BuildNumber
	)
	Write-Verbose $("Starting: '{0}'" -f $MyInvocation.MyCommand)
	Write-Debug $("Build Number: {0}" -f $BuildNumber)
	
	Write-Host "##teamcity[buildNumber '$BuildNumber']"
}

function Get-NuSpecVersion {
	[CmdletBinding()]
	param()
	
	Write-Verbose $("Starting: '{0}'" -f $MyInvocation.MyCommand)
	Write-Debug $("NuSpec File: {0}" -f $mr.NuSpecFilePath)
	
	$nuspec_file = $(Get-Content $mr.NuSpecFilePath -ErrorAction:SilentlyContinue) -as [Xml]
	if($nuspec_file)
	{
		$version = $nuspec_file.package.metadata.version -as [System.Version]
		if($version) {
			return $version
		} else {
			Write-Error "The NuSpec file contains no valid version information"
		}		
	} else {
		Write-Error $("NuSpec file path invalid or it wasn't a valid nuspec file.")
	}
}

function Get-BuildMetaData {
	Write-Verbose $("Starting: '{0}'" -f $MyInvocation.MyCommand)
	Write-Debug $("Revision Type: {0}" -f $mr.RevisionType)
	Write-Debug $("Build Counter: {0}" -f $mr.BuildCounter)
	
	switch ($mr.RevisionType) {
		"SHA" {
			Write-Debug $("VCS Build Number: {0}" -f $mr.BuildVCSNumber)
			$short_hash = $mr.BuildVCSNumber.SubString(0,7)
			Write-Debug $("ShortHash: {0}" -f $short_hash)
		
			return $("{0}.{1}" -f $mr.BuildCounter, $short_hash)
		}
		"STD" {
			Write-Debug $("VCS Build Number: {0}" -f $mr.BuildVCSNumber)
			return $("{0}.{1}" -f $mr.BuildCounter, $mr.BuildVCSNumber)
		}
		default {return $mr.BuildCounter} #same as n/a
	}
	
}

function Invoke-Exit {
	param(
		[Int]$ExitCode
	)
	
	[System.Environment]::Exit($ExitCode)
}

function Get-SemVer {
	[CmdletBinding()]
	param()
	
	Write-Verbose $("Starting: '{0}'" -f $MyInvocation.MyCommand)
	
	$version = $mr.ManualVersion
	
	if($mr.NuSpecFilePath -and [String]::IsNullOrWhiteSpace($version)) {
		$version = Get-NuSpecVersion -ea:Stop		
	}
	
	if([String]::IsNullOrWhiteSpace($version)) {
		Write-Error "SemVer creation failed. Found no valid version."
		return
	}
	
	Write-Debug $("Version: {0}" -f $version)
	
	$mr.IgnoreBuildMetaData = [Bool]::Parse($mr.IgnoreBuildMetaData)
	Write-Debug $("Ignore MetaData: {0}" -f $mr.IgnoreBuildMetaData)
	
	if($mr.IgnoreBuildMetaData) {
		return $version
	}
	
	$build_metadata = Get-BuildMetaData	
	Write-Debug $("Build MetaData: {0}" -f $build_metadata)
	
	return $("{0}+{1}" -f $version, $build_metadata) 
}

function Set-PSConsole {
  try {
        $max = $host.UI.RawUI.MaxPhysicalWindowSize
        if($max) {
        $host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(9999,9999)
        $host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size($max.Width,$max.Height)
    }
    } catch {}
}

$mr = @{
	NuSpecFilePath = "%mr.SemVer.NuSpecFilePath%"
	BuildCounter = "%build.counter%"
	BuildVCSNumber = "%build.vcs.number%"
	ManualVersion = "%mr.SemVer.ManualVersion%"
	RevisionType = "%mr.SemVer.RevisionType%"
	IgnoreBuildMetaData = "%mr.SemVer.IgnoreMetaData%"
}

$VerbosePreference = "%mr.SemVer.Verbose%"
$DebugPreference = "%mr.SemVer.Debug%"

if ($env:TEAMCITY_VERSION) {
    Set-PSConsole
}

try {
	#Get-SemVer -ea:Stop | Update-BuildNumber
} catch {
	Write-Error $_
	Invoke-Exit 1
}