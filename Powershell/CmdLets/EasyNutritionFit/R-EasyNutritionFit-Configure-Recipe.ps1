
function R-EasyNutritionFit-Configure-Recipe {
	[CmdletBinding()]
	Param(
        [parameter(Mandatory=$true)]
		[string] $youtubeUrl,

        [parameter(Mandatory=$true)]
		[string] $RecipeName,

        [Parameter(Mandatory = $false, HelpMessage = "If set, all confirmation prompts will be automatically accepted.")]
        [switch]$ForceAnswersTrue = $false
        
	)


     ##############
    #             #
    #  Constants  #
    #             #
    ##############


    $N8N_HOST = "localhost"
    $N8N_PORT = 5678
    $N8N_URL = "${N8N_HOST}:$N8N_PORT"
    $N8N_WORKFLOW_PREPARE_RECIPE_URL = "http://$N8N_URL/webhook/4fc818ee-cdad-44e5-bc64-ce35121ff640"
    

     ##############
    #             #
    #  Functions  #
    #             #
    ############## 


    function isN8nRunning() {
        $testConnection = Test-NetConnection -ComputerName $N8N_HOST -Port $N8N_PORT
        return $testConnection.TcpTestSucceeded
    }

    function extractYoutubeId($youtubeUrl) {
        $patterns = @(
            'v=([-\w]{11})',       # Standard format
            'youtu\.be/([-\w]{11})', # Short format
            'embed/([-\w]{11})',    # Embedded format
            'v/([-\w]{11})'         # Old format
        )

        foreach ($pattern in $patterns) {
            if ($youtubeUrl -match $pattern) {
                return $matches[1]
            }
        }

        Write-Error "Youtube ID not found for url $youtubeUrl"
    }


     #########
    #        #
    #  Main  #
    #        #
    #########


    if(-not (isN8nRunning)) {
        Write-Error -Message "N8n is not running on $N8N_URL. Please start it before. Exiting."
        return
    }

    $youtubeId = extractYoutubeId -youtubeUrl $youtubeUrl

    try {

        if(-not $ForceAnswersTrue) {
            Write-Host -ForegroundColor Blue "Ready to configure the recipe. Press Enter to continue"
            $confirm = Read-Host
            if($confirm -ne "") {
                Write-Host -ForegroundColor Yellow "Operation aborted."
                return  
            }
        }

        Write-Host -ForegroundColor Green "Starting the recipe configuration process..."

        $n8nResponse = Invoke-WebRequest -Uri "${N8N_WORKFLOW_PREPARE_RECIPE_URL}?YoutubeId=$youtubeId&VideoName=$RecipeName"
        
        if($n8nResponse.StatusCode -ne 200) {
            Write-Error -Message "Received code doesn't equal 200. Exiting."
            return
        }

    } catch {
        Write-Error -Message "Error occurred when reaching N8N"
        throw $_
    }

    Write-Host -ForegroundColor Green "Recipe configuration process completed successfully!"

    $urlResult = $n8nResponse.Content

    try {
        chrome.exe $urlResult
    } catch {
        Write-Error -Message "An error occurred when trying to open chrome.exe, make sure it is accessible in the PATH"
        throw $_
    }

    Write-Host -ForegroundColor Green "Completed"
}