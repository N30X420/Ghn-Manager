param (
    [switch]$RestartEndpoint,
    [string]$Mac,
    [switch]$RestartG42004C,
    [string]$Address,
    [string]$Username,
    [string]$Password
)

# Set error handling preference to stop on errors
$ErrorActionPreference = "Stop"

# Define program metadata
$version = "1.2"
$ProgramName = "G.hn-Manager"
$programdir = "C:\MATRIXNET\$ProgramName-$version"
$GithubRepo = "https://github.com/N30X420/Ghn-Manager"
$CurDate = Get-Date -Format "dd-MM-yyyy_HH-mm-ss"
$global:LogFilePath = "$programdir\$ProgramName-$version-$CurDate.log"

# Ensure the program directory exists
if (-Not (Test-Path $programdir)) { New-Item -ItemType Directory -Path $programdir }

# Load or create configuration file
$configFilePath = "$programdir\config.json"
if (-Not (Test-Path $configFilePath)) {
    $defaultConfig = @{
        Address = ""
        Username = ""
        Password = ""
    }
    $defaultConfig | ConvertTo-Json -Depth 1 | Set-Content -Path $configFilePath
    Write-Host "Configuration file created at $configFilePath with default values." -ForegroundColor Green
}
$config = Get-Content -Path $configFilePath | ConvertFrom-Json

# Use config values if arguments are not provided
if (-not $Address) { $Address = $config.Address }
if (-not $Username) { $Username = $config.Username }
if (-not $Password) { $Password = $config.Password }

# Clear the console screen
clear-host

# Initialize global variables for SSH session and stream
$global:sshSession = $null
$global:stream = $null

# Determine connection status and set corresponding status color
$ConnectionStatus = if ($sshSession.Connected -eq $true) { "Connected" } else { "Disconnected" }
$ConnectionStatusColor = if ($ConnectionStatus -eq "Connected") { "Green" } else { "Red" }

function SplashLogo {
write-host ""
write-host "███╗   ███╗ █████╗ ████████╗██████╗ ██╗██╗  ██╗" -ForegroundColor White -NoNewline
Write-host "███╗   ██╗███████╗████████╗" -ForegroundColor Red
write-host "████╗ ████║██╔══██╗╚══██╔══╝██╔══██╗██║╚██╗██╔╝" -ForegroundColor white -NoNewline
Write-Host "████╗  ██║██╔════╝╚══██╔══╝" -ForegroundColor Red
write-host "██╔████╔██║███████║   ██║   ██████╔╝██║ ╚███╔╝ " -ForegroundColor White -NoNewline
Write-Host "██╔██╗ ██║█████╗     ██║   " -ForegroundColor Red
write-host "██║╚██╔╝██║██╔══██║   ██║   ██╔══██╗██║ ██╔██╗ " -ForegroundColor White -NoNewline
Write-Host "██║╚██╗██║██╔══╝     ██║   " -ForegroundColor Red
write-host "██║ ╚═╝ ██║██║  ██║   ██║   ██║  ██║██║██╔╝ ██╗" -ForegroundColor White -NoNewline
write-host "██║ ╚████║███████╗   ██║   " -ForegroundColor Red
write-host "╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝" -ForegroundColor White -NoNewline
write-host "╚═╝  ╚═══╝╚══════╝   ╚═╝   " -ForegroundColor Red                                         

}

# Function to display the program logo and connection status
function Logo {
    Write-Host " "
    write-Host "   ____   _                     __  __ " -ForegroundColor Blue
    write-Host "  / ___| | |__  _ __           |  \/  | __ _ _ __   __ _  __ _  ___ _ __" -ForegroundColor Blue
    write-Host " | |  _  |  _ \|  _ \   _____  | |\/| |/ _  |  _ \ / _  |/ _  |/ _ \  __|" -ForegroundColor Blue
    write-Host " | |_| |_| | | | | | | |_____| | |  | | (_| | | | | (_| | (_| |  __/ |" -ForegroundColor Blue
    write-Host "  \____(_)_| |_|_| |_|         |_|  |_|\__,_|_| |_|\__,_|\__, |\___|_|" -ForegroundColor Blue
    write-Host "                                                        |___/" -ForegroundColor Blue
    write-Host "v$version " -ForegroundColor Blue -NoNewline
    Write-Host " $Script:NewVersionAvailable" -ForegroundColor Green
    Write-Host "`n$ConnectionStatus" -ForegroundColor $ConnectionStatusColor
}


