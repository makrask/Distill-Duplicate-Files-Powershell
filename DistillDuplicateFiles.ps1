# Φόρτωση της βιβλιοθήκης Windows Forms
Add-Type -AssemblyName System.Windows.Forms

# Συνάρτηση για επιλογή φακέλου μέσω διαλόγου
function Select-FolderDialog {
    [CmdletBinding()]
    param(
        [string]$Description = "Select Folder",
        [string]$SelectedPath = "C:\"
    )
    $folderBrowser = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderBrowser.Description = $Description
	$folderBrowser.SelectedPath = $SelectedPath
    $folderBrowser.ShowNewFolderButton = $true
    if ($folderBrowser.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $folderBrowser.SelectedPath
    } else {
        Write-Error "You didn't select folder, I quit."
        exit
    }
}

# Επιλογή φακέλων μέσω διαλόγου
$AssortedFolder = Select-FolderDialog -Description "Select Assorted Folder - files to check and clean" -SelectedPath "C:\Distiller\Assorted"
$MainFolder = Select-FolderDialog -Description "Select Main Folder" -SelectedPath "C:\Distiller\MainFolder"
$BinFolder = Select-FolderDialog -Description "Select Recycle Bin Folder" -SelectedPath "C:\Distiller\Bin"

# Ορισμός αρχείου log
$LogFile = "$PSScriptRoot\move-log.txt"

# Εξασφάλιση ύπαρξης του φακέλου προορισμού
if (!(Test-Path $BinFolder)) {
    New-Item -ItemType Directory -Path $BinFolder | Out-Null
}

# Δημιουργία του αρχείου log αν δεν υπάρχει
if (!(Test-Path $LogFile)) {
    New-Item -ItemType File -Path $LogFile -Force | Out-Null
}

# Συνάρτηση για καταγραφή μηνυμάτων στο log file με χρονική σήμανση
function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $LogFile -Value "$timestamp - $Message"
}

# Συνάρτηση για τη διαγραφή άδειων φακέλων
function Remove-EmptyFolders {
    param (
        [string]$FolderPath
    )
    
    # Εύρεση όλων των υποφακέλων
    $Subfolders = Get-ChildItem -Path $FolderPath -Directory
    
    foreach ($Subfolder in $Subfolders) {
        # Αναδρομή για να ελεγχθούν και οι υποφάκελοι
        Remove-EmptyFolders -FolderPath $Subfolder.FullName
        
        # Έλεγχος αν ο φάκελος είναι άδειος
        if (-not (Get-ChildItem -Path $Subfolder.FullName -Recurse)) {
            # Διαγραφή του άδειου φακέλου
            Remove-Item -Path $Subfolder.FullName -Force
#            Write-Host "Empty folder deleted: $($Subfolder.FullName)"
			Write-Log -Message "Empty folder deleted: $($Subfolder.FullName)"
        }
    }
}

# Λήψη όλων των αρχείων από τον πηγαίο φάκελο με αναδρομή
$AssortedFiles = Get-ChildItem -Path $AssortedFolder -Recurse -File

foreach ($file in $AssortedFiles) {
    $foundMatch = $false
    $fileSize = $file.Length

    # Αναζήτηση στο CompareFolder για αρχεία με ίδιο μέγεθος
    $potentialMatches = Get-ChildItem -Path $MainFolder -Recurse -File | Where-Object { $_.Length -eq $fileSize }

    if ($potentialMatches.Count -gt 0) {
        # Υπολογισμός hash του αρχείου-στόχου (SHA256)
        $assortedFileHash = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash
        
        foreach ($cmp in $potentialMatches) {
            $cmpHash = (Get-FileHash -Path $cmp.FullName -Algorithm SHA256).Hash
            if ($assortedFileHash -eq $cmpHash) {
                $foundMatch = $true
                break  # Βρέθηκε ισοδύναμο αρχείο
            }
        }
    }

    if ($foundMatch) {
        # Υπολογισμός της σχετικής διαδρομής του αρχείου ως προς τον πηγαίο φάκελο
        $relativePath = $file.DirectoryName.Substring($AssortedFolder.Length)
        
        # Αφαίρεση του αρχικού "\" αν υπάρχει
        if ($relativePath.StartsWith("\")) {
            $relativePath = $relativePath.Substring(1)
        }
        
        # Δημιουργία της διαδρομής στον φάκελο προορισμού που διατηρεί τη δομή του αρχικού φακέλου
        $newDir = Join-Path -Path $BinFolder -ChildPath $relativePath
        
        # Δημιουργία του φακέλου προορισμού αν δεν υπάρχει
        if (!(Test-Path $newDir)) {
            New-Item -Path $newDir -ItemType Directory -Force | Out-Null
        }
        
        # Μεταφορά του αρχείου στον νέο φάκελο
        Move-Item -Path $file.FullName -Destination $newDir -Force

#το παρακάτω διαγράφει μόνο τον τελευταίο φάκελο αν είναι άδειος, δεν θέλω να τσεκάρω τον πιο πάνω για να μην σβήσω κατά λάθος κάτι που δεν πρέπει		
		# Έλεγχος αν ο φάκελος είναι άδειος
#		if (-not (Get-ChildItem -Path $file.DirectoryName)) {
#			# Διαγραφή του φακέλου
#			Remove-Item -Path $file.DirectoryName -Force
#			Write-Host "Folder [$($file.DirectoryName)] deleted!"
#		} 
        
        $message = "Moved: $($file.FullName) --> $newDir"
#        Write-Output $message
        Write-Log -Message $message
    }
}


# Διαγραφή άδειων υποφακέλων
Remove-EmptyFolders -FolderPath $AssortedFolder