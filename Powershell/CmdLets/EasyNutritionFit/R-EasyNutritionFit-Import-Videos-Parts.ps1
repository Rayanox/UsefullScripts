function R-EasyNutritionFit-Import-Videos-Parts {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Source path on Android device. If not provided, will use default camera path.")]
        [string]$PathImport,

        [Parameter(Mandatory = $true, HelpMessage = "Target path where videos will be imported.")]
        [string]$TargetImportPath,
        
        [Parameter(Mandatory = $false, HelpMessage = "If set, all answers will be true.")]
        [switch]$AllAnswersTrue,

        [Parameter(Mandatory = $false, HelpMessage = "If set, will not perform any action.")]
        [switch]$WhatIf
    )

    
    #  ██████╗ ██████╗ ███╗   ██╗███████╗████████╗ █████╗ ███╗   ██╗████████╗███████╗███████╗
    # ██╔════╝██╔═══██╗████╗  ██║██╔════╝╚══██╔══╝██╔══██╗████╗  ██║╚══██╔══╝██╔════╝██╔════╝
    # ██║     ██║   ██║██╔██╗ ██║███████╗   ██║   ███████║██╔██╗ ██║   ██║   █████╗  ███████╗
    # ██║     ██║   ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║╚██╗██║   ██║   ██╔══╝  ╚════██║
    # ╚██████╗╚██████╔╝██║ ╚████║███████║   ██║   ██║  ██║██║ ╚████║   ██║   ███████╗███████║
    #  ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚══════╝
    

    # Constants
    $ANDROID_CAMERA_FOLDER = "/sdcard/DCIM/Camera"
    $MIN_VIDEOS_PER_DAY = 3


    # ███╗   ███╗ █████╗ ██╗███╗   ██╗
    # ████╗ ████║██╔══██╗██║████╗  ██║
    # ██╔████╔██║███████║██║██╔██╗ ██║
    # ██║╚██╔╝██║██╔══██║██║██║╚██╗██║
    # ██║ ╚═╝ ██║██║  ██║██║██║ ╚████║
    # ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝

    try {

        if (-not (Test-ADB)) {
            Write-Host "ADB not found. Please, first install ADB and add it to the path before restarting console and running this script." -ForegroundColor Red
            return $false
        }

        $deviceId = Get-ConnectedAndroidDevice
        if (-not $deviceId) {
            Write-Host "Error: No Android device connected or authorized." -ForegroundColor Red
            return $false
        }

        $androidPhotosPath = Get-AndroidPhotosPath -DeviceId $deviceId
        if (-not $androidPhotosPath) {
            Write-Host "Error: No Android device connected or authorized." -ForegroundColor Red
            return $false
        }

        Write-Host "Setting import path to $androidPhotosPath" -ForegroundColor Yellow
        $PathImport = $androidPhotosPath

        # Get video list from device
        $videosToImport = Select-VideosToImport -DeviceId $deviceId -SourcePath $PathImport -AllAnswersTrue $AllAnswersTrue
        if ($videosToImport) {
            Import-SelectedVideos -DeviceId $deviceId -Videos $videosToImport -TargetPath $TargetImportPath
            Write-Host "Videos successfully imported to $TargetImportPath" -ForegroundColor Green
            return $true
        } else {
            Write-Host "No videos were selected for import." -ForegroundColor Yellow
            return $false
        }
    }
    catch {
        Write-Host "Error during video import process: $_" -ForegroundColor Red
        return $false
    }
}

#  ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
#  ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
#  █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
#  ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
#  ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚█████╔╝██║ ╚████║███████║
#  ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝


function Get-ConnectedAndroidDevice {
    $devices = @(adb devices | Select-Object -Skip 1 | Where-Object { $_ -match "device$" })
    if (-not $devices) {
        Write-Host "No Android device detected. Please:" -ForegroundColor Red
        Write-Host "1. Connect your phone via USB" -ForegroundColor Yellow
        Write-Host "2. Enable USB Debugging in developer options" -ForegroundColor Yellow
        Write-Host "3. Allow the connection on your phone when the popup appears" -ForegroundColor Yellow
        return
    }

    Write-Host "Android device(s) detected:" -ForegroundColor Green
    $devices | ForEach-Object {
        $serial = $_.Split()[0]
        Write-Host "- $serial" -ForegroundColor Cyan
    }

    return $devices[0].Split()[0]
}
    
