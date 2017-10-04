#DownloadFile#################################
#Created By: Jon Mattivi
#Modified Date: 09/18/2012
#v1.3 SCOrch IP for SFTP/FTP
############################################
#Define Variables
$SourcePath = '$(SourcePath)'
$SourceServer = '$(SourceServer)'
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
			"lcd ""$DestPath""",
			"cd ""$SourcePath""",
			"mget ""$FileName""",
			"bye"
			)
			#Run psftp.exe to Upload File - Auto Accept Host Key
			$Output = $cmd | & .\psftp.exe -v -pw $Password $Username@$SourceServer 2>&1
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
			"lcd ""$DestPath""",
			"cd ""$SourcePath""",
			"mget ""$FileName""",
			"bye"
			)
			#Run psftp.exe to Upload File - Do Not Auto Accept Host Key
			$Output = $cmd | & .\psftp.exe -v -pw $Password $Username@$SourceServer 2>&1
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
	####Download File####
	$uri = "ftp://$SourceServer/$SourcePath/$FileName"
	$FTPRequest = [System.Net.FtpWebRequest]::create($uri)
	$FTPRequest.Method = [System.Net.WebRequestMethods+Ftp]::DownloadFile
	$FTPRequest.UseBinary = $UseBinary
	$FTPRequest.UsePassive = $UsePassive
	$FTPRequest.Timeout = 120000
	$FTPRequest.Credentials = New-Object System.Net.NetworkCredential($Username,$Password)
	$FTPResponse = $FTPRequest.GetResponse()
	If ($FTPResponse){
		$FTPResponsestream = $FTPResponse.GetResponseStream()
		$Target = $DestPath + "\" + $FileName
		$targetfile = New-Object IO.FileStream ("$Target",[IO.FileMode]::Create)
		[byte[]]$readbuffer = New-Object byte[] 1024
		do{
			$readlength = $FTPResponsestream.Read($readbuffer,0,1024)
    		$targetfile.Write($readbuffer,0,$readlength)
		}
		while ($readlength -ne 0)
		$targetfile.close()
	}
}
#Create Published Data
$Output = [system.string]::Join("`n",$Output)
$MyObject = new-object psobject
$Props = @"
SourceServer
SourcePath
DestPath
FileName
Username
Secure
AutoAcceptKey
Output
"@
$Props -split "`n" |%{
$MyObject | add-member -membertype noteproperty -name $_.trim() -value $null
}
$MyObject.SourceServer = $SourceServer
$MyObject.SourcePath = $SourcePath
$MyObject.DestPath = $DestPath
$MyObject.FileName = $FileName
$MyObject.Username = $Username
$MyObject.Secure = $Secure
$MyObject.AutoAcceptKey = $AutoAcceptKey
$MyObject.Output = $Output
$MyObject