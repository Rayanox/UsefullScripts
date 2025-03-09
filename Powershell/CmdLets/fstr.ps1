
[CmdletBinding]
function R-fstr {
	Param(
		[parameter(Mandatory=$true)]
		[String]
		$Str,
		
		[parameter(Mandatory=$true)]
		[String]
		$Path,
		
		[switch]
		$Recurse
	)

	if($Recurse) {
		Write-host "findstr.exe /I /S /N /P /C:`"$str`" $path" -foreground Green
		findstr.exe /I /S /P /N /C:"$str" $path
	}else {
		Write-host "findstr.exe /I /N /P /C:`"$str`" $path" -foreground Green
		findstr.exe /I /N /P /C:"$str" $path
	}	
}