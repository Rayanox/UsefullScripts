
# Checker si N8n est lancé
# Appel du workflow avec gestion d'erreur si retour != 200
# Récupération de l'URL de configuration de la recette + ouverture de Chrome sur cette page
# Commiter le tout + documenter dans Notion et N8n de mon serveur (et copier le workflow local vers mon serveur)


function R-EasyNutritionFit-Configure-Recipe {
	[CmdletBinding()]
	Param(
        [parameter(Mandatory=$true)]
		[string] $youtubeUrl
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
            'v=([-\w]{11})',       # Format standard
            'youtu\.be/([-\w]{11})', # Format court
            'embed/([-\w]{11})',    # Format intégré
            'v/([-\w]{11})'         # Ancien format
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
        $n8nResponse = Invoke-WebRequest -Uri "${N8N_WORKFLOW_PREPARE_RECIPE_URL}?YoutubeId=$youtubeId"
        
        if($n8nResponse.StatusCode -ne 200) {
            Write-Error -Message "Received code doesn't equal 200. Exiting."
            return
        }

    } catch {
        Write-Error -Message "Error occured when reaching N8N"
        throw $_
    }

    
    $urlResult = $n8nResponse.Content

    try {
        chrome.exe $urlResult
    } catch {
        Write-Error -Message "An error occured when trying to open chrome.exe, make sure it is accessible in the PATH"
        throw $_
    }

    Write-Host -ForegroundColor Green "Completed"
}