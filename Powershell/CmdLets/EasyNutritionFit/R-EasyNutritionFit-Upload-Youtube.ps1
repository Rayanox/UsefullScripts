function R-EasyNutritionFit-Upload-Youtube {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, HelpMessage = "Path to the video to upload")]
        [string]$VideoPath,

        [Parameter(Mandatory = $true, HelpMessage = "Video title")]
        [string]$Title,

        [Parameter(Mandatory = $false, HelpMessage = "Video description")]
        [string]$Description = "",

        [Parameter(Mandatory = $false, HelpMessage = "Video tags")]
        [string[]]$Tags = @(),

        [Parameter(Mandatory = $true, HelpMessage = "Privacy level (private, unlisted, public)")]
        [ValidateSet("private", "unlisted", "public")]
        [string]$PrivacyStatus
    )


    #   ██████╗ ██████╗ ███╗   ██╗███████╗████████╗ █████╗ ███╗   ██╗████████╗███████╗███████╗
    #  ██╔════╝██╔═══██╗████╗  ██║██╔════╝╚══██╔══╝██╔══██╗████╗  ██║╚══██╔══╝██╔════╝██╔════╝
    #  ██║     ██║   ██║██╔██╗ ██║███████╗   ██║   ███████║██╔██╗ ██║   ██║   █████╗  ███████╗
    #  ██║     ██║   ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║╚██╗██║   ██║   ██╔══╝  ╚════██║
    #  ╚██████╗╚██████╔╝██║ ╚████║███████║   ██║   ██║  ██║██║ ╚████║   ██║   ███████╗███████║
    #   ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚══════╝

    
    
    $YOUTUBE_UPLOAD_SCOPE = "https://www.googleapis.com/auth/youtube.upload"
    $YOUTUBE_API_ENDPOINT = "https://www.googleapis.com/upload/youtube/v3/videos"
    $OAUTH_TOKEN_ENDPOINT = "https://oauth2.googleapis.com/token"
    $CREDENTIALS_PATH = "$env:LOCALAPPDATA\EasyNutritionFit\youtube-credentials.json"


    
    # ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
    # ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
    # █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
    # ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
    # ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚█████╔╝██║ ╚████║███████║
    # ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝


    
    function Import-YoutubeCredentials {
        $downloadPath = [System.IO.Path]::Combine($env:USERPROFILE, "Downloads")
        $credentialsFolder = [System.IO.Path]::GetDirectoryName($CREDENTIALS_PATH)

        # Check if credentials folder exists, create if not
        if (-not (Test-Path $credentialsFolder)) {
            New-Item -ItemType Directory -Path $credentialsFolder -Force | Out-Null
        }

        # If credentials don't exist
        if (-not (Test-Path $CREDENTIALS_PATH)) {
            Write-Host "No credentials file found." -ForegroundColor Yellow
            Write-Host "1. Go to https://console.cloud.google.com/" -ForegroundColor Cyan
            Write-Host "2. Create a project and enable YouTube Data v3 API" -ForegroundColor Cyan
            Write-Host "3. In 'Credentials', create an OAuth 2.0 Client ID" -ForegroundColor Cyan
            Write-Host "4. Download the JSON credentials file" -ForegroundColor Cyan
            Write-Host "5. Place the file in your Downloads folder" -ForegroundColor Cyan
            
            # Wait for user to download the file
            do {
                Start-Sleep -Seconds 2
                $credentialFile = Get-ChildItem -Path $downloadPath -Filter "client_secret*.json" | 
                    Where-Object { $_.CreationTime.Date -eq (Get-Date).Date } |
                    Sort-Object CreationTime -Descending |
                    Select-Object -First 1
            } while (-not $credentialFile)

            # Copy file to final location
            Copy-Item -Path $credentialFile.FullName -Destination $CREDENTIALS_PATH -Force
            Write-Host "Credentials imported successfully!" -ForegroundColor Green
        }
    }

    function Get-OAuth2Token {
        param (
            [string]$CredentialsPath
        )

        # Ensure credentials are available
        Import-YoutubeCredentials

        # Read credentials
        $credentials = Get-Content $CredentialsPath | ConvertFrom-Json
        
        # If no refresh token stored, start authentication flow
        if (-not $credentials.refresh_token) {
            $authUrl = "https://accounts.google.com/o/oauth2/v2/auth?" + 
                "client_id=$($credentials.installed.client_id)" +
                "&redirect_uri=urn:ietf:wg:oauth:2.0:oob" +
                "&scope=$YOUTUBE_UPLOAD_SCOPE" +
                "&response_type=code" +
                "&access_type=offline"

            Write-Host "Please visit this URL to authorize the application:" -ForegroundColor Yellow
            Write-Host $authUrl -ForegroundColor Cyan
            $authCode = Read-Host "Enter the authorization code"

            # Exchange code for token
            $tokenParams = @{
                code = $authCode
                client_id = $credentials.installed.client_id
                client_secret = $credentials.installed.client_secret
                redirect_uri = "urn:ietf:wg:oauth:2.0:oob"
                grant_type = "authorization_code"
            }

            $tokenResponse = Invoke-RestMethod -Uri $OAUTH_TOKEN_ENDPOINT -Method Post -Body $tokenParams
            
            # Save refresh token
            $credentials | Add-Member -NotePropertyName refresh_token -NotePropertyValue $tokenResponse.refresh_token
            $credentials | ConvertTo-Json | Set-Content $CredentialsPath
            
            return $tokenResponse.access_token
        }
        
        # Use existing refresh token
        $refreshParams = @{
            refresh_token = $credentials.refresh_token
            client_id = $credentials.installed.client_id
            client_secret = $credentials.installed.client_secret
            grant_type = "refresh_token"
        }

        $tokenResponse = Invoke-RestMethod -Uri $OAUTH_TOKEN_ENDPOINT -Method Post -Body $refreshParams
        return $tokenResponse.access_token
    }

    function Initialize-YoutubeUpload {
        param (
            [string]$AccessToken,
            [string]$Title,
            [string]$Description,
            [string[]]$Tags,
            [string]$PrivacyStatus
        )

        $videoMetadata = @{
            snippet = @{
                title = $Title
                description = $Description
                tags = $Tags
            }
            status = @{
                privacyStatus = $PrivacyStatus
                selfDeclaredMadeForKids = $false
            }
        }

        $headers = @{
            "Authorization" = "Bearer $AccessToken"
            "Content-Type" = "application/json"
        }

        $uploadParams = @{
            part = "snippet,status"
            uploadType = "resumable"
        }

        $uploadUrl = "$YOUTUBE_API_ENDPOINT`?" + 
            (($uploadParams.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "&")

        try {
            $response = Invoke-WebRequest -Uri $uploadUrl -Method Post -Headers $headers -Body ($videoMetadata | ConvertTo-Json -Depth 10)
            $uploadLocation = $response.Headers['Location']
            
            if (-not $uploadLocation) {
                throw "Impossible to retrieve the upload URL"
            }

            Write-Host "Video created in Youtube Studio, now need to import video binaries..." -ForegroundColor Green
            Write-Host "Upload URL: $uploadLocation" -ForegroundColor Cyan

            return $uploadLocation
        }
        catch {
            Write-Host "Upload initialization error: $_" -ForegroundColor Red
            throw $_
        }
    }

    function Upload-VideoToYoutube {
        param (
            [string]$UploadLocation,
            [string]$VideoPath,
            [string]$AccessToken
        )

        try {
            $headers = @{
                "Authorization" = "Bearer $AccessToken"
                "Content-Type" = "video/*"
            }

            $videoBytes = [System.IO.File]::ReadAllBytes($VideoPath)
            Write-Host "Uploading video to YouTube... Estimation time: $(New-EstimationTimeString -VideoSize $videoBytes.Length) seconds" -ForegroundColor Cyan
            $response = Invoke-WebRequest -Uri $UploadLocation -Method Put -Headers $headers -Body $videoBytes

            if ($response.StatusCode -ne 200) {
                throw "Error during video upload. Code: $($response.StatusCode)"
            }
            
            return $response.Content | ConvertFrom-Json
        }
        catch {
            Write-Host "Error during video upload: $_" -ForegroundColor Red
            throw $_
        }
    }

    function New-EstimationTimeString {
        param (
            [int]$VideoSize
        )

        $downloadSpeeds = @(1, 10, 20, 30)

        $estimationsInSeconds = $downloadSpeeds | ForEach-Object {
            $videoSizeInMo = $VideoSize / 1024 / 1024
            $estimationTimeInSeconds = $videoSizeInMo / $_
            return " - $estimationTimeInSeconds seconds"
        }

        return "\n\n" + $estimationsInSeconds.join("\n") + "\n"
    }   

    function Show-UploadSuccess {
        param (
            [object]$Response
        )

        Write-Host "Video uploaded successfully!" -ForegroundColor Green
        Write-Host "Video ID: $($Response.id)" -ForegroundColor Cyan
        Write-Host "Title: $($Response.snippet.title)" -ForegroundColor Cyan
        Write-Host "Status: $($Response.status.privacyStatus)" -ForegroundColor Cyan
    }

    
    #  ███╗   ███╗ █████╗ ██╗███╗   ██╗
    #  ████╗ ████║██╔══██╗██║████╗  ██║
    #  ██╔████╔██║███████║██║██╔██╗ ██║
    #  ██║╚██╔╝██║██╔══██║██║██║╚██╗██║
    #  ██║ ╚═╝ ██║██║  ██║██║██║ ╚████║
    #  ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝
    

    
    

    try {
        # Check video file
        if (-not (Test-Path $VideoPath)) {
            throw "The video file does not exist: $VideoPath"
        }

        # Get token
        $accessToken = Get-OAuth2Token -CredentialsPath $CREDENTIALS_PATH
        
        # Initialize upload
        Write-Host "Upload initialization..." -ForegroundColor Yellow
        $uploadLocation = Initialize-YoutubeUpload -AccessToken $accessToken -Title $Title -Description $Description -Tags $Tags -PrivacyStatus $PrivacyStatus

        # Upload video
        Write-Host "Starting of the video upload..." -ForegroundColor Yellow
        $response = Upload-VideoToYoutube -UploadLocation $uploadLocation -VideoPath $VideoPath -AccessToken $accessToken

        # Show result
        Show-UploadSuccess -Response $response

        return $response.id
    }
    catch {
        Write-Host "Error during video upload: $_" -ForegroundColor Red
        throw $_
    }
}
