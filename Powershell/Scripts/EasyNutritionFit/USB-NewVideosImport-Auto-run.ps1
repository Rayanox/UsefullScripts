

# ███████╗██╗   ██╗███╗   ██╗ ██████╗████████╗██╗ ██████╗ ███╗   ██╗███████╗
# ██╔════╝██║   ██║████╗  ██║██╔════╝╚══██╔══╝██║██╔═══██╗████╗  ██║██╔════╝
# █████╗  ██║   ██║██╔██╗ ██║██║        ██║   ██║██║   ██║██╔██╗ ██║███████╗
# ██╔══╝  ██║   ██║██║╚██╗██║██║        ██║   ██║██║   ██║██║╚██╗██║╚════██║
# ██║     ╚██████╔╝██║ ╚████║╚██████╗   ██║   ██║╚█████╔╝██║ ╚████║███████║
# ╚═╝      ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝   ╚═╝   ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚══════╝



function Show-Banner {
    $banner = @"
         _______  ____   _______ 
        |   ____||    \ |   ____|
        |   |___ |     \|   |___ 
        |   ___| |      |   ___|
        |   |___ |  |\  |   |   
        |_______||__| \_|___|   
"@

    $subBanner = @"
           _________________
          |                 |
          |  IMPORT  TOOL   |
          |_________________|
"@

    Write-Host
    Write-Host $banner -ForegroundColor Green
    Write-Host $subBanner -ForegroundColor Cyan
    Write-Host "`n`n" -ForegroundColor Gray
}

function Get-RecipeName {
    $recipeName = $null
    
    while ([string]::IsNullOrWhiteSpace($recipeName)) {
        Write-Host "Please enter the recipe name: " -ForegroundColor Yellow -NoNewline
        $recipeName = Read-Host
        
        if ([string]::IsNullOrWhiteSpace($recipeName)) {
            Write-Host "Error: Recipe name cannot be empty!" -ForegroundColor Red
        }
    }
    
    return $recipeName
}

function Ask-AllAnswersTrue {
    $allAnswersTrue = $false
    $answer = $null

    while (-not $answer) {
        $answer = Read-Host "Do you want to answer all questions with true? (y/n)"
        if ($answer -eq "y") {
            $allAnswersTrue = $true
        } elseif ($answer -eq "n") {
            $allAnswersTrue = $false
        } else {
            Write-Host "Invalid input. Please enter 'y' or 'n'." -ForegroundColor Red
            $answer = $null
        }
    }
    return $allAnswersTrue
}


    # ███╗   ███╗ █████╗ ██╗███╗   ██╗
    # ████╗ ████║██╔══██╗██║████╗  ██║
    # ██╔████╔██║███████║██║██╔██╗ ██║
    # ██║╚██╔╝██║██╔══██║██║██║╚██╗██║
    # ██║ ╚═╝ ██║██║  ██║██║██║ ╚████║
    # ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝


	clear
    Show-Banner
    $recipeName = Get-RecipeName
    $allAnswersTrue = Ask-AllAnswersTrue
    #$PathWorkspace = "C:\Users\rayane.ben-hmidane-e\UsefullScripts\Powershell\CmdLets\EasyNutritionFit"
    $PathWorkspace = $null
    
    if ($allAnswersTrue) {
        R-EasyNutritionFit-New-Recipe -RecipeName "$recipeName" -PathWorkspace $PathWorkspace -ForceAnswersTrue
    } else {
        R-EasyNutritionFit-New-Recipe -RecipeName "$recipeName" -PathWorkspace $PathWorkspace
    }
    Write-Host "End of work !`n" -ForegroundColor Green

    Read-Host "`n`nPress Enter to exit...`n`n"
    
    




