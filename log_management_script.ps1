# Parameters
$logDir = "C:\Logs"
$archiveDir = "C:\ArchivedLogs"
$ageInDays = 30
$compressionFormat = "zip"
$logFile = "C:\log_management_script.log"

# Function to log messages
function Log-Message {
    param (
        [string]$message,
        [string]$type = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$type] $message"
    Add-Content -Path $logFile -Value $logEntry
}

# Calculate the cutoff date
$cutoffDate = (Get-Date).AddDays(-$ageInDays)

# Ensure the archive directory exists
if (-not (Test-Path -Path $archiveDir)) {
    try {
        New-Item -ItemType Directory -Path $archiveDir -ErrorAction Stop
        Log-Message "Created archive directory at $archiveDir."
    } catch {
        Log-Message "Failed to create archive directory at $archiveDir. Error: $_" "ERROR"
        exit 1
    }
}

# Get files older than the cutoff date
try {
    $oldFiles = Get-ChildItem -Path $logDir -File | Where-Object { $_.LastWriteTime -lt $cutoffDate }
    Log-Message "Found $($oldFiles.Count) files older than $ageInDays days."
} catch {
    Log-Message "Failed to retrieve files from $logDir. Error: $_" "ERROR"
    exit 1
}

foreach ($file in $oldFiles) {
    try {
        # Define the archive path
        $archivePath = Join-Path -Path $archiveDir -ChildPath ($file.Name + ".zip")
        
        # Compress the file
        Compress-Archive -Path $file.FullName -DestinationPath $archivePath -ErrorAction Stop
        Log-Message "Compressed $($file.FullName) to $archivePath."

        # Delete the original file
        Remove-Item -Path $file.FullName -ErrorAction Stop
        Log-Message "Deleted original file $($file.FullName)."

    } catch {
        Log-Message "Failed to process file $($file.FullName). Error: $_" "ERROR"
    }
}

Log-Message "Log file management completed."
