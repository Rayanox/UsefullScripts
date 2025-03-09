
function R-Hibernate {
	[CmdletBinding()]
	Param(
		[int] $MinutesToWait =$( Read-Host "How much time to wait before hibernate ? (minutes) : " )
	)

	sleep -Seconds (60*$MinutesToWait)
		
	shutdown.exe /h
}