﻿function Get-DokuPageVersions {
<#
	.SYNOPSIS
		Returns the available versions of a Wiki page.

	.DESCRIPTION
		Returns the available versions of a Wiki page. The number of pages in the result is controlled via the recent configuration setting. The offset can be used to list earlier versions in the history

	.PARAMETER FullName
		The full page name for which to return the data

	.PARAMETER Offset
		used to list earlier versions in the history

	.EXAMPLE
		PS C:\> $PageVersions = Get-DokuPageVersions -FullName "namespace:namespace:page"

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
				   Position = 2,
				   ValueFromPipeline = $true,
				   ValueFromPipelineByPropertyName = $true,
				   HelpMessage = 'The full page name for which to return the data')]
		[ValidateNotNullOrEmpty()]
		[string[]]$FullName,
		[Parameter(Position = 3,
				   HelpMessage = 'Used to list earlier versions in the history')]
		[ValidateNotNullOrEmpty()]
		[int]$Offset = 0
	)

	begin {

	} # begin

	process {
		foreach ($PageName in $FullName) {
			$APIResponse = Invoke-DokuApiCall -MethodName 'wiki.getPageVersions' -MethodParameters @($PageName,$Offset)
			if ($APIResponse.CompletedSuccessfully -eq $true) {
				$MemberNodes = ($APIResponse.XMLPayloadResponse  | Select-Xml -XPath "//struct").Node
				foreach ($node in $MemberNodes) {
					$PageObject = New-Object PSObject -Property @{
						FullName = $PageName
						User = (($node.member)[0]).value.string
						IpAddress = (($node.member)[1]).value.string
						Type = (($node.member)[2]).value.string
						Summary = (($node.member)[3]).value.string
						Modified = Get-Date -Date ((($node.member)[4]).value.InnerText)
						VersionTimestamp = (($node.member)[5]).value.int
						PageName = ($PageName -split ":")[-1]
						ParentNamespace = ($PageName -split ":")[-2]
						RootNamespace = ($PageName -split ":")[0]
					}
					$PageObject
				}
			} elseif ($null -eq $APIResponse.ExceptionMessage) {
				Write-Error "Fault code: $($APIResponse.FaultCode) - Fault string: $($APIResponse.FaultString)"
			} else {
				Write-Error "Exception: $($APIResponse.ExceptionMessage)"
			}
		} # foreach
	} # process

	end {

	} # end
}