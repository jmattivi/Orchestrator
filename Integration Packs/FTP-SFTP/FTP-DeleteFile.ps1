#DeleteFile#################################
#Created By: Jon Mattivi
#Modified Date: 09/18/2012
#v1.3 SCOrch IP for SFTP/FTP
############################################
#Define Variables
$Path = '$(Path)'
$Server = '$(Server)'
$FileName = '$(FileName)'
$Username = '$(Username)'
$Password = '$(Password)'
$Secure = $$(Secure)
$AutoAcceptKey = $$(AutoAcceptKey)
$UsePassive = $$(UsePassive)
$Output = @()

If ($Secure -eq $true) {
		If ($AutoAcceptKey -eq $true) {
			$cmd = @(
			"y",
			"This is a really, really, really, really long bogus cmd",
			"cd ""$Path""",
			"del ""$FileName""",
			"bye"
			)
			#Run psftp.exe to Delete File - Auto Accept Host Key
			$Output = $cmd | & .\psftp.exe -v -pw $Password $Username@$Server 2>&1
			$Err = [String]($Output -like "psftp> rm*OK")
			If ($LastExitCode -ne 0) {
				throw "Failed to Delete File!!!! `n $($Output)"
			}
			ElseIf (($Err.StartsWith("psftp> rm") -and $Err.EndsWith("OK")) -eq $false) {
				throw "Failed to Delete File!!!! `n $($Output)"
			}
		}
		ElseIf($AutoAcceptKey -eq $false) {
			$cmd = @(
			"cd ""$Path""",
			"del ""$FileName""",
			"bye"
			)
			#Run psftp.exe to Delete File - Do Not Auto Accept Host Key
			$Output = $cmd | & .\psftp.exe -v -pw $Password $Username@$Server 2>&1
			$Err = [String]($Output -like "psftp> rm*OK")
			If ($LastExitCode -ne 0) {
				throw "Failed to Delete File!!!! `n $($Output)"
			}
			ElseIf (($Err.StartsWith("psftp> rm") -and $Err.EndsWith("OK")) -eq $false) {
				throw "Failed to Delete File!!!! `n $($Output)"
			}
		}
}
ElseIf ($Secure -eq $false) {
	#Config
	$uri = "ftp://$Server/$Path/$FileName"
	####Delete File####
	$FTPRequest = [System.Net.FtpWebRequest]::Create($uri);
	$FTPRequest.Method = [System.Net.WebRequestMethods+Ftp]::DeleteFile
	$FTPRequest.UseBinary = $true
	$FTPRequest.UsePassive = $UsePassive
	$FTPRequest.Timeout = 120000
	$FTPRequest.Credentials = New-Object System.Net.NetworkCredential($Username,$Password)
	$FTPResponse = $FTPRequest.GetResponse();
	$FTPResponse.Close();
}

#Create Published Data
$Output = [system.string]::Join("`n",$Output)
$MyObject = new-object psobject
$Props = @"
Server
Path
FileName
Username
Secure
AutoAcceptKey
Output
"@

$Props -split "`n" |%{
$MyObject | add-member -membertype noteproperty -name $_.trim() -value $null
}

$MyObject.Server = $Server
$MyObject.Path = $Path
$MyObject.FileName = $FileName
$MyObject.Username = $Username
$MyObject.Secure = $Secure
$MyObject.AutoAcceptKey = $AutoAcceptKey
$MyObject.Output = $Output

$MyObject