function Get-AndroidPhotosPath {
    param (
        [Parameter(Mandatory = $true)]
        [string]$deviceId
    )

    # Get external storage path (usually /sdcard or /storage/emulated/0)
    $storagePath = adb -s $deviceId shell echo `$EXTERNAL_STORAGE
    if (-not $storagePath) {
        $storagePath = "/sdcard"
    }

    # Get external storage path (usually /sdcard or /storage/emulated/0)
    $storagePath = adb -s $deviceId shell echo `$EXTERNAL_STORAGE
    if (-not $storagePath) {
        $storagePath = "/sdcard"
    }

    # Full path to photos folder (may vary by manufacturer)
    $photosPath = "$storagePath/DCIM/Camera"
    
    # Check if folder exists on device
    $folderExists = adb -s $deviceId shell "if [ -d '$photosPath' ]; then echo 'exists'; fi"
    
    if ($folderExists -eq "exists") {
        Write-Host "Photos/videos folder found:" -ForegroundColor Green
        Write-Host "$photosPath" -ForegroundColor Cyan
        return $photosPath
    }
    else {
        Write-Host "Standard Camera folder not found. Trying alternative search..." -ForegroundColor Yellow
        
        # Alternative search for other manufacturers
        $alternativePaths = @(
            "$storagePath/DCIM/100ANDRO",
            "$storagePath/DCIM/100MEDIA", 
            "$storagePath/DCIM/100_PANA",
            "$storagePath/Pictures",
            "$storagePath/DCIM"
        )
        
        foreach ($path in $alternativePaths) {
            $folderExists = adb -s $deviceId shell "if [ -d '$path' ]; then echo 'exists'; fi"
            if ($folderExists -eq "exists") {
                Write-Host "Media folder found:" -ForegroundColor Green
                Write-Host "$path" -ForegroundColor Cyan
                return $path
            }
        }
        
        Write-Host "Unable to locate photos/videos folder on device." -ForegroundColor Red
        Write-Host "Try browsing manually with: adb shell ls $storagePath/DCIM/" -ForegroundColor Yellow
        return $null
    }
}

# Function to check if ADB module is available
function Test-ADB {
    try {
        $null = Get-Command adb -ErrorAction Stop
        return $true
    }
    catch {
        Write-Host "ADB (Android Debug Bridge) is not installed or not in PATH." -ForegroundColor Red
        Write-Host "Please install Android Platform Tools SDK from:" -ForegroundColor Yellow
        Write-Host "https://developer.android.com/studio/releases/platform-tools" -ForegroundColor Cyan
        return $false
    }
}

function Select-VideosToImport {
    param (
        [Parameter(Mandatory = $true)]
        [string]$DeviceId,
        
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $false)]
        [bool]$AllAnswersTrue = $false
    )

    # Get video list with their dates
    $videoList = adb -s $DeviceId shell "ls -l $SourcePath/*.mp4" | 
        Where-Object { $_ -match "\.mp4$" } |
        ForEach-Object {
            if ($_ -match "(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2})\s+(.+\.mp4)$") {
                @{
                    Name = $matches[3]
                    FullPath = "$($matches[3])"
                    Date = [DateTime]::ParseExact("$($matches[1]) $($matches[2])", "yyyy-MM-dd HH:mm", $null)
                }
            }
        }

    # Group by date and sort by descending date
    $videosByDate = $videoList | 
        Group-Object { $_.Date.Date } | 
        Sort-Object { $_.Name -as [DateTime] } -Descending

    if($videosByDate.Count -gt 0) {
        Write-Host "`n`nSelect the video series to import. Use ↑/↓ arrows to navigate, Enter to select, 'q' to quit`n`n" -ForegroundColor Yellow
    }

    $currentIndex = 0
    $isGoingDown = $true
    while ($videosByDate.Count -gt 0) {
        $dateGroup = $videosByDate[$currentIndex]
        
        if ($dateGroup.Count -ge $MIN_VIDEOS_PER_DAY -or $currentIndex -eq 0 -or $currentIndex -eq ($videosByDate.Count - 1)) {
            Write-Host "`nDate: $([DateTime]::Parse($dateGroup.Name).ToString("dd/MM/yyyy")) - $($dateGroup.Count) videos found:" -ForegroundColor Cyan
            $dateGroup.Group | ForEach-Object { Write-Host "  - $($_.Name)" }

            $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            
            switch ($key.VirtualKeyCode) {
                38 { # Up Arrow
                    if ($currentIndex -gt 0) { $currentIndex-- }
                    $isGoingDown = $false
                }
                40 { # Down Arrow
                    if ($currentIndex -lt ($videosByDate.Count - 1)) { $currentIndex++ }
                    $isGoingDown = $true
                }
                13 { # Enter Key
                    return $dateGroup.Group
                }
                81 { # 'q' Key
                    Write-Host "`nOperation cancelled by user." -ForegroundColor Yellow
                    return $null
                }
            }
        } else {
            Write-Host "Date: $($dateGroup.Name) - Not enough videos found for this date ($($dateGroup.Count) instead of $MIN_VIDEOS_PER_DAY videos). Skipped..." -ForegroundColor Yellow
            if ($isGoingDown) { $currentIndex++ } else { $currentIndex-- }
        }
    }
    return $null
}

