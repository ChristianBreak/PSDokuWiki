﻿function New-DokuAttachment {
<#
	.SYNOPSIS
		Uploads a file as an attachment

	.DESCRIPTION
		Uploads a file as an attachment

	.PARAMETER FullName
		The FullName of the to-be-uploaded file, including namespace(s)

	.PARAMETER Path
		The file path of the attachment to upload

	.PARAMETER Force
		Force upload of attachment, overwriting any existing files with the same name

	.EXAMPLE
		PS C:\> New-DokuAttachment -FullName 'value2' -FilePath 'value3'

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
				   Position = 2,
				   HelpMessage = 'The FullName of the to-be-uploaded file, including namespace(s)')]
		[ValidateNotNullOrEmpty()]
		[string]$FullName,
		[Parameter(Mandatory = $true,
				   Position = 3,
				   HelpMessage = 'The file path of the attachment to upload')]
		[ValidateScript({ Test-Path -Path $_ -PathType Leaf })]
		[string]$Path,
		[Parameter(HelpMessage = 'Force upload of attachment, overwriting any existing files with the same name')]
		[switch]$Force
	)

	$FileBytes = [IO.File]::ReadAllBytes($Path)
	# Moved conversion to Base64 to inside the function0.
	$APIResponse = Invoke-DokuApiCall -MethodName 'wiki.putAttachment' -MethodParameters @($FullName,$FileBytes,@{'ow' = [bool]$Forced})
	if ($APIResponse.CompletedSuccessfully -eq $true) {
		$FileItem = (Get-Item -Path $Path)
		$ResultString = [string]($APIResponse.XMLPayloadResponse | Select-Xml -XPath "//value/string").node.InnerText
		if ($ResultString -ne $FullName) {
			Write-Error "Error: $ResultString - Fullname: $FullName"
		}
	
		$attachmentObject = New-Object PSObject -Property @{
			FullName = $FullName
			SourceFilePath = $Path
			Size = $FileItem.Length
			SourceFileLastModified = $FileItem.LastWriteTimeUtc
			FileName = ($FullName -split ":")[-1]
			ParentNamespace = ($FullName -split ":")[-2]
			RootNamespace = ($FullName -split ":")[0]
		}
		$attachmentObject
	} elseif ($null -eq $APIResponse.ExceptionMessage) {
		Write-Error "Fault code: $($APIResponse.FaultCode) - Fault string: $($APIResponse.FaultString)"
	} else {
		Write-Error "Exception: $($APIResponse.ExceptionMessage)"
	}
}