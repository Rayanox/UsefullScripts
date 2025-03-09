param(
    [Parameter(Mandatory=$false)]
    [string] $patternToFilter,

    [Parameter(Mandatory=$false)]
    [switch] $NotOnlyNews = $false,

    [Parameter(Mandatory=$false)]
    [string] $DateGreatherThan,

    [Parameter(Mandatory=$false)]
    [switch] $DontInludeDate = $false
)

# Constants

$FILE_NEW_DATE = "~/.tmp/scripts/adb/logs-new-date.txt"
$EMPTY_PATTERN_KEY = "EMPTY_PATTERN_KEY"

# Functions

function createFileNewDateIfNeeded() {
    $absolutePath = $FILE_NEW_DATE.Replace("~", $env:USERPROFILE)

    if (-not (Test-Path -Path $absolutePath)) {

        $parentDirectory = Split-Path -Path $absolutePath -Parent
        if (-not (Test-Path -Path $parentDirectory)) {
            New-Item -ItemType Directory -Path $parentDirectory | Out-Null
        }

        New-Item -ItemType File -Path $absolutePath | Out-Null
        Write-Host "The file '$absolutePath' has been created."
    } else {
        Write-Debug "The file '$absolutePath' already exists."
    }
}

function getSavedDates() {
    $result = cat $FILE_NEW_DATE.Replace("~", $env:USERPROFILE) | ConvertFrom-Json
    if(-not $result) {
        return [PSCustomObject]@{}
    }
    return $result
}

function getLastNewDate($pattern) {
    if(-not $pattern) {
        return (getSavedDates).$EMPTY_PATTERN_KEY
    }else {
        return (getSavedDates).$pattern
    }
}

function saveNewDate($pattern) {
    $currentDate = Get-Date -Format "MM-dd HH:mm:ss.fff"

    $absolutePath = $FILE_NEW_DATE.Replace("~", $env:USERPROFILE)

    if(-not $pattern) {
        $savePattern = $EMPTY_PATTERN_KEY
    }else {
        $savePattern = $pattern
    }

    $savedDates = getSavedDates

    if($savedDates | Get-Member -Name "$savePattern") {
        $savedDates.$savePattern = $currentDate
    } else {
        $savedDates | Add-Member -MemberType NoteProperty -Name $savePattern -Value "$currentDate"
    }

    try {
        $savedDates | ConvertTo-Json | Out-File -FilePath $absolutePath -Encoding UTF8
        Write-Debug "The new date has been saved to '$absolutePath'."
    } catch {
        Write-Warning "Error writing to file '$absolutePath': $($_.Exception.Message)"
    }
}

function logCat($filter) {
    if($filter) {
        return adb logcat -d | Select-String "$filter"
    } else {
        return adb logcat -d
    }    
}

function Filter-LogcatByDate {
    param (
        [Parameter(Mandatory=$true)]
        [string[]]$LogcatLogs,

        [Parameter(Mandatory=$true)]
        [string]$ReferenceDate,

        [Parameter(Mandatory=$true)]
        [bool]$includeDate
    )

    $referenceDateTime = [datetime]::ParseExact($ReferenceDate, "MM-dd HH:mm:ss.fff", $null)
    $filteredLogs = @()

    foreach ($log in $LogcatLogs) {
        if ($log -match "^(\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})") {
            try {
                $logDateTime = [datetime]::ParseExact($matches[1], "MM-dd HH:mm:ss.fff", $null)
                if($includeDate) {
                    if ($logDateTime -ge $referenceDateTime) {
                        $filteredLogs += $log
                    }
                } else {
                    if ($logDateTime -gt $referenceDateTime) {
                        $filteredLogs += $log
                    }
                }
            } catch {
                # Ignore
            }
        }
    }

    return $filteredLogs
}

function Convert-Iso8601ToLogcatDate {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Iso8601Date
    )

    try {
        $dateTime = [datetime]::Parse($Iso8601Date)
        return $dateTime.ToString("MM-dd HH:mm:ss.fff")
    } catch {
        Write-Warning "Error: The ISO 8601 date provided is not valid"
        return $null
    }
}


# Main

$allLogs = logCat -filter $patternToFilter

if($DateGreatherThan) {
    $dateFilter = Convert-Iso8601ToLogcatDate -Iso8601Date $DateGreatherThan
    if(-not $dateFilter) {
        Write-Host -ForegroundColor Red "Date has not been properly converted. Fix your input with a correct ISO 8601 date format and retry"
        exit -1
    }
    Filter-LogcatByDate -LogcatLogs $allLogs -ReferenceDate $dateFilter -includeDate (-not $DontInludeDate)
} elseif (-not $NotOnlyNews){
    createFileNewDateIfNeeded
    $lastNewDate = getLastNewDate -pattern $patternToFilter
    if($lastNewDate) {
        Filter-LogcatByDate -LogcatLogs $allLogs -ReferenceDate $lastNewDate -includeDate (-not $DontInludeDate)
    } else {
        $allLogs
    }
    saveNewDate -pattern $patternToFilter
} else {
    $allLogs
}
