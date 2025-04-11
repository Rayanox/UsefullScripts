function R-EasyNutritionFit-Compose-Video {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Path to the workspace directory. If not provided, a temporary directory will be used.")]
        [string]$PathWorkspace,

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory containing video files to import into the workspace.")]
        [string]$PathImport,

        [Parameter(Mandatory = $true, HelpMessage = "The name of the recipe, used to generate the final video filename.")]
        [string]$RecipeName,

        [Parameter(Mandatory = $false, HelpMessage = "If set, all confirmation prompts will be automatically accepted.")]
        [switch]$ForceAnswersTrue,

        [Parameter(Mandatory = $false, HelpMessage = "Operation mode: VIDEO_COMPOSE_ONLY to only create the video, UPLOAD_ONLY to only upload an existing video.")]
        [ValidateSet("VIDEO_COMPOSE_ONLY", "UPLOAD_ONLY", "ANY")]
        [string]$Mode = "ANY",

        [Parameter(Mandatory = $false, HelpMessage = "If set, the import of videos will be skipped.")]
        [switch]$SkipImport
    )

    Add-Type -AssemblyName System.Web

    #  ██████╗ ██████╗ ███╗   ██╗███████╗████████╗ █████╗ ███╗   ██╗████████╗███████╗███████╗
    # ██╔════╝██╔═══██╗████╗  ██║██╔════╝╚══██╔══╝██╔══██╗████╗  ██║╚══██╔══╝██╔════╝██╔════╝
    # ██║     ██║   ██║██╔██╗ ██║███████╗   ██║   ███████║██╔██╗ ██║   ██║   █████╗  ███████╗
    # ██║     ██║   ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║╚██╗██║   ██║   ██╔══╝  ╚════██║
    # ╚██████╗╚██████╔╝██║ ╚████║███████║   ██║   ██║  ██║██║ ╚████║   ██║   ███████╗███████║
    #  ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚══════╝
    
    
    $PREFIX_FINALE_VIDEO = 'FV_'
    $CONFIG_DIR = "$env:LOCALAPPDATA\EasyNutritionFit"

    $MAX_SIZE_MB = 400
    
    # ███╗   ███╗ █████╗ ██╗███╗   ██╗
    # ████╗ ████║██╔══██╗██║████╗  ██║
    # ██╔████╔██║███████║██║██╔██╗ ██║
    # ██║╚██╔╝██║██╔══██║██║██║╚██╗██║
    # ██║ ╚═╝ ██║██║  ██║██║██║ ╚████║
    # ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝


    


    # Si mode UPLOAD_ONLY, vérifier que la vidéo existe et passer directement à l'upload
    if ($Mode -eq "UPLOAD_ONLY") {
        $finalVideo = "$PathWorkspace\$PREFIX_FINALE_VIDEO$RecipeName.mp4"
        if (-not (Test-Path $finalVideo)) {
            Write-Host "Error: Final video not found at path: $finalVideo" -ForegroundColor Red
            Write-Host "When using UPLOAD_ONLY mode, the final video must already exist in the workspace." -ForegroundColor Red
            exit 1
        }

        # Prompt before uploading to YouTube
        if (-not $ForceAnswersTrue) {
            Write-Host -ForegroundColor Blue "Ready to upload video to YouTube. Press Enter to continue"
            Write-Host -ForegroundColor DarkRed "ATTENTION: This will upload the video to YouTube. Please: Check the video before uploading, ensure you do not have to modify the video, and that the video is ready to be uploaded before pressing Enter."
            $confirmUpload = Read-Host
            if ($confirmUpload -ne "") {
                Write-Host "Operation aborted." -ForegroundColor Yellow
                exit 1
            }
        }

        return Upload-To-YouTube-Simple -PathWorkspace $PathWorkspace -RecipeName $RecipeName
    }

    # Si on arrive ici, soit c'est VIDEO_COMPOSE_ONLY, soit pas de mode spécifié
    Check-FFmpeg
    
    # Prompt before merging videos
    if (-not $ForceAnswersTrue) {
        Write-Host -ForegroundColor Blue "Ready to merge videos. Press Enter to continue"
        $confirmMerge = Read-Host
        if ($confirmMerge -ne "") {
            Write-Host "Operation aborted." -ForegroundColor Yellow
            exit 1
        }
    }
    
    Concatenate-Videos -PathWorkspace $PathWorkspace

    Write-Host "`nAbout to optimize the video, if you want to modify the video, please do it now before clicking Enter !`n" -ForegroundColor DarkRed
    #Write-Host "(next steps may take a while (same time as video duration), so please be patient and do not interrupt the process)" -ForegroundColor Blue
    Write-Host "(next steps may take a while, so please be patient and do not interrupt the process)" -ForegroundColor Blue
    Read-Host

    #Optimize-Video-For-YouTube-Sending -PathWorkspace $PathWorkspace -RecipeName $RecipeName

    # Si mode VIDEO_COMPOSE_ONLY, arrêter ici
    if ($Mode -eq "VIDEO_COMPOSE_ONLY") {
        Write-Host "Video composition completed. Skipping upload as per VIDEO_COMPOSE_ONLY mode." -ForegroundColor Green
        return $null
    }

    # Si on arrive ici, c'est qu'on fait l'upload aussi
    if (-not $ForceAnswersTrue) {
        Write-Host -ForegroundColor Blue "Ready to upload video to YouTube. Press Enter to continue"
        Write-Host -ForegroundColor DarkRed "ATTENTION: This will upload the video to YouTube. Please: Check the video before uploading, ensure you do not have to modify the video, and that the video is ready to be uploaded before pressing Enter."
        $confirmUpload = Read-Host
        if ($confirmUpload -ne "") {
            Write-Host "Operation aborted." -ForegroundColor Yellow
            exit 1
        }
    }
    
    return Upload-To-YouTube-Simple -PathWorkspace $PathWorkspace -RecipeName $RecipeName
}

# ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
# ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
# █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
# ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
# ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚█████╔╝██║ ╚████║███████║
# ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝


function Optimize-Video-For-YouTube-Sending {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PathWorkspace,
        [Parameter(Mandatory = $true)]
        [string]$RecipeName
    )

    $finalVideo = "$PathWorkspace\$PREFIX_FINALE_VIDEO$RecipeName.mp4"
    if (-not (Test-Path $finalVideo)) {
        Write-Host "Final video not found at path: $finalVideo" -ForegroundColor Red
        return $null
    }   

    Test-And-Compress-Video -VideoPath $finalVideo
}

function Test-And-Compress-Video {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VideoPath
    )

    $fileSizeMB = Get-Video-Size-MB -VideoPath $VideoPath

    if ($fileSizeMB -gt $MAX_SIZE_MB) {
        Write-Host "La vidéo fait $([math]::Round($fileSizeMB,2)) MB, ce qui dépasse la limite de $MAX_SIZE_MB MB" -ForegroundColor Yellow
        Write-Host "Compression de la vidéo en cours..." -ForegroundColor Cyan

        Backup-Original-Video -VideoPath $VideoPath
        Compress-Video -VideoPath $VideoPath

        $newFileSizeMB = Get-Video-Size-MB -VideoPath $VideoPath
        Write-Host "Compression terminée. Nouvelle taille: $([math]::Round($newFileSizeMB,2)) MB" -ForegroundColor Green
    }
    else {
        Write-Host "La taille de la vidéo ($([math]::Round($fileSizeMB,2)) MB) est acceptable" -ForegroundColor Green
    }
}

function Get-Video-Size-MB {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VideoPath
    )
    
    $fileInfo = Get-Item $VideoPath
    return $fileInfo.Length / 1MB
}

function Backup-Original-Video {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VideoPath
    )

    $originalVideo = $VideoPath -replace '\.mp4$', '_ORIGINAL.mp4'
    Move-Item -Path $VideoPath -Destination $originalVideo -Force
    return $originalVideo
}

