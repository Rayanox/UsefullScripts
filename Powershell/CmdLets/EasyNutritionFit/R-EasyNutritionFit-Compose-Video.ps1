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
    $UPLOAD_URL = "http://localhost:5678/webhook/9be03d65-4e9d-4e92-9e9f-33de72709845"
    
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
            $confirmUpload = Read-Host "Ready to upload video to YouTube. Press Enter to continue"
            if ($confirmUpload -ne "") {
                Write-Host "Operation aborted." -ForegroundColor Yellow
                exit 1
            }
        }

        return Upload-To-YouTube-Simple -PathWorkspace $PathWorkspace -UploadUrl $UPLOAD_URL -RecipeName $RecipeName
    }

    # Si on arrive ici, soit c'est VIDEO_COMPOSE_ONLY, soit pas de mode spécifié
    Check-FFmpeg
    
    # Prompt before merging videos
    if (-not $ForceAnswersTrue) {
        $confirmMerge = Read-Host "Ready to merge videos. Press Enter to continue"
        if ($confirmMerge -ne "") {
            Write-Host "Operation aborted." -ForegroundColor Yellow
            exit 1
        }
    }
    
    Concatenate-Videos -PathWorkspace $PathWorkspace

    # Si mode VIDEO_COMPOSE_ONLY, arrêter ici
    if ($Mode -eq "VIDEO_COMPOSE_ONLY") {
        Write-Host "Video composition completed. Skipping upload as per VIDEO_COMPOSE_ONLY mode." -ForegroundColor Green
        return $null
    }

    # Si on arrive ici, c'est qu'on fait l'upload aussi
    if (-not $ForceAnswersTrue) {
        $confirmUpload = Read-Host "Ready to upload video to YouTube. Press Enter to continue"
        if ($confirmUpload -ne "") {
            Write-Host "Operation aborted." -ForegroundColor Yellow
            exit 1
        }
    }
    
    return Upload-To-YouTube-Simple -PathWorkspace $PathWorkspace -UploadUrl $UPLOAD_URL -RecipeName $RecipeName
}

# ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
# ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
# █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
# ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
# ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚█████╔╝██║ ╚████║███████║
# ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝


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
        [string]$UploadUrl, 

        [Parameter(Mandatory = $true)]
        [string]$RecipeName 
    )
    
    Write-Host "Preparing to upload to YouTube..." -ForegroundColor Green
    
    $finalVideo = "$PathWorkspace\$PREFIX_FINALE_VIDEO$RecipeName.mp4"
    if (-not (Test-Path $finalVideo)) {
        Write-Host "Final video not found at path: $finalVideo" -ForegroundColor Red
        return $null
    }
    
    try {
        # Créer un objet pour les données multipart
        $boundary = [System.Guid]::NewGuid().ToString()
        $LF = "`r`n"
        
        # Préparer le contenu du fichier
        $fileBytes = [System.IO.File]::ReadAllBytes($finalVideo)
        $encoding = [System.Text.Encoding]::UTF8
        
        # Construire le corps de la requête
        $bodyLines = (
            "--$boundary",
            "Content-Disposition: form-data; name=`"NomVideo`"$LF",
            $RecipeName,
            "--$boundary",
            "Content-Disposition: form-data; name=`"data`"; filename=`"$($RecipeName).mp4`"",
            "Content-Type: video/mp4$LF",
            [System.Text.Encoding]::UTF8.GetString($fileBytes),
            "--$boundary--"
        ) -join $LF
        
        Write-Host "Uploading video to server..." -ForegroundColor Cyan
        
        # Faire l'appel POST
        $encodedRecipeName = [System.Web.HttpUtility]::UrlEncode($RecipeName)
        $response = Invoke-RestMethod `
            -Uri "$($UploadUrl)?NomVideo=$encodedRecipeName" `
            -Method Post `
            -ContentType "multipart/form-data; boundary=$boundary" `
            -Body $bodyLines
        
        if ($response) {
            $videoId = $response
            $youtubeUrl = "https://youtu.be/$videoId"
            
            Write-Host "Video uploaded successfully!" -ForegroundColor Green
            Write-Host "Video ID: $videoId" -ForegroundColor Cyan
            Write-Host "YouTube URL: $youtubeUrl" -ForegroundColor Cyan
            
            return $videoId
        }
        else {
            Write-Host "Error: Server returned empty response" -ForegroundColor Red
            return $null
        }
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