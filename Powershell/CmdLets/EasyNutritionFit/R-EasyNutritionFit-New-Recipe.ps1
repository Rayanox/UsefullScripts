function R-EasyNutritionFit-New-Recipe {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, HelpMessage = "Path to the workspace directory. If not provided, a temporary directory will be used.")]
        [string]$PathWorkspace,

        [Parameter(Mandatory = $false, HelpMessage = "Path to the directory containing video files to import into the workspace.")]
        [string]$PathImport,

        [Parameter(Mandatory = $true, HelpMessage = "The name of the recipe, used to generate the final video filename.")]
        [string]$RecipeName,

        [Parameter(Mandatory = $false, HelpMessage = "If set, all confirmation prompts will be automatically accepted.")]
        [switch]$ForceAnswersTrue = $false,

        [Parameter(Mandatory = $false, HelpMessage = "Operation mode: VIDEO_COMPOSE_ONLY to only create the video, UPLOAD_ONLY to only upload an existing video.")]
        [ValidateSet("VIDEO_COMPOSE_ONLY", "UPLOAD_ONLY", "3_CONFIGURE_VIDEO_DIRECTLY", "ANY")]
        [string]$Mode = "ANY",

        [Parameter(Mandatory = $false, HelpMessage = "If set, the videos import process will be skipped.")]
        [switch]$SkipImport = $false,

        [Parameter(Mandatory = $false, HelpMessage = "The name of the recipe, used to generate the final video filename.")]
        [string]$YoutubeVideoIdToConfigure
    )

    #   ██████╗ ██████╗ ███╗   ██╗███████╗████████╗ █████╗ ███╗   ██╗████████╗███████╗███████╗
    #  ██╔════╝██╔═══██╗████╗  ██║██╔════╝╚══██╔══╝██╔══██╗████╗  ██║╚══██╔══╝██╔════╝██╔════╝
    #  ██║     ██║   ██║██╔██╗ ██║███████╗   ██║   ███████║██╔██╗ ██║   ██║   █████╗  ███████╗
    #  ██║     ██║   ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║╚██╗██║   ██║   ██╔══╝  ╚════██║
    #  ╚██████╗╚██████╔╝██║ ╚████║███████║   ██║   ██║  ██║██║ ╚████║   ██║   ███████╗███████║
    #   ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚══════╝

    
    $PATH_DEFAULT_WORKSPACE = "$env:TEMP\EasyNutritionFit-Workspace_" + [guid]::NewGuid().ToString().Substring(0, 8)
    
    
    #  ███╗   ███╗ █████╗ ██╗███╗   ██╗
    #  ████╗ ████║██╔══██╗██║████╗  ██║
    #  ██╔████╔██║███████║██║██╔██╗ ██║
    #  ██║╚██╔╝██║██╔══██║██║██║╚██╗██║
    #  ██║ ╚═╝ ██║██║  ██║██║██║ ╚████║
    #  ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝
    
  
    if ($Mode -eq "3_CONFIGURE_VIDEO_DIRECTLY") {
        if (-not $YoutubeVideoIdToConfigure) {
            Write-Host "YoutubeVideoIdToConfigure is required when using the 3_CONFIGURE_VIDEO_DIRECTLY mode." -ForegroundColor Red
            return
        }
        _Step-3-Configure-Recipe-And-Finish -VideoId $YoutubeVideoIdToConfigure -RecipeName $RecipeName
        return
    }

    $PathWorkspace = Test-Directories

    $importSuccess = _Step-1-Import-Videos-Parts -TargetImportPath $PathWorkspace
    if (-not $importSuccess) {
        Write-Host "Failed to import videos. Exiting..." -ForegroundColor Red
        return
    }
    

    
    # Step 2: Aggregate, create and upload the video
    $videoId = _Step-2-Aggregate-Create-And-Upload-Video -PathWorkspace $PathWorkspace -PathImport $PathImport -RecipeName $RecipeName -ForceAnswersTrue:$ForceAnswersTrue -Mode $Mode

    # If we are in VIDEO_COMPOSE_ONLY mode, we stop here
    if ($Mode -eq "VIDEO_COMPOSE_ONLY") {
        return
    }

    # If we don't have a video ID, it's an error
    if ($null -eq $videoId) {
        throw "Failed to upload video to YouTube"
    }

    # Step 3: Configure the recipe
    _Step-3-Configure-Recipe-And-Finish -VideoId $videoId -RecipeName $RecipeName

    
}


# ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
# ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
# █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
# ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
# ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚█████╔╝██║ ╚████║███████║
# ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝

function _Step-1-Import-Videos-Parts {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TargetImportPath
    )

    if ($SkipImport -or ($Mode -eq "UPLOAD_ONLY")) {
        return $true
    }

    Write-Host "Starting videos import..." -ForegroundColor Cyan

    if ($ForceAnswersTrue) {
        $importSuccess = R-EasyNutritionFit-Import-Videos-Parts -TargetImportPath $PathWorkspace -AllAnswersTrue
    }
    else {
        $importSuccess = R-EasyNutritionFit-Import-Videos-Parts -TargetImportPath $PathWorkspace
    }

    if (-not $importSuccess) {
        Write-Host "Failed to import videos. Exiting..." -ForegroundColor Red
        return $false
    }

    return $true
}

function _Step-2-Aggregate-Create-And-Upload-Video {
    param (
        [Parameter(Mandatory = $true)]
        [string]$PathWorkspace,
        [Parameter(Mandatory = $true)]
        [string]$PathImport,
        [Parameter(Mandatory = $true)]
        [string]$RecipeName,
        [Parameter(Mandatory = $true)]
        [switch]$ForceAnswersTrue,
        [Parameter(Mandatory = $true)]
        [string]$Mode
    )

    Write-Host "Starting video aggregation and upload process..." -ForegroundColor Blue
        
    $videoId = R-EasyNutritionFit-Compose-Video `
        -PathWorkspace $PathWorkspace `
        -PathImport $PathImport `
        -RecipeName $RecipeName `
        -ForceAnswersTrue:$ForceAnswersTrue `
        -Mode $Mode

    Write-Host "Video aggregation and upload process completed successfully!" -ForegroundColor Green

    return $videoId
}

function _Step-3-Configure-Recipe-And-Finish {
    param (
        [Parameter(Mandatory = $true)]
        [string]$videoId,
        [Parameter(Mandatory = $true)]
        [string]$RecipeName
    )

    Write-Host "Starting recipe configuration process..." -ForegroundColor Cyan
        
    $youtubeUrl = "https://youtu.be/$videoId"
    R-EasyNutritionFit-Configure-Recipe -youtubeUrl $youtubeUrl -RecipeName $RecipeName

    Write-Host "Recipe creation process completed successfully!" -ForegroundColor Green

}

function Test-Directories {
    # Initialize workspace path if not provided
    if (-not $PathWorkspace) {
        $PathWorkspace = $PATH_DEFAULT_WORKSPACE
        if (-not (Test-Path $PathWorkspace)) {
            New-Item -ItemType Directory -Path $PathWorkspace | Out-Null
        }
    }
    <#if (-not (Test-Path $CONFIG_DIR)) {
        New-Item -ItemType Directory -Path $CONFIG_DIR | Out-Null
    }#>

    Write-Host "Using workspace: $PathWorkspace" -ForegroundColor Cyan
    return $PathWorkspace
}