function Get-Video-Duration-Seconds {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VideoPath
    )

    $durationOutput = & ffmpeg -i $VideoPath 2>&1
    $durationMatch = $durationOutput | Select-String "Duration: (\d{2}):(\d{2}):(\d{2})"
    if ($durationMatch) {
        $hours = [int]$durationMatch.Matches[0].Groups[1].Value
        $minutes = [int]$durationMatch.Matches[0].Groups[2].Value 
        $seconds = [int]$durationMatch.Matches[0].Groups[3].Value
        return ($hours * 3600) + ($minutes * 60) + $seconds
    }
    throw "Impossible de déterminer la durée de la vidéo"
}

function calculate-bitrate-for-expected-video-size {
    param(
        [Parameter(Mandatory = $true)]
        [int]$expectedVideoSizeMB
    )

    $durationSec = Get-Video-Duration-Seconds -VideoPath $originalVideo
    $bitrateKbps = [math]::Floor(($expectedVideoSizeMB * 8192) / $durationSec)  # 8192 = 1024 * 8
    return $bitrateKbps

    #$originalVideoSizeMB = Get-Video-Size-MB -VideoPath $VideoPath
    #$bitRateForExpectedVideoSize = $originalVideoSizeMB / $expectedVideoSizeMB
    #return $bitRateForExpectedVideoSize
}   

function Compress-Video {
    param(
        [Parameter(Mandatory = $true)]
        [string]$VideoPath
    )

    $originalVideo = $VideoPath -replace '\.mp4$', '_ORIGINAL.mp4'

    $bitRateForExpectedVideoSize = calculate-bitrate-for-expected-video-size -expectedVideoSizeMB $MAX_SIZE_MB

    Write-Host "Valeur bitRate = $bitRateForExpectedVideoSize" -ForegroundColor Gray
    

    try {
        #$process = Start-Process -NoNewWindow -Wait -FilePath ffmpeg -ArgumentList "-i `"$originalVideo`" -c:v libx264 -crf 28 -preset medium -b:v $bitRateForExpectedVideoSize -c:a aac -b:a 128k `"$VideoPath`"" -PassThru
        $process = Start-Process -NoNewWindow -Wait -FilePath ffmpeg -ArgumentList "-i `"$originalVideo`" -b:v $($bitRateForExpectedVideoSize)k -maxrate $($bitRateForExpectedVideoSize)k -bufsize $($bitRateForExpectedVideoSize*2)k -c:a aac -b:a 128k `"$VideoPath`"" -PassThru
        #ffmpeg -i ".\FV_Couscous by Donia.mp4" -b:v 377k -maxrate 377k -bufsize 754k -c:a aac -b:a 128k ./resut.mp4
        if ($process.ExitCode -ne 0) {
            Write-Host "Erreur lors de la compression de la vidéo (Code de sortie: $($process.ExitCode))" -ForegroundColor Red
            # Restaurer le fichier original
            Move-Item -Path $originalVideo -Destination $VideoPath -Force
            exit 1
        }
    }
    catch {
        Write-Host "Erreur lors de l'exécution de FFmpeg: $_" -ForegroundColor Red
        # Restaurer le fichier original
        Move-Item -Path $originalVideo -Destination $VideoPath -Force
        exit 1
    }
    
}

