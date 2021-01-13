New-Item -ItemType directory -Path C:\dsinfo | Out-Null
New-Item -ItemType directory -Path C:\dsinfo\inspect | Out-Null
New-Item -ItemType directory -Path C:\dsinfo\logs | Out-Null
New-Item -ItemType directory -Path C:\dsinfo\eventlogs | Out-Null
New-Item -ItemType directory -Path C:\dsinfo\shimlogs | Out-Null
New-Item -ItemType directory -Path C:\dsinfo\storagelogs | Out-Null
New-Variable -Name 'SCRIPTLOG' -Scope 'Script' -Value 'C:\dsinfo\dsinfo.txt' -Option Constant
New-Variable -Name 'LOGLINES' -Scope 'Script' -Value 40000 -Option Constant

$defaultgateway = (netsh interface ipv4 show route | Select-String -Pattern "0.0.0.0/0" -List).Line.Split(' ')[-1]

$Env:PATH="$Env:PATH;c:\docker"

function append-ts {
    "[{0:MM/dd/yy} {0:HH:mm:ss}] $args" -f (Get-Date) | Add-Content $script:SCRIPTLOG
}

function append {
    echo "$args" | Add-Content $script:SCRIPTLOG
}

function append-no-newline {
    echo "$args" | Add-Content -NoNewline $script:SCRIPTLOG
}

function append-errors {
    echo "$args" | Add-Content C:\dsinfo\errors.txt
}

function bline {
    append ""
}

function header {
    append "========================="
    bline
    append $($args | Out-String)
    append "========================="
    bline
}

function execute {
    bline
    append-no-newline $($args | Out-String)
    append "========================="
    try {
        append-no-newline $(Invoke-Expression "& $args" | Out-String)
    } catch {
        append "Could not run command: $($_.Exception)"
    }
}

# This function is used to copy the event log files, which are mounted by the
# host system and thus frequently locked when we try to copy them. This function
# uses system calls to read the files without locking. From
# http://stackoverflow.com/questions/34627593/powershell-copy-a-file-or-get-the-content-without-lock-it
function Copy-ReadOnly
{
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [Parameter(Mandatory)]
        [string]$Destination
    )

    # Instantiate a buffer for the copy operation
    $Buffer = New-Object 'byte[]' 1024

    $SourceFile = [System.IO.File]::Open($Path,[System.IO.FileMode]::Open,[System.IO.FileAccess]::Read,[System.IO.FileShare]::ReadWrite)
    # Create the new file
    $DestinationFile = [System.IO.File]::Open($Destination,[System.IO.FileMode]::CreateNew)

    try{
        # Copy the contents of the source file to the destination
        while(($readLength = $SourceFile.Read($Buffer,0,$Buffer.Length)) -gt 0)
        {
            $DestinationFile.Write($Buffer,0,$readLength)
        }
    }
    catch{
        throw $_
    }
    finally{
        $SourceFile.Close()
        $DestinationFile.Close()
    }
}

header 'Docker/System Information'
append-no-newline $(date | Out-String)
append-no-newline $([Environment]::OSVersion | Out-String)

execute "docker version"
execute "docker info"
execute "docker images --no-trunc"
execute "docker stats --all --no-stream"
append-ts "INFO: docker stats written"

header "daemon.json"
execute "cat C:\ProgramData\docker\config\daemon.json"
append-ts "INFO: Wrote daemon.json"

$ucpContainers = docker ps -a --filter name=ucp- --format "{{.Names}}"
ForEach ($container in $ucpContainers) {
    append-ts "INFO: Writing $container"
    try {
        docker logs --timestamps --tail $script:LOGLINES 2>&1 $container | Add-Content "C:\dsinfo\logs\$($container).log"
    } catch {
        append-errors "Could not run docker logs --timestamps --tail $($script:LOGLINES) 2>&1 $($container): $($_.Exception)"
    }
    try {
        docker inspect $container | Add-Content "C:\dsinfo\inspect\$($container).txt"
    } catch {
        append-errors "Could not run docker inspect $($container): $($_.Exception)"
    }
    append-ts "INFO: Wrote $container"
}

# Copy containerd shim log
Copy-Item C:\Windows\Temp\ucp-* C:\dsinfo\shimlogs\
append-ts "INFO: Wrote containerd shim log"

$logNames = "Microsoft-Windows-Hyper-V-Compute-Admin",
            "Microsoft-Windows-Hyper-V-Compute-Operational",
            "Application",
            "Microsoft-Windows-Security-Netlogon%4Operational" # For MSA category events

$providerSet = New-Object System.Collections.Generic.HashSet[string]
$providerSet.add("Microsoft-Windows-Hyper-V-Compute")
$providerSet.add("Microsoft-Windows-Security-Netlogon")

$logStartTime = (Get-Date).AddHours(-24)
ForEach ($logName in $logNames) {
    try {
        append-ts "INFO: Writing $logName"
        if (-Not (Test-Path "C:\Windows\system32\winevt\logs\$($logName).evtx")) {
            append-ts "INFO: $logName does not exist"
            continue
        }

        # Copy the log in question to a new file because the host machine
        # probably still has this log in use, which prevents us from seeing its
        # contents.
        # Note here that we can use FilterHashtable to filter out the events by
        # date, but we need to use Where-Object to filter by provider because
        # FilterHashtable will not recognize our event provider names because
        # they don't exist in the dsinfo image.
        $events = Get-WinEvent -FilterHashtable @{Path="C:\Windows\system32\winevt\logs\$($logName).evtx"; StartTime=$logStartTime} -ErrorAction Ignore -MaxEvents $script:LOGLINES | select TimeCreated, ProviderName, @{n="Message";e={$_.properties.Value}} | Where-Object {$_.ProviderName -eq "docker" -or $_.ProviderName -like "kube*" -or $providerSet.contains($_.ProviderName)} | Sort-Object -Property TimeCreated
        $events | Export-CSV "C:\dsinfo\eventlogs\$($logName).csv"
        append-ts "INFO: Wrote $logName"
    } catch {
        append-errors "Could not get logs for $($logName): $($_.Exception)"
    }
}