# Function to clear the SSH stream buffer
function Clear-SSHStream {
    param([object]$stream)
    while ($stream.DataAvailable) { $null = $stream.Read() }
}



# Function to write logs to a file
function Write-Log {
    param ([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $global:LogFilePath -Value "[$timestamp] [$Level] $Message"
}
function Format-Hyperlink {
    param(
      [Parameter(ValueFromPipeline = $true, Position = 0)]
      [ValidateNotNullOrEmpty()]
      [Uri] $Uri,
  
      [Parameter(Mandatory=$false, Position = 1)]
      [string] $Label
    )
  
    if (($PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows) -and -not $Env:WT_SESSION) {
      # Fallback for Windows users not inside Windows Terminal
      if ($Label) {
        return "($Uri)"
      }
      return "$Uri"
    }
  
    if ($Label) {
      return "`e]8;;$Uri`e\$Label`e]8;;`e\"
    }
  
    return "$Uri"
}
function CheckForUpdates {
    try {
        $Releases = Invoke-RestMethod -Uri "https://api.github.com/repos/N30X420/Ghn-Manager/releases"
		$ReleaseInfo = ($Releases | Sort-Object id -desc)[0]
		$LatestVersion = [version[]]$ReleaseInfo.Name.Trim('v')
		if ($LatestVersion -gt $version){ $Script:NewVersionAvailable = "v$LatestVersion is available $(Format-Hyperlink -Uri "$GithubRepo" -Label "v$LatestVersion")"}
        else {
            Write-Host "You are running the latest version - " -ForegroundColor Green -NoNewline
            Write-Host "v$version" -ForegroundColor Blue
            Start-Sleep -Seconds 2}
    }
    catch {
        Write-Log $_.Exception.Message "ERROR"
        Write-Warning "Error while checking for updates"
        Start-Sleep -Seconds 2
    }
}

# Function to check and install required dependencies
function CheckDependencies {
    Logo
    Write-Log "Checking dependencies..." "INFO"
    Write-Host "`nChecking dependencies..." -ForegroundColor Yellow
    Import-Module Posh-SSH -ErrorAction SilentlyContinue
    if (-Not (Get-module "Posh-SSH" -ErrorAction SilentlyContinue)) {
        Write-Log "Posh-SSH module is not installed." "ERROR"
        Write-Host "Posh-SSH module is not installed." -ForegroundColor Red
        Write-Host "Would you like to install it now? (Y/N)" -ForegroundColor Yellow
        $response = Read-Host "Response"
        if ($response -eq "Y" -or $response -eq "y") {
            Install-Module -Name Posh-SSH -Force -Scope CurrentUser
            Write-Log "Posh-SSH module installed successfully." "INFO"
            Write-Host "Posh-SSH module installed successfully." -ForegroundColor Green
            return
        }
        else {
            Write-Log "Exiting due to missing dependencies." "ERROR"
            Write-Host "Exiting due to missing dependencies." -ForegroundColor Red
            start-sleep -Seconds 2
            exit
        }
    }
    Write-Log "All dependencies are satisfied." "INFO"
    Write-Host "All dependencies are satisfied." -ForegroundColor Green
    start-sleep -Seconds 2
}

# Function to connect or disconnect from the G.hn device
function ConnectToGhnDevice {
    Logo
    if ($sshSession -and $sshSession.Connected) {
        Write-Log "Already connected to G4200-4C. Disconnecting..." "INFO"
        Write-Host "`nAlready connected to G4200-4C. Disconnecting..." -ForegroundColor Yellow
        $stream.WriteLine("exit")
        Start-Sleep -Seconds 1
        $stream.WriteLine("logout")
        Start-Sleep -Seconds 1
        $stream.Close()
        Remove-SSHSession -SSHSession $sshSession | Out-Null
        $sshSession = $null
        Write-Log "Disconnected successfully." "INFO"
        Write-Host "Disconnected successfully." -ForegroundColor Green
        start-sleep -Seconds 2
        return
    }

    if ($Address -and $Username -and $Password) {
        Write-Log "Using provided parameters or config file to connect to G4200-4C." "INFO"
        $sshhost = $Address
        $username = $Username
        $password = (ConvertTo-SecureString $Password -AsPlainText -Force)
    } else {
        Write-Host "`n#############################" -ForegroundColor cyan
        Write-Host "# Setup G4200-4C Connection #" -ForegroundColor cyan
        Write-Host "#############################" -ForegroundColor cyan
        Write-Host "`nPlease enter the IP address or hostname of G4200-4C" -ForegroundColor Yellow
        $sshhost = Read-Host "IP or Hostname"
        if (-Not $sshhost) {
            Write-Log "No host specified. Exiting..." "ERROR"
            Write-Host "No host specified. Exiting..." -ForegroundColor Red
            start-sleep -Seconds 2
            return
        }

        Write-Host "`nEnter your credentials for G4200-4C" -ForegroundColor Yellow
        $username = Read-Host "Username"
        Write-Log "Username provided: $username" "INFO"
        $password = Read-Host "Password" -AsSecureString
    }

    if (-Not (Test-Connection -ComputerName $sshhost -Count 1 -Quiet)) {
        Write-Log "Device is not reachable. Check IP or network connection." "ERROR"
        Write-Host "Device is not reachable. Please check the IP address or network connection." -ForegroundColor Red
        start-sleep -Seconds 2
        return
    }

    try {
        $credential = New-Object System.Management.Automation.PSCredential($username, $password)
        $global:sshSession = New-SSHSession -ComputerName $sshhost -Credential $credential -AcceptKey
        $global:stream = New-SSHShellStream -SSHSession $global:sshSession -TerminalName "xterm" -Columns 80 -Rows 24 -Width 800 -Height 600 -BufferSize 1000
        Write-Log "Connected successfully to G4200-4C at host: $sshhost with username: $username" "INFO"
        Write-Host "Connected successfully." -ForegroundColor Green
        start-sleep -Seconds 2
    } catch {
        Write-Log "Failed to connect to G4200-4C at host: $sshhost with username: $username. Error: $_" "ERROR"
        Write-Host "Failed to connect: $_" -ForegroundColor Red
        start-sleep -Seconds 2
        return
    }
}

# Function to check if there is an active SSH connection
function CheckConnection {
    if (-Not ($sshSession -and $sshSession.Connected)) {
        Write-Log "Not connected to G4200-4C." "ERROR"
        Write-Host "`nNot connected to G4200-4C. Please connect first." -ForegroundColor Red
        start-sleep -Seconds 2
        break
    }
}

# Function to open an interactive shell session with the G.hn device
function OpenShell {
    Logo
    CheckConnection
    Write-Log "Entering interactive shell mode." "INFO"
    Write-Host "`nEntering interactive shell mode. Type 'exit' to return to the menu." -ForegroundColor Yellow
    while ($true) {
        $inputdata = Read-Host -Prompt "G4200-4C"
        if ($inputdata -eq "exit") {
            Write-Log "Exiting interactive shell mode." "INFO"
            break
        }
        $stream.WriteLine($inputdata)
        Start-Sleep -Seconds 1
        while ($stream.DataAvailable) {
            $output = $stream.Read()
            Write-Log "Shell Output: $output" "INFO"
            Write-Output $output
            Start-Sleep -Milliseconds 200
        }
    }
}

# Function to display connected G.hn endpoints
function ShowConnectedGhnEndpoints {
    Logo
    CheckConnection
    Clear-SSHStream $stream
    Write-Log "Fetching connected G.hn endpoints..." "INFO"
    Write-Host "`nFetching connected G.hn endpoints" -ForegroundColor Yellow
    $stream.WriteLine("show ghn interface")
    $count = 0
    while ($count -ne 4) {
        Write-Host "." -ForegroundColor Yellow -NoNewline
        Start-Sleep -Seconds 1
        $count++
    }
    $output = $stream.Read()
    Write-Log "Connected G.hn endpoints: $output" "INFO"

    # Parse the G.hn endpoint data into a structured format
    $endpoints = @()
    foreach ($line in $output -split "`r?`n") {
        $line = $line.Trim()
        if ($line -match "^(?<Interface>\S+)\s+(?<Master_ID>\d+)\s+(?<Link>\S+)\s+(?<Local_MAC>\S+)\s+(?<Remote_MAC>\S+)\s+(?<Speed>\S+)\s+(?<Wire_Length>\S+)\s+(?<Estimated_XPUT>\S+)$") {
            $endpoints += [PSCustomObject]@{
                Interface       = $matches.Interface
                Master_ID       = $matches.Master_ID
                Link            = $matches.Link
                Local_MAC       = $matches.Local_MAC
                Remote_MAC      = $matches.Remote_MAC
                Speed           = $matches.Speed
                Wire_Length     = $matches.Wire_Length
                Estimated_XPUT  = $matches.Estimated_XPUT
            }
        }
    }

    # Display the parsed G.hn endpoint data in a table format
    Write-Host "`n----------- Connected G.hn Endpoints -----------" -ForegroundColor Cyan
    $endpoints | Format-Table -AutoSize
    Write-Host "------------------------------------------------" -ForegroundColor Cyan

    Write-Host "Press any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to display configured VLANs
function ShowConfiguredVlans {
    Logo
    CheckConnection
    Clear-SSHStream $stream
    Write-Log "Fetching VLAN configuration..." "INFO"
    Write-Host "`nFetching VLAN configuration" -ForegroundColor Yellow
    $stream.WriteLine("show vlan all")
    $count = 0
    while ($count -ne 4) {
        Write-Host "." -ForegroundColor Yellow -NoNewline
        Start-Sleep -Seconds 1
        $count++
    }
    $output = $stream.Read()
    Write-Log "VLAN configuration: $output" "INFO"

    # Parse the VLAN configuration into a structured format
    $vlans = @()
    $currentVlan = $null
    foreach ($line in $output -split "`r?`n") {
        $line = $line.Trim()
        if ($line -match "^VLAN ID: (\d+)$") {
            # Start a new VLAN entry
            if ($currentVlan) {
                $vlans += $currentVlan
            }
            $currentVlan = @{
                VlanId = $matches[1]
                VlanType = ""
                Description = ""
                TagPorts = @()
                unTagPorts = @()
                ForbiddenPorts = @()
            }
        } elseif ($line -match "^VLAN Type:\s*(.*)$") {
            $currentVlan.VlanType = $matches[1]
        } elseif ($line -match "^Description:(.*)$") {
            $currentVlan.Description = $matches[1].Trim()
        } elseif ($line -match "^Tag Ports:$") {
            $currentSection = "TagPorts"
        } elseif ($line -match "^unTag Ports:$") {
            $currentSection = "unTagPorts"
        } elseif ($line -match "^Forbidden Ports:$") {
            $currentSection = "ForbiddenPorts"
        } elseif ($line -match "^\S") {
            # Add ports to the current section
            if ($currentSection -and $currentVlan) {
                $currentVlan.$currentSection += $line -split "\s{2,}"
            }
        }
    }
    # Add the last VLAN entry
    if ($currentVlan) {
        $vlans += $currentVlan
    }

    # Display the parsed VLAN configuration in a table format
    Write-Host "`n----------- VLAN Configuration -----------" -ForegroundColor Cyan
    $table = $vlans | ForEach-Object {
        [PSCustomObject]@{
            "VLAN ID"         = $_.VlanId
            "Type"            = $_.VlanType
            "Description"     = $_.Description
            "Tagged Ports"    = ($_.TagPorts -join ", ")
            "Untagged Ports"  = ($_.unTagPorts -join ", ")
            "Forbidden Ports" = ($_.ForbiddenPorts -join ", ")
        }
    }
    $table | Format-Table -AutoSize
    Write-Host "------------------------------------------" -ForegroundColor Cyan

    Write-Host "Press any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to add a new VLAN
function AddVlan {
    Logo
    CheckConnection
    Clear-SSHStream $stream
    Write-Log "Adding new VLAN..." "INFO"
    Write-Host "`nAdding new VLAN" -ForegroundColor Yellow
    Write-Warning "BE SURE TO NOT USE AN EXISTING VLAN ID, THIS WILL OVERWRITE THE EXISTING VLAN!"

    # Validate VLAN ID
    while ($true) {
        $vlanId = Read-Host "Enter VLAN ID (1-4094)"
        if ($vlanId -match '^\d+$' -and [int]$vlanId -ge 1 -and [int]$vlanId -le 4094) {
            break
        } else {
            Write-Host "Invalid VLAN ID. Please enter a number between 1 and 4094." -ForegroundColor Red
        }
    }

    $vlanDescription = Read-Host "Enter VLAN Name/Description"
    Write-Host "`nWould you like to use custom port assignments? (Y/N)" -ForegroundColor Yellow
    Write-Host "If no the default ports will be assigned. (Ghn1,Ghn2,Ghn3,Ghn4,RJ45/G1,RJ45/G2,Fiber/G1,Fiber/G2)" -ForegroundColor Yellow
    $customPorts = Read-Host "Use custom ports"
    if ($customPorts -eq "Y" -or $customPorts -eq "y") {
        $taggedPorts = Read-Host "Enter Tagged Ports (comma-separated, e.g., Ghn1,Ghn2,Ghn3,Ghn4,Ghn5,Ghn6,Ghn7,Ghn8,Monitor,RJ45/G1,RJ45/G2,Fiber/G1,Fiber/G2)"
        $untaggedPorts = Read-Host "Enter Untagged Ports (comma-separated, e.g., Ghn1,Ghn2,Ghn3,Ghn4,Ghn5,Ghn6,Ghn7,Ghn8,Monitor,RJ45/G1,RJ45/G2,Fiber/G1,Fiber/G2)"
        $forbiddenPorts = Read-Host "Enter Forbidden Ports (comma-separated, e.g., Ghn1,Ghn2,Ghn3,Ghn4,Ghn5,Ghn6,Ghn7,Ghn8,Monitor,RJ45/G1,RJ45/G2,Fiber/G1,Fiber/G2)"
    }
    else {
        $taggedPorts = "Ghn1,Ghn2,Ghn3,Ghn4,RJ45/G1,RJ45/G2,Fiber/G1,Fiber/G2"
        $untaggedPorts = ""
        $forbiddenPorts = ""
    }
    Write-Log "Creating VLAN ID: $vlanId, Description: $vlanDescription" "INFO"
    $stream.WriteLine("configure terminal")
    Start-Sleep -Seconds 2
    $stream.WriteLine("vlan $vlanId")
    Start-Sleep -Seconds 2
    $stream.WriteLine("name `"$vlanDescription`"")
    Start-Sleep -Seconds 2
    if ($taggedPorts) {
        $taggedPortsArray = $taggedPorts -split ","
        foreach ($port in $taggedPortsArray) {
            $port = $port.Trim()
            if ($port) {
                Write-Log "Adding Tagged Port: $port to VLAN ID: $vlanId" "INFO"
                Write-Host "Adding Tagged Port: $port to VLAN ID: $vlanId" -ForegroundColor Yellow
                $stream.WriteLine("switchport tagged ethernet $port")
                Start-Sleep -Seconds 1
            }
        }
    }
    if ($untaggedPorts) {
        $untaggedPortsArray = $untaggedPorts -split ","
        foreach ($port in $untaggedPortsArray) {
            $port = $port.Trim()
            if ($port) {
                Write-Log "Adding Untagged Port: $port to VLAN ID: $vlanId" "INFO"
                Write-Host "Adding Untagged Port: $port to VLAN ID: $vlanId" -ForegroundColor Yellow
                $stream.WriteLine("switchport untagged ethernet $port")
                Start-Sleep -Seconds 1
            }
        }
    }
    if ($forbiddenPorts) {
        $forbiddenPortsArray = $forbiddenPorts -split ","
        foreach ($port in $forbiddenPortsArray) {
            $port = $port.Trim()
            if ($port) {
                Write-Log "Adding Forbidden Port: $port to VLAN ID: $vlanId" "INFO"
                Write-Host "Adding Forbidden Port: $port to VLAN ID: $vlanId" -ForegroundColor Yellow
                $stream.WriteLine("switchport forbidden ethernet $port")
                Start-Sleep -Seconds 1
            }
        }
    }
    $stream.WriteLine("exit")
    Start-Sleep -Seconds 1
    Write-Log "VLAN ID: $vlanId created successfully." "INFO"
    Write-Host "VLAN ID: $vlanId created successfully." -ForegroundColor Green
    Write-Host "Press any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")


}

# Function to remove an existing VLAN
function RemoveVlan {
    Logo
    CheckConnection
    Clear-SSHStream $stream
    Write-Log "Removing VLAN..." "INFO"
    Write-Host "`nRemoving VLAN" -ForegroundColor Yellow
    Write-Warning "BE SURE TO NOT REMOVE AN EXISTING VLAN THAT IS IN USE, THIS WILL DISCONNECT DEVICES!"

    # Validate VLAN ID
    while ($true) {
        $vlanId = Read-Host "Enter VLAN ID to remove (1-4094)"
        if ($vlanId -match '^\d+$' -and [int]$vlanId -ge 1 -and [int]$vlanId -le 4094) {
            break
        } else {
            Write-Host "Invalid VLAN ID. Please enter a number between 1 and 4094." -ForegroundColor Red
        }
    }

    Write-Host "`nAre you sure you want to remove VLAN ID: $vlanId ? (Y/N)" -ForegroundColor Yellow
    $confirmation = Read-Host "Type 'Y' to confirm"
    if ($confirmation -ne 'Y' -or $confirmation -ne 'y') {
        Write-Log "Remove VLAN cancelled by user." "INFO"
        Write-Host "Operation cancelled." -ForegroundColor Red
        start-sleep -Seconds 1
        return
    }

    Write-Log "Removing VLAN ID: $vlanId" "INFO"
    Write-Host "Removing VLAN ID: $vlanId" -ForegroundColor Yellow
    $stream.WriteLine("configure terminal")
    Start-Sleep -Seconds 2
    $stream.WriteLine("no vlan $vlanId")
    Start-Sleep -Seconds 2
    $stream.WriteLine("exit")
    Start-Sleep -Seconds 1
    Write-Log "VLAN ID: $vlanId removed successfully." "INFO"
    Write-Host "VLAN ID: $vlanId removed successfully." -ForegroundColor Green
    Write-Host "Press any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to restart a specific G.hn endpoint by MAC address
function RestartGhnEndpoint {
    Logo
    CheckConnection
    Clear-SSHStream $stream

    # Automatically use the provided MAC address if -RestartEndpoint is used
    if ($RestartEndpoint -and $Mac) {
        Write-Log "Restarting G.hn endpoint with MAC: $Mac (automatic mode)" "INFO"
        $mac = $Mac
    } else {
        Write-Host "`nEnter MAC Address of endpoint (Format: xxxx.xxxx.xxxx)" -ForegroundColor yellow
        Write-Host "Enter exit to return to the menu" -ForegroundColor Yellow
        write-Host ""
        while ($true) {
            $mac = Read-Host "MAC"
            if ($mac -match '^[a-fA-F0-9]{4}\.[a-fA-F0-9]{4}\.[a-fA-F0-9]{4}$') {
                Write-Log "Valid MAC address entered: $mac" "INFO"
                break
            } 
            elseif ($mac -eq "exit") {
                Write-Log "Restart G.hn endpoint cancelled by user." "INFO"
                Write-Host "Operation cancelled." -ForegroundColor Red
                start-sleep -Seconds 1
                return
            } else {
                Write-Log "Invalid MAC address entered: $mac" "ERROR"
                Write-Host "Invalid MAC address format. Please use the format xxxx.xxxx.xxxx" -ForegroundColor Red
            }
        }
    }

    Write-Log "Restarting G.hn endpoint with MAC: $mac" "INFO"
    Write-Host "Restarting G.hn endpoint with MAC: $mac" -ForegroundColor Yellow
    $stream.WriteLine("configure terminal")
    Start-Sleep -Seconds 2
    $stream.WriteLine("ghn restart $mac")
    Start-Sleep -Seconds 5
    $stream.WriteLine("exit")
    Start-Sleep -Seconds 1
    $response = $stream.Read()
    Write-Log "Response from device: $response" "INFO"

    if ($response -match "Didn't find node!") {
        Write-Log "G.hn endpoint not found for MAC: $mac" "ERROR"
        Write-Host "G.hn endpoint not found." -ForegroundColor Red
    } 
    elseif ($response -match "Reboot ghn node failed!") {
        Write-Log "Failed to restart G.hn endpoint with MAC: $mac" "ERROR"
        Write-Host "Failed to restart G.hn endpoint." -ForegroundColor Red
    }
    else {
        Write-Log "G.hn endpoint with MAC $mac restarted successfully." "INFO"
        Write-Host "G.hn endpoint restarted successfully." -ForegroundColor Green
    }

    Write-Host "Press any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to restart the G4200-4C device
function RestartG42004C {
    Logo
    CheckConnection
    Write-host ""
    Write-Log "Restarting G4200-4C initiated." "WARNING"

    # Automatically confirm if -RestartG42004C is used
    if (-not $RestartG42004C) {
        Write-Warning "Are you sure you want to restart the G4200-4C? (Config will not be saved !) (Y/N)"
        Write-Warning "This will disconnect all G.hn clients and disrupt the network."
        $confirmation = Read-Host "Type 'Y' to confirm"
        if ($confirmation -ne 'Y') {
            Write-Log "Restart G4200-4C cancelled by user." "INFO"
            Write-Host "Operation cancelled." -ForegroundColor Red
            start-sleep -Seconds 1
            return
        }
    } else {
        Write-Log "Reboot confirmed automatically due to -RestartG42004C parameter." "INFO"
    }

    Clear-SSHStream $stream
    Write-Log "Restarting G4200-4C..." "INFO"
    Write-Host "`nRestarting G4200-4C" -ForegroundColor Yellow
    $stream.WriteLine("configure terminal")
    Start-Sleep -Seconds 2
    $stream.WriteLine("reboot")
    Start-Sleep -Seconds 2
    $stream.WriteLine("n")
    Start-Sleep -Seconds 5
    Write-Log "Restart command executed for G4200-4C." "INFO"
    Write-Host "Command executed successfully." -ForegroundColor Green
    Write-Host "Please wait for the device to come back online." -ForegroundColor Yellow
    Write-Host "This may take up to a minute." -ForegroundColor Yellow
    Write-Host "Waiting for G4200-4C to come back online" -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    while ((Test-Connection -ComputerName $Address -Count 1 -Quiet) -eq $false) {
        Write-Host "." -ForegroundColor Yellow -NoNewline
    }
    Write-Log "G4200-4C is back online." "INFO"
    Write-Host "G4200-4C is back online." -ForegroundColor Green
    Write-Host "`nYou can now reconnect to the device." -ForegroundColor Yellow
    Write-Host "Press any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to show system logs from the G4200-4C device
function ShowSystemLogs {
    Logo
    CheckConnection
    Clear-SSHStream $stream
    Write-Log "Fetching system logs..." "INFO"
    Write-Host "`nFetching system logs" -ForegroundColor Yellow
    $stream.WriteLine("show logging")
    $count = 0
    while ($count -ne 4) {
        Write-Host "." -ForegroundColor Yellow -NoNewline
        Start-Sleep -Seconds 1
        $count++
    }
    $output = $stream.Read()
    Write-Log "System logs: $output" "INFO"

    # Display the system logs
    Write-Host "`n----------- System Logs -----------" -ForegroundColor Cyan
    Write-Host $output
    Write-Host "-----------------------------------" -ForegroundColor Cyan

    Write-Host "Press any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
}

function SaveConfig {
    Logo
    CheckConnection
    Clear-SSHStream $stream
    Write-Log "Saving configuration..." "INFO"
    Write-Host "`nSaving configuration" -ForegroundColor Yellow
    $stream.WriteLine("write")
    start-sleep -Seconds 1
    $stream.WriteLine("y")
    $count = 0
    while ($count -ne 4) {
        Write-Host "." -ForegroundColor Yellow -NoNewline
        Start-Sleep -Seconds 1
        $count++
    }
    $output = $stream.Read()
    Write-Log "Save configuration response: $output" "INFO"
    Write-Host "`nConfiguration saved successfully." -ForegroundColor Green
    Write-Host "Press any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Function to close the program and clean up resources
function CloseProgram {
    Clear-Host
    Logo
    Write-Log "Closing connection" "INFO"
    if ($sshSession -and $sshSession.Connected) {
        $stream.WriteLine("exit")
        Start-Sleep -Seconds 1
        $stream.WriteLine("logout")
        Start-Sleep -Seconds 1
        Write-Host "`nClosing connection" -ForegroundColor Yellow
        $stream.Close()
        Remove-SSHSession -SSHSession $sshSession -ErrorAction SilentlyContinue
        Write-Log "Connection closed successfully." "INFO"
    } else {
        Write-Log "No active connection to close." "INFO"
        Write-Host "No active connection to close." -ForegroundColor Yellow
    }
    Write-Log "BYE BYE !!!" "INFO"
    Write-Host "BYE BYE !!!" -ForegroundColor Yellow
    Write-Host "Thank you for using $ProgramName" -ForegroundColor Magenta
    Write-Host "Log file saved to: $global:LogFilePath" -ForegroundColor Cyan
    $curDateFinished = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
    Write-Log "Finished: $curDateFinished" "INFO"
    Write-Log "################ LOG END ################"
    start-sleep -Seconds 3
    Exit 0
}

#####################################################################
# Main Code --- Main Code --- Main Code --- Main Code --- Main Code #
#-------------------------------------------------------------------#

# Log the start of the program
Write-Log "################ LOG BEGIN ################" "INFO"

# Display the splash logo and program information
SplashLogo
Write-Host "G.hn - Management Program for G4200-4C" -ForegroundColor Yellow
Write-Host "MATRIXNET ~ Vincent" -ForegroundColor Yellow
Write-Host "Version $version" -ForegroundColor Blue
Write-Host "`n----------------------------" -ForegroundColor Magenta
Write-Host "| Always trust the process |" -ForegroundColor Magenta
Write-Host "----------------------------" -ForegroundColor Magenta
Start-Sleep -Seconds 3
CheckForUpdates
CheckDependencies

# Ensure the program directory exists
if (-Not (Test-Path $programdir)) { New-Item -ItemType Directory -Path $programdir }

# Import the Posh-SSH module
Import-Module Posh-SSH -ErrorAction SilentlyContinue

# Handle parameters for non-interactive execution
if ($RestartEndpoint -and $Mac -and $Address -and $Username -and $Password) {
    Write-Log "Non-interactive mode: Restarting G.hn endpoint with provided parameters." "INFO"
    $global:sshSession = $null
    $global:stream = $null
    $Address = $Address
    $Username = $Username
    $Password = $Password
    ConnectToGhnDevice
    RestartGhnEndpoint
    CloseProgram
    Exit
}

if ($RestartG42004C -and $Address -and $Username -and $Password) {
    Write-Log "Non-interactive mode: Restarting G4200-4C with provided parameters." "INFO"
    $global:sshSession = $null
    $global:stream = $null
    $Address = $Address
    $Username = $Username
    $Password = $Password
    ConnectToGhnDevice
    RestartG42004C
    CloseProgram
    Exit
}


##################################
# Begin Loop
$WhileLoopVar = 1
while ($WhileLoopVar -eq 1){
##################################
##################################
# Interactive Menu #
##################################

# Define menu items
$list = @('CONNECT / DISCONNECT G4200-4C', 'SHOW CONNECTED GHN ENDPOINTS', 'SHOW CONFIGURED VLANS', 'ADD VLAN', 'REMOVE VLAN', 'RESTART GHN ENDPOINT', 'RESTART G4200-4C', 'OPEN SHELL', 'SHOW SYSTEM LOGS', 'SAVE CONFIG', 'EXIT')


# menu offset to allow space to write a message above the menu
$xmin = 3
$ymin = 15
 
# Write the menu to the console
If ( $sshSession.Connected -eq "True" -or $sshSession.Connected -eq $true ) {
    $ConnectionStatus = "Connected"
    $ConnectionStatusColor = "Green"
}
else {
    $ConnectionStatus = "Disconnected"
    $ConnectionStatusColor = "Red"
}
Clear-Host
Logo
$host.UI.RawUI.WindowTitle = "$ProgramName - Version $version"
Write-Host ""
Write-Host "`n  Use the up / down arrow to navigate and Enter to make a selection" -ForegroundColor Yellow
Write-Host "`n "
[Console]::SetCursorPosition(0, $ymin)
foreach ($name in $List) {
    for ($i = 0; $i -lt $xmin; $i++) {
        Write-Host " " -NoNewline
    }
    Write-Host "   " + $name
}
 
# Function to highlight the selected menu item
function Write-Highlighted {
 
    [Console]::SetCursorPosition(1 + $xmin, $cursorY + $ymin)
    Write-Host ">" -BackgroundColor Yellow -ForegroundColor Black -NoNewline
    Write-Host " " + $List[$cursorY] -BackgroundColor Yellow -ForegroundColor Black
    [Console]::SetCursorPosition(0, $cursorY + $ymin)     
}
 
# Function to remove highlight from a menu item
function Write-Normal {
    [Console]::SetCursorPosition(1 + $xmin, $cursorY + $ymin)
    Write-Host "  " + $List[$cursorY]  
}
 
# Highlight the first menu item by default
$cursorY = 0
Write-Highlighted
 
# Handle menu navigation and selection
$selection = ""
$menu_active = $true
while ($menu_active) {
    if ([console]::KeyAvailable) {
        $x = $Host.UI.RawUI.ReadKey()
        [Console]::SetCursorPosition(1, $cursorY)
        Write-Normal
        switch ($x.VirtualKeyCode) { 
            38 {
                #down key
                if ($cursorY -gt 0) {
                    $cursorY = $cursorY - 1
                }
            }
 
            40 {
                #up key
                if ($cursorY -lt $List.Length - 1) {
                    $cursorY = $cursorY + 1
                }
            }
            13 {
                #enter key
                $selection = $List[$cursorY]
                $menu_active = $false
            }
        }
        Write-Highlighted
    }
    Start-Sleep -Milliseconds 5 #Prevents CPU usage from spiking while looping
}
 


Clear-Host
switch ($selection) {
    "CONNECT / DISCONNECT G4200-4C" {ConnectToGhnDevice}
    "SHOW CONNECTED GHN ENDPOINTS" {ShowConnectedGhnEndpoints}
    "SHOW CONFIGURED VLANS" {ShowConfiguredVlans}
    "ADD VLAN" {AddVlan}
    "REMOVE VLAN" {RemoveVlan}
    "RESTART GHN ENDPOINT" {RestartGhnEndpoint}
    "RESTART G4200-4C" {RestartG42004C}
    "OPEN SHELL" {OpenShell}
    "SHOW SYSTEM LOGS" {ShowSystemLogs}
    "SAVE CONFIG" {SaveConfig}
    "EXIT" {CloseProgram}
}
}
##################################
# End Loop