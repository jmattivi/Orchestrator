#ListFolder#################################
#Created By: Jon Mattivi
#Modified Date: 09/18/2012
#v1.3 SCOrch IP for SFTP/FTP
############################################
#Define Variables
$Path = '$(Path)'
$Server = '$(Server)'
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
			"dir ""$Path""",
			"bye"
			)
			#Run psftp.exe to List Folder - Auto Accept Host Key
			$Output = $cmd | & .\psftp.exe -v -pw $Password $Username@$Server 2>&1
			$Err = [String]($Output -like "Unable to open *: failure")
			If ($LastExitCode -ne 0) {
				throw "Failed to List Folder!!!! `n $($Output)"
			}
			ElseIf (($Err.Contains("failure") -and $Err.StartsWith("Unable to open") -and $Err.EndsWith("failure")) -eq $true) {
				throw "Failed to List Folder!!!! `n $($Output)"
			}
		}
		ElseIf($AutoAcceptKey -eq $false) {
			$cmd = @(
			"dir ""$Path""",
			"bye"
			)
			#Run psftp.exe to List Folder - Do Not Auto Accept Host Key
			$Output = $cmd | & .\psftp.exe -v -pw $Password $Username@$Server 2>&1
			$Err = [String]($Output -like "Unable to open *: failure")
			If ($LastExitCode -ne 0) {
				throw "Failed to List Folder!!!! `n $($Output)"
			}
			ElseIf (($Err.Contains("failure") -and $Err.StartsWith("Unable to open") -and $Err.EndsWith("failure")) -eq $true) {
				throw "Failed to List Folder!!!! `n $($Output)"
			}
		}
	}
ElseIf ($Secure -eq $false) {
	#Config
	$uri = "ftp://$Server/$Path/"
	####List Folder####
	$FTPRequest = [System.Net.FtpWebRequest]::Create($uri);
	$FTPRequest.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectoryDetails
	$FTPRequest.UsePassive = $UsePassive
	$FTPRequest.Timeout = 120000
	$FTPRequest.Credentials = New-Object System.Net.NetworkCredential($Username,$Password)
	$FTPResponse = $FTPRequest.GetResponse();
	$FTPResponseStream = $FTPResponse.GetResponseStream();
	$buffer = new-object System.Byte[] 1024
	$encoding = new-object System.Text.AsciiEncoding
	$Output = ""
	$foundMore = $false
	## Read all the data available from the stream, writing it to the
	## output buffer when done.
	do
		{
		## Allow data to buffer for a bit
		start-sleep -m 1000
		## Read what data is available
		$foundmore = $false
		$FTPResponseStream.ReadTimeout = 1000
		do
			{
			try
			{
				$read = $FTPResponseStream.Read($buffer, 0, 1024)
				if($read -gt 0)
				{
					$foundmore = $true
					$Output += ($encoding.GetString($buffer, 0, $read))
				}
			} catch { $foundMore = $false; $read = 0 }
		} while($read -gt 0)
	} while($foundmore)
	$FTPResponse.Close();
}

#Create Published Data
If ($Secure -eq $True) {
	$Output = [system.string]::Join("`n",$Output)
	$StartIndex = ($Output.IndexOf("psftp> Listing directory"))
	$EndIndex = ($Output.IndexOf("Sent EOF message")) - $StartIndex
	$Output = $Output.Substring($StartIndex,$EndIndex)
	$Output = $Output.split("`n") | ?{($_ -notlike "*Listing Directory*") -and ($_ -ne "")}
	$Output = [system.string]::Join("`n",$Output)
}
ElseIf ($Secure -eq $False) {
	$Output = [system.string]::Join("`n",$Output)
}
$MyObject = new-object psobject
$Props = @"
Server
Path
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
$MyObject.Username = $Username
$MyObject.Secure = $Secure
$MyObject.AutoAcceptKey = $AutoAcceptKey
$MyObject.Output = $Output

$MyObject