function Check-FFmpeg {
    if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        Write-Host "ffmpeg not found. Installing..." -ForegroundColor Yellow
        $ffmpegPath = "$env:LOCALAPPDATA\ffmpeg"
        if (-not (Test-Path $ffmpegPath)) {
            New-Item -ItemType Directory -Path $ffmpegPath | Out-Null
        }
        
        # Direct download of ffmpeg for Windows from ffmpeg.org
        $ffmpegUrl = "https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip"
        $downloadPath = "$ffmpegPath\ffmpeg.zip"
        
        Write-Host "Downloading ffmpeg from $ffmpegUrl..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $ffmpegUrl -OutFile $downloadPath
        
        Write-Host "Extracting ffmpeg..." -ForegroundColor Yellow
        Expand-Archive -Path $downloadPath -DestinationPath $ffmpegPath -Force
        
        # Find the bin directory in the extracted files
        $binDirectory = Get-ChildItem -Path $ffmpegPath -Recurse -Directory | Where-Object { $_.Name -eq "bin" } | Select-Object -First 1
        
        if ($binDirectory) {
            Write-Host "Adding ffmpeg to PATH..." -ForegroundColor Yellow
            $env:PATH += ";$($binDirectory.FullName)"
        } else {
            Write-Error "Could not find ffmpeg bin directory in the extracted files."
            exit 1
        }
    }
}

function Concatenate-Videos {
    param($PathWorkspace)
    # Get video list first to check if empty
    $videoList = Get-ChildItem -Path $PathWorkspace -Filter "*.mp4" | Where-Object { $_.Name -notmatch "^$PREFIX_FINALE_VIDEO" } | Sort-Object Name
    
    # Check if video list is empty
    if (-not $videoList) {
        Write-Host "Error: No videos found in workspace directory ($PathWorkspace). Try to either specify a specific folder containing video data (PathWorkspace parameter) or import videos from import path parameter called 'PathImport'." -ForegroundColor Red
        exit 1
    }

    $finalVideo = "$PathWorkspace\$PREFIX_FINALE_VIDEO$RecipeName.mp4"
    if (Test-Path $finalVideo) {
        if (-not $ForceAnswersTrue) {
            $confirm = Read-Host "Final video exists. Overwrite? (Enter to confirm)"
            if ($confirm -ne "") {
                Write-Host "Operation aborted." -ForegroundColor Yellow
                exit 1
            }
        }
        Remove-Item $finalVideo -Force
    }
    $listFile = "$PathWorkspace\video_list.txt"
    # Utiliser Resolve-Path pour obtenir les chemins absolus
    Push-Location $PathWorkspace
    $videoList | ForEach-Object { "file '" + (Resolve-Path -Path $_.FullName).Path + "'" } | Set-Content $listFile
    
    Write-Host "Merging videos..." -ForegroundColor Cyan
    try {
        # Utiliser le chemin absolu pour le fichier de liste
        $listFileAbsolute = (Resolve-Path -Path $listFile).Path
        $process = Start-Process -NoNewWindow -Wait -FilePath ffmpeg -ArgumentList "-f concat -safe 0 -i `"$listFileAbsolute`" -c copy `"$finalVideo`"" -PassThru
        if ($process.ExitCode -ne 0) {
            Write-Host "Error: FFmpeg failed to merge videos (Exit code: $($process.ExitCode))" -ForegroundColor Red
            exit 1
        }
    }
    catch {
        Write-Host "Error: Failed to execute FFmpeg command: $_" -ForegroundColor Red
        exit 1
    }
    finally {
        Pop-Location
    }
}

function Upload-To-YouTube-Simple {
    param(
        [Parameter(Mandatory = $true)]
        [string]$PathWorkspace,

        [Parameter(Mandatory = $true)]
        [string]$RecipeName 
    )
    
    Write-Host "Preparing to upload to YouTube..." -ForegroundColor Blue
    
    $finalVideo = "$PathWorkspace\$PREFIX_FINALE_VIDEO$RecipeName.mp4"
    if (-not (Test-Path $finalVideo)) {
        Write-Host "Final video not found at path: $finalVideo" -ForegroundColor Red
        return $null
    }
    
    try {
        return R-EasyNutritionFit-Upload-Youtube -VideoPath $finalVideo -Title $RecipeName -PrivacyStatus unlisted
    }
    catch {
        Write-Host "Error uploading video: $_" -ForegroundColor Red
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode.value__
            $statusDescription = $_.Exception.Response.StatusDescription
            Write-Host "Server returned status code: $statusCode - $statusDescription" -ForegroundColor Red
        }
        return $null
    }
}