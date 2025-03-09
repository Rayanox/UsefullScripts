Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Convert-TimeToSeconds ($timeString) {
    # Expression régulière pour extraire les heures et les minutes
    $regex = '(?i)(?:(\d+)\s*h(?:eure|r)?)?\s*(?:(\d+)\s*min(?:ute|s)?)?'

    if ($timeString -match $regex) {
        $heures = [int]$Matches[1]
        $minutes = [int]$Matches[2]

        # Calcul des secondes
        $secondes = 0
        if ($heures) {
            $secondes += $heures * 3600
        }
        if ($minutes) {
            $secondes += $minutes * 60
        }

        return $secondes
    } else {
        return $null # Retourne $null si le format n'est pas reconnu
    }
}

$form = New-Object System.Windows.Forms.Form
$form.Text = "Hibernation"
$form.Size = New-Object System.Drawing.Size(600, 300)
$form.StartPosition = "CenterScreen"
$form.BackColor = [System.Drawing.Color]::LightSteelBlue

# ComboBox
$comboBox = New-Object System.Windows.Forms.ComboBox
$comboBox.Location = New-Object System.Drawing.Point(30, 30)
$comboBox.Size = New-Object System.Drawing.Size(120, 25)
$comboBox.Items.AddRange(@("20 min", "30 min", "35 min", "45 min", "55 min", "65 min", "1h 15min", "1h 30min", "2h"))
$form.Controls.Add($comboBox)

# Boutons
$startButton = New-Object System.Windows.Forms.Button
$startButton.Location = New-Object System.Drawing.Point(160, 30)
$startButton.Size = New-Object System.Drawing.Size(120, 30)
$startButton.Text = "Démarrer"
$startButton.BackColor = [System.Drawing.Color]::LightGreen
$form.Controls.Add($startButton)

$stopButton = New-Object System.Windows.Forms.Button
$stopButton.Location = New-Object System.Drawing.Point(290, 30)
$stopButton.Size = New-Object System.Drawing.Size(80, 30)
$stopButton.Text = "Stop"
$stopButton.BackColor = [System.Drawing.Color]::LightCoral
$stopButton.Enabled = $false
$form.Controls.Add($stopButton)

# Labels
$timerLabel = New-Object System.Windows.Forms.Label
$timerLabel.Location = New-Object System.Drawing.Point(30, 80)
$timerLabel.Size = New-Object System.Drawing.Size(450, 30)
$timerLabel.Font = New-Object System.Drawing.Font("Arial", 14, [System.Drawing.FontStyle]::Bold)
$form.Controls.Add($timerLabel)

$endTimeLabel = New-Object System.Windows.Forms.Label
$endTimeLabel.Location = New-Object System.Drawing.Point(30, 120)
$endTimeLabel.Size = New-Object System.Drawing.Size(250, 30)
$endTimeLabel.Font = New-Object System.Drawing.Font("Arial", 12)
$form.Controls.Add($endTimeLabel)

# Timer avec portée globale
$global:timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 1000
$global:remainingSeconds = 0
$global:endTime = $null
$global:stopRequested = $false

# Fonction de formatage du temps
function Format-TimeRemaining {
    param([int]$seconds)
    
    $hours = [math]::Floor($seconds / 3600)
    $minutes = [math]::Floor(($seconds % 3600) / 60)
    $seconds = $seconds % 60
    
    $parts = @()
    
    if($hours -gt 0) { $parts += "${hours}h" }
    if($minutes -gt 0) { $parts += "${minutes}min" }
    if($seconds -ge 0 -or $parts.Count -eq 0) { $parts += "${seconds}s" }
    
    return $parts -join ' '
}

# Événement Timer
$timer.Add_Tick({
    $global:remainingSeconds--
    
    if ($global:remainingSeconds -le 0 -or $global:stopRequested) {
        $timer.Stop()
        $startButton.Enabled = $true
        $stopButton.Enabled = $false
        $global:stopRequested = $false
		if($global:remainingSeconds -le 0 ) {
			R-Hibernate -MinutesToWait 0
		}
        return
    }
    
    # Mise à jour dynamique avec formatage personnalisé
    $timerLabel.Text = "Temps restant : $(Format-TimeRemaining $global:remainingSeconds)"
    $endTimeLabel.Text = "Fin à : $($global:endTime.ToString('HH:mm:ss'))"
})

# Gestionnaires d'événements
$startButton.Add_Click({
    if ($comboBox.SelectedItem) {
        $global:remainingSeconds = [int] (Convert-TimeToSeconds($comboBox.SelectedItem))
        $global:endTime = (Get-Date).AddSeconds($global:remainingSeconds)
        $global:stopRequested = $false
        
        $timerLabel.Text = "Temps restant : $(Format-TimeRemaining $global:remainingSeconds)"
        $endTimeLabel.Text = "Fin à : $($global:endTime.ToString('HH:mm:ss'))"
        
        $startButton.Enabled = $false
        $stopButton.Enabled = $true
        $timer.Start()
    }
    else {
        [System.Windows.Forms.MessageBox]::Show("Sélectionnez une durée")
    }
})

$stopButton.Add_Click({
    $global:stopRequested = $true
    $timerLabel.Text = "Arrêté par l'utilisateur"
    $endTimeLabel.Text = "Opération annulée"
})

# Afficher le formulaire
$form.Add_Shown({$form.Activate()})
[void]$form.ShowDialog()