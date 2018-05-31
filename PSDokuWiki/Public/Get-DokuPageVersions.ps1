﻿function Get-DokuPageVersions {
<#
	.SYNOPSIS
		Returns the available versions of a Wiki page.
	
	.DESCRIPTION
		Returns the available versions of a Wiki page. The number of pages in the result is controlled via the recent configuration setting. The offset can be used to list earlier versions in the history
	
	.PARAMETER DokuSession
		The DokuSession (generated by New-DokuSession) from which to get the page versions
	
	.PARAMETER FullName
		The full page name for which to return the data
	
	.PARAMETER Offset
		used to list earlier versions in the history
	
	.EXAMPLE
		PS C:\> $PageVersions = Get-DokuPageVersions -DokuSession $DokuSession -FullName "namespace:namespace:page"
	
	.OUTPUTS
		System.Management.Automation.PSObject[]
	
	.NOTES
		AndyDLP - 2018-05-26
#>
	
	[CmdletBinding()]
	[OutputType([psobject[]])]
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 1,
				   HelpMessage = 'The DokuSession from which to get the page versions')]
		[ValidateNotNullOrEmpty()]
		[Psobject]$DokuSession,
		[Parameter(Mandatory = $true,
				   Position = 2,
				   HelpMessage = 'The full page name for which to return the data')]
		[ValidateNotNullOrEmpty()]
		[string]$FullName,
		[Parameter(Position = 3,
				   HelpMessage = 'Used to list earlier versions in the history')]
		[ValidateNotNullOrEmpty()]
		[int]$Offset = 0
	)
	
	$payload = (ConvertTo-XmlRpcMethodCall -Name "wiki.getPageVersions" -Params @($FullName, $Offset)) -replace "String", "string"
	$payload = $payload -replace "Int32", "i4"
	if ($DokuSession.SessionMethod -eq "HttpBasic") {
		$httpResponse = Invoke-WebRequest -Uri $DokuSession.TargetUri -Method Post -Headers $DokuSession.Headers -Body $payload -ErrorAction Stop
	} else {
		$httpResponse = Invoke-WebRequest -Uri $DokuSession.TargetUri -Method Post -Headers $DokuSession.Headers -Body $payload -ErrorAction Stop -WebSession $DokuSession.WebSession
	}
	
	$MemberNodes = ([xml]$httpResponse.Content | Select-Xml -XPath "//struct").Node
	foreach ($node in $MemberNodes) {
		$PageObject = New-Object PSObject -Property @{
			FullName = $FullName
			User = (($node.member)[0]).value.string
			IpAddress = (($node.member)[1]).value.string
			Type = (($node.member)[2]).value.string
			Summary = (($node.member)[3]).value.string
			Modified = Get-Date -Date ((($node.member)[4]).value.InnerText)
			VersionTimestamp = (($node.member)[5]).value.int
			PageName = ($FullName -split ":")[-1]
			ParentNamespace = ($FullName -split ":")[-2]
			RootNamespace = ($FullName -split ":")[0]
		}
		[array]$PageVersions = $PageVersions + $PageObject
	}
	return $PageVersions
}