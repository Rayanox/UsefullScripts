# Functions

function extractScriptPathFromProfile($textLine) {
    if ($textLine -match '.\W+"([^"]+)"') {
        return $url = $matches[1]
    } else {
        return $null
    }
}

function installCmdlets() {
    Write-Host -ForegroundColor Yellow "Start install Cmdlets"
    $allCmdLetsFiles = [string[]] @(ls -Recurse -File -Filter "*.ps1" -Path .\CmdLets | % {$_.FullName})
    $alreadyInstalledCmdlets = [string[]] @(cat $PROFILE | % {extractScriptPathFromProfile -textLine $_}) | ?{$_}

    $pathsToInstall = [string[]] (Compare-Object -ReferenceObject $allCmdLetsFiles -DifferenceObject $alreadyInstalledCmdlets | Where-Object {$_.SideIndicator -eq "<="} | % {$_.InputObject})

    if($pathsToInstall) {
        $pathsToInstall | % { Add-Content -Path $PROFILE -Value ". `"$_`"" }

        Write-Host -ForegroundColor Green "Cmdlets installation finished"
        Write-Host -ForegroundColor DarkYellow "New paths of Cmdlets:"
        $pathsToInstall | %{ Write-Host -ForegroundColor Cyan $_ }
    } else {
        Write-Host -ForegroundColor Cyan "No new paths of Cmdlets to install, already up to date"
    }
    echo ""
}

function installScripts() {
    Write-Host -ForegroundColor Yellow "Start install Scripts"

    $scriptRootPath = [string[]] @(ls -Filter "Scripts" -Directory | Select-Object -First 1 | % { $_.FullName })
    $otherPaths = [string[]] @(ls -Recurse -Directory -Path .\Scripts| %{ $_.FullName } | ?{ (ls $_ -Filter "*.ps1").count -gt 0 })
    $allPaths = $scriptRootPath + $otherPaths

    $env:Path = [Environment]::GetEnvironmentVariable("Path", "User")
    $alreadyInstalledPaths = $env:Path -split ";" | ?{ $_ }

    $pathsToInstall = [string[]] (Compare-Object -ReferenceObject $allPaths -DifferenceObject $alreadyInstalledPaths | Where-Object {$_.SideIndicator -eq "<="} | % {$_.InputObject})

    if($pathsToInstall) {
        $pathsToInstall | %{ $env:Path="$env:Path;$_" }
        [Environment]::SetEnvironmentVariable("Path", $env:Path, "User")

        Write-Host -ForegroundColor Green "Scripts installation finished"
        Write-Host -ForegroundColor DarkYellow "New paths of Scripts:"
        $pathsToInstall | %{ Write-Host -ForegroundColor Cyan $_ }
    } else {
        Write-Host -ForegroundColor Cyan "No new paths of Scripts to install, already up to date"
    }
    echo ""
}

# Pre-requisites

if($profile -match "PowerShellISE_profile") {
    $profile = $profile -replace "PowerShellISE_profile","PowerShell_profile"
    Write-Host -ForegroundColor Yellow "Powershell ISE Profile detected, switching to simple Powershell Profile"
}


# Main

git pull
installScripts
installCmdlets