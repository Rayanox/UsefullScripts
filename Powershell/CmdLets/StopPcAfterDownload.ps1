
function Stop-PCAfterDownload {
	[CmdletBinding()]
	Param(	
		[bool] $ShutdownPC =$( Read-Host "Shutdown ? (Y) If false (N), will sleep" | % { if($_ -eq "Y" -or $_ -eq "y"){$true} else {$false} } ),
		[int] $ExpectedPartsCount =$( Read-Host "How many parts to load ? " )
	)

	$SLEEP_TIME_MIN=5

	$pathDirectoryTarget = pwd

	$lastLengthCount=$null

	while(1) {
		$lastPartFilesResult=(ls -Path $pathDirectoryTarget | ?{ $_.Name.EndsWith(".part$($ExpectedPartsCount)") })
		$lastFileReached=($lastPartFilesResult -ne $null)

		if($lastFileReached) { 

			if($lastLengthCount -eq $null) {
				echo "Last part file just reached"
				$newLengthCount = $lastPartFilesResult.Length

				if($newLengthCount -gt $lastLengthCount) {
					echo "Dernier fichier (partie) toujours pas terminé"
				}else {					
					echo "Le téléchargement est terminé. FIN !!" 

					if($ShutdownPC) {
						echo "shutdown /s     # Shutdown the computer"
						shutdown /s    # Shutdown the computer						
					}else {
						echo "shutdown /h     # Hibernate (~= sleep)"
						shutdown /h    # Hibernate (~= sleep)						
					}
					return;
				}
				
				$lastLengthCount = $lastPartFilesResult.Length
			}

		}else{ 
			echo "On attend 5 nouvelles minutes avant de re-tester si on a fini le job ;)" 
			sleep -Seconds (60*$SLEEP_TIME_MIN)
		}
	}
}