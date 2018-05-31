﻿function Get-DokuPageVersionHtml {
<#
	.SYNOPSIS
		Returns the rendered HTML for a specific version of a Wiki page
	
	.DESCRIPTION
		Returns the rendered HTML for a specific version of a Wiki page
	
	.PARAMETER DokuSession
		The DokuSession (generated by New-DokuSession) from which to get the page data
	
	.PARAMETER FullName
		The full page name for which to return the data
	
	.PARAMETER VersionTimestamp
		The timestamp for which version to get the info from
	
	.PARAMETER Raw
		Return only the raw HTML, rather than an object
	
	.EXAMPLE
		PS C:\> $RawPageHtml = Get-DokuPageVersionHtml -DokuSession $DokuSession -FullName "namespace:namespace:page" -VersionTimestamp 1497464418 -Raw
	
	.OUTPUTS
		System.Management.Automation.PSObject
	
	.NOTES
		AndyDLP - 2018-05-26
#>
	
	[CmdletBinding()]
	[OutputType([psobject])]
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 1,
				   HelpMessage = 'The DokuSession from which to get the page data')]
		[ValidateNotNullOrEmpty()]
		[psobject]$DokuSession,
		[Parameter(Position = 4,
				   HelpMessage = 'Return only the raw HTML, rather than an object')]
		[switch]$Raw,
		[Parameter(Mandatory = $true,
				   Position = 2,
				   HelpMessage = 'The full page name for which to return the data')]
		[ValidateNotNullOrEmpty()]
		[string]$FullName,
		[Parameter(Mandatory = $true,
				   Position = 3,
				   HelpMessage = 'The timestamp for which version to get the info from')]
		[ValidateNotNullOrEmpty()]
		[int]$VersionTimestamp
	)
	
	$payload = (ConvertTo-XmlRpcMethodCall -Name "wiki.getPageHTMLVersion" -Params @($FullName, $VersionTimestamp)) -replace "String", "string"
	$payload = $payload -replace "Int32","i4"
	if ($DokuSession.SessionMethod -eq "HttpBasic") {
		$httpResponse = Invoke-WebRequest -Uri $DokuSession.TargetUri -Method Post -Headers $DokuSession.Headers -Body $payload -ErrorAction Stop
	} else {
		$httpResponse = Invoke-WebRequest -Uri $DokuSession.TargetUri -Method Post -Headers $DokuSession.Headers -Body $payload -ErrorAction Stop -WebSession $DokuSession.WebSession
	}
	
	$PageObject = New-Object PSObject -Property @{
		FullName = $FullName
		RenderedHtml = [string]([xml]$httpResponse.Content | Select-Xml -XPath "//value/string").Node.InnerText
		PageName = ($FullName -split ":")[-1]
		ParentNamespace = ($FullName -split ":")[-2]
		RootNamespace = ($FullName -split ":")[0]
	}
	
	if ($Raw) {
		return $PageObject.RenderedHtml
	} else {
		return $PageObject
	}
}