<#
function Show-SelectionMenu {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    if ($AllAnswersTrue) {
        Write-Host "$Message -> Automatiquement sélectionné Oui (AllAnswersTrue est activé)" -ForegroundColor Yellow
        return $true
    }

    do {
        Write-Host "`n$Message (o/n): " -ForegroundColor Cyan -NoNewline
        $response = Read-Host
        
        # Convertir la réponse en minuscules et nettoyer les espaces
        $response = $response.ToLower().Trim()
        
        switch ($response) {
            { $_ -in @('o', 'oui', 'y', 'yes') } { return $true }
            { $_ -in @('n', 'non', 'no', '') } { return $false }
            default {
                Write-Host "Invalid response. Please respond with 'o' (yes) or 'n' (no) or press Enter to automatically select 'no'." -ForegroundColor Yellow
            }
        }
    } while ($true)
}#>

function Import-SelectedVideos {
    param (
        [Parameter(Mandatory = $true)]
        [string]$DeviceId,
        
        [Parameter(Mandatory = $true)]
        [array]$Videos,
        
        [Parameter(Mandatory = $true)]
        [string]$TargetPath
    )

    if (-not (Test-Path $TargetPath)) {
        if (-not $AllAnswersTrue) {
            $confirmCreate = Read-Host "Target directory does not exist. Create it? (Press Enter to confirm, any other key to abort)"
            if ($confirmCreate -ne "") {
                Write-Host "Operation aborted by user." -ForegroundColor Yellow
                return
            }
        }
        New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
    }

    # Confirmation before starting import
    if (-not $AllAnswersTrue) {
        Write-Host "`nPreparing to import $($Videos.Count) videos to $TargetPath" -ForegroundColor Cyan
        $confirmImport = Read-Host "Start import process? (Press Enter to confirm, any other key to abort)"
        if ($confirmImport -ne "") {
            Write-Host "Operation aborted by user." -ForegroundColor Yellow
            return
        }
    }

    $totalVideos = $Videos.Count
    $currentVideo = 0

    # Sort videos by filename
    $sortedVideos = $Videos | Sort-Object { $_.Name }

    foreach ($video in $sortedVideos) {
        $currentVideo++
        $progress = [math]::Round(($currentVideo / $totalVideos) * 100)
        Write-Progress -Activity "Importing Videos" -Status "Copying $($video.Name)" -PercentComplete $progress

        try {
            if (-not $WhatIf) {
                adb -s $DeviceId pull "$($video.FullPath)" "$TargetPath" | Out-Null
            } else {
                Write-Host "WhatIf: Imported $($video.Name) to $TargetPath" -ForegroundColor Yellow
            }
            if ($LASTEXITCODE -ne 0) {
                throw "ADB pull command failed with exit code $LASTEXITCODE"
            }
        }
        catch {
            Write-Host "Error copying $($video.Name): $_" -ForegroundColor Red
        }
    }
    Write-Progress -Activity "Importing Videos" -Completed
}
