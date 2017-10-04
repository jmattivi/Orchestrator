#UploadFile#################################
#Created By: Jon Mattivi
#Modified Date: 09/18/2012
#v1.3 SCOrch IP for SFTP/FTP
############################################
#Define Variables
$SourcePath = '$(SourcePath)'
$DestServer = '$(DestServer)'
$DestPath = '$(DestPath)'
$FileName = '$(FileName)'
$Username = '$(Username)'
$Password = '$(Password)'
$Secure = $$(Secure)
$AutoAcceptKey = $$(AutoAcceptKey)
$UsePassive = $$(UsePassive)
$UseBinary = $$(UseBinary)
$Output = @()

If ($Secure -eq $true) {
		If ($AutoAcceptKey -eq $true) {
			$cmd = @(
			"y",
			"This is a really, really, really, really long bogus cmd",
			"lcd ""$SourcePath""",
			"cd ""$DestPath""",
			"mput ""$FileName""",
			"bye"
			)
			#Run psftp.exe to Upload File - Auto Accept Host Key
			$Output = $cmd | & .\psftp.exe -v -pw $Password $Username@$DestServer 2>&1
			$Err = [String]($Output -like "*=>*")
			$LocalErr = [String]($Output -like "*New local directory is*")
			$RemoteErr = [String]($Output -like "*Remote directory is now*")
			If ($LastExitCode -ne 0) {
				throw "File Failed to Transfer!!!! `n $($Output)"
			}
			ElseIf (($LocalErr.Contains("New local directory is")) -eq $false) {
				throw "Failed to Change Local Directory!!!! `n $($Output)"
			}
			ElseIf (($RemoteErr.Contains("Remote directory is now")) -eq $false) {
				throw "Failed to Change Remote Directory!!!! `n $($Output)"
			}
			ElseIf (($Err.Contains("=>")) -eq $false) {
				throw "File Failed to Transfer!!!! `n $($Output)"
			}			
		}
		ElseIf($AutoAcceptKey -eq $false) {
			$cmd = @(
			"lcd ""$SourcePath""",
			"cd ""$DestPath""",
			"mput ""$FileName""",
			"bye"
			)
			#Run psftp.exe to Upload File - Do Not Auto Accept Host Key
			$Output = $cmd | & .\psftp.exe -v -pw $Password $Username@$DestServer 2>&1
			$Err = [String]($Output -like "*=>*")
			$LocalErr = [String]($Output -like "*New local directory is*")
			$RemoteErr = [String]($Output -like "*Remote directory is now*")
			If ($LastExitCode -ne 0) {
				throw "File Failed to Transfer!!!! `n $($Output)"
			}
			ElseIf (($LocalErr.Contains("New local directory is")) -eq $false) {
				throw "Failed to Change Local Directory!!!! `n $($Output)"
			}
			ElseIf (($RemoteErr.Contains("Remote directory is now")) -eq $false) {
				throw "Failed to Change Remote Directory!!!! `n $($Output)"
			}
			ElseIf (($Err.Contains("=>")) -eq $false) {
				throw "File Failed to Transfer!!!! `n $($Output)"
			}
		}
}
ElseIf ($Secure -eq $false) {
	####Upload File####
	#Config
	$uri = "ftp://$DestServer/$DestPath/$FileName"
	#Create FTP Rquest Object
	$FTPRequest = [System.Net.FtpWebRequest]::Create($uri)
	$FTPRequest = [System.Net.FtpWebRequest]$FTPRequest
	$FTPRequest.Method = [System.Net.WebRequestMethods+Ftp]::UploadFile
	$FTPRequest.UseBinary = $UseBinary
	$FTPRequest.UsePassive = $UsePassive
	$FTPRequest.Timeout = 120000
	$FTPRequest.Credentials = new-object System.Net.NetworkCredential($Username, $Password)
	#Read the File for Upload
	$FileContent = [System.IO.File]::ReadAllBytes($SourcePath + "\" + $FileName)
	$FTPRequest.ContentLength = $FileContent.Length
	#Get Stream Request by bytes
	If ($FileContent){
		$Run = $FTPRequest.GetRequestStream()
		$Run.Write($FileContent, 0, $FileContent.Length)
		#Cleanup
		$Run.Close()
		$Run.Dispose()
	}
	Else {
		throw "File to upload is empty!  File failed to transfer!!!!"
	}
}

#Create Published Data
$Output = [system.string]::Join("`n",$Output)
$MyObject = new-object psobject
$Props = @"
DestServer
DestPath
SourcePath
FileName
Username
Secure
AutoAcceptKey
Output
"@

$Props -split "`n" |%{
$MyObject | add-member -membertype noteproperty -name $_.trim() -value $null
}

$MyObject.DestServer = $DestServer
$MyObject.DestPath = $DestPath
$MyObject.SourcePath = $SourcePath
$MyObject.FileName = $FileName
$MyObject.Username = $Username
$MyObject.Secure = $Secure
$MyObject.AutoAcceptKey = $AutoAcceptKey
$MyObject.Output = $Output

$MyObject