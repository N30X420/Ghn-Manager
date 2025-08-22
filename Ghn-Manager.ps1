$ErrorActionPreference = "Stop"

$version = "1.0"
$ProgramName = "G.hn-Manager"
$programdir = "C:\MATRIXNET\$ProgramName-$version"
clear-host
Import-Module Posh-SSH

$global:sshSession = $null
$global:stream = $null

If ( $sshSession.Connected -eq "True" -or $sshSession.Connected -eq $true ) {
    $ConnectionStatus = "Connected"
    $ConnectionStatusColor = "Green"
}
else {
    $ConnectionStatus = "Disconnected"
    $ConnectionStatusColor = "Red"
}

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

function Logo {
    Write-Host " "
    write-Host "   ____   _                     __  __ " -ForegroundColor Blue
    write-Host "  / ___| | |__  _ __           |  \/  | __ _ _ __   __ _  __ _  ___ _ __" -ForegroundColor Blue
    write-Host " | |  _  |  _ \|  _ \   _____  | |\/| |/ _  |  _ \ / _  |/ _  |/ _ \  __|" -ForegroundColor Blue
    write-Host " | |_| |_| | | | | | | |_____| | |  | | (_| | | | | (_| | (_| |  __/ |" -ForegroundColor Blue
    write-Host "  \____(_)_| |_|_| |_|         |_|  |_|\__,_|_| |_|\__,_|\__, |\___|_|" -ForegroundColor Blue
    write-Host "                                                        |___/" -ForegroundColor Blue
    write-Host "v$version" -ForegroundColor Blue
    Write-Host "$ConnectionStatus" -ForegroundColor $ConnectionStatusColor
}


function Clear-SSHStream {
    param([object]$stream)
    while ($stream.DataAvailable) {
        $null = $stream.Read()
    }
}
function CheckDependencies {
    Logo
    Write-Host "Checking dependencies..." -ForegroundColor Yellow
    if (-Not (Get-module "Posh-SSH" -ErrorAction SilentlyContinue)) {
        Write-Host "Posh-SSH module is not installed." -ForegroundColor Red
        Write-Host "Would you like to install it now? (Y/N)" -ForegroundColor Yellow
        $response = Read-Host "Response"
        if ($response -eq "Y" -or $response -eq "y") {
            Install-Module -Name Posh-SSH -Force -Scope CurrentUser
            return
        }
        else {
            Write-Host "Exiting due to missing dependencies." -ForegroundColor Red
            start-sleep -Seconds 2
            exit
        }
        return
    }
    Write-Host "All dependencies are satisfied." -ForegroundColor Green
    start-sleep -Seconds 2
}

function ConnectToGhnDevice {
    Logo
    if ($sshSession -and $sshSession.Connected) {
        Write-Host "`nAlready connected to G4200-4C. Disconnecting..." -ForegroundColor Yellow
        $stream.WriteLine("exit")
        Start-Sleep -Seconds 1
        $stream.WriteLine("logout")
        Start-Sleep -Seconds 1
        $stream.Close()
        Remove-SSHSession -SSHSession $sshSession | Out-Null
        $sshSession = $null
        Write-Host "Disconnected successfully." -ForegroundColor Green
        start-sleep -Seconds 2
        return
    }
    Write-Host "`nSetup G4200-4C Connection" -ForegroundColor cyan
    Write-Host "Please enter the IP address or hostname of G4200-4C" -ForegroundColor Yellow
    $sshhost = Read-Host "IP"
    if (-Not $sshhost) {
        Write-Host "No host specified. Exiting..." -ForegroundColor Red
        start-sleep -Seconds 2
        return
    }

    if (-Not (Test-Connection -ComputerName $sshhost -Count 1 -Quiet)) {
        Write-Host "Device is not reachable. Please check the IP address or network connection." -ForegroundColor Red
        start-sleep -Seconds 2
        return
    }

    Write-host "Enter SSH credentials for G4200-4C" -ForegroundColor Yellow
    $username = Read-Host "Username"
    $password = Read-Host "Password" -AsSecureString
    $credential = New-Object System.Management.Automation.PSCredential($username, $password)
    
    Write-Host "Connecting to G4200-4C..." -ForegroundColor Yellow
    try {
        $global:sshSession = New-SSHSession -ComputerName $sshhost -Credential $credential -AcceptKey
        $global:stream = New-SSHShellStream -SSHSession $global:sshSession -TerminalName "xterm" -Columns 80 -Rows 24 -Width 800 -Height 600 -BufferSize 1000
        Write-Host "Connected successfully." -ForegroundColor Green
        start-sleep -Seconds 2

    } catch {
        Write-Host "Failed to connect: $_" -ForegroundColor Red
        start-sleep -Seconds 2
        return
    }
}

function OpenShell {
    Logo
    if (-Not ($sshSession -and $sshSession.Connected)) {
        Write-Host "`nNot connected to G4200-4C. Please connect first." -ForegroundColor Red
        start-sleep -Seconds 2
        return
    }
    Write-Host "`nEntering interactive shell mode. Type 'exit' to return to the menu." -ForegroundColor Yellow
    while ($true) {
        $inputdata = Read-Host -Prompt "G4200-4C"
        if ($inputdata -eq "exit") {
            break
        }
        $stream.WriteLine($inputdata)
        Start-Sleep -Seconds 1
        while ($stream.DataAvailable) {
            $output = $stream.Read()
            Write-Output $output
            Start-Sleep -Milliseconds 200
        }
    }
    
}
function ShowConnectedGhnClients {
    Logo
    Clear-SSHStream $stream
    Write-Host "`nFetching connected GHN clients..." -ForegroundColor Yellow
    $stream.WriteLine("show ghn interface")
    Start-Sleep -Seconds 2
    Write-Host "-----------Connected GHN clients-----------" -ForegroundColor Cyan
    $output = $stream.Read()
    Write-Output $output
    Write-Host "--------------------------------------------" -ForegroundColor Cyan
    Write-Host "Press any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function RestartGhnEndpoint {
    Logo
    Clear-SSHStream $stream
    Write-Host "`nEnter MAC Address of node (Format: xxxx.xxxx.xxxx)" -ForegroundColor Magenta
    $mac = Read-Host "MAC: "
    Write-Host "Restarting GHN device with MAC: $mac" -ForegroundColor Yellow
    $stream.WriteLine("configure terminal")
    Start-Sleep -Seconds 2
    $stream.WriteLine("ghn restart $mac")
    Start-Sleep -Seconds 5
    $stream.WriteLine("exit")
    Start-Sleep -Seconds 1
    Write-Host "GHN device restarted successfully." -ForegroundColor Green
    Write-Host "Press any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Restart-G42004C {
    Logo
    Write-Warning "Are you sure you want to restart the G4200-4C? (Y/N)"
    Write-Warning "This will disconnect all G.hn clients and disrupt the network."
    $confirmation = Read-Host "Type 'Y' to confirm"
    if ($confirmation -ne 'Y') {
        Write-Host "Restart cancelled." -ForegroundColor Red
        return
    }
    Clear-SSHStream $stream
    Write-Host "`nRestarting G4200-4C" -ForegroundColor Yellow
    $stream.WriteLine("configure terminal")
    Start-Sleep -Seconds 2
    $stream.WriteLine("reboot")
    Start-Sleep -Seconds 2
    $stream.WriteLine("y")
    Start-Sleep -Seconds 5
    Write-Host "Command executed successfully." -ForegroundColor Green
    Write-Host "Please wait for the device to come back online." -ForegroundColor Yellow
    Write-Host "This may take up to a minute." -ForegroundColor Yellow
    Write-Host "Waiting for G4200-4C to come back online" -ForegroundColor Yellow
    while ((Test-Connection -ComputerName $sshhost -Count 1 -Quiet) -eq $false) {
        Write-Host "." -ForegroundColor Yellow -NoNewline
    }
    Write-Host "G4200-4C is back online." -ForegroundColor Green
    Write-Host "`nYou can now reconnect to the device." -ForegroundColor Yellow
    Write-Host "Press any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function EXIT {
    Clear-Host
    Logo
    $stream.WriteLine("exit")
    Start-Sleep -Seconds 1
    $stream.WriteLine("logout")
    Start-Sleep -Seconds 1
    write-host "`nClosing connection" -ForegroundColor Yellow
    $stream.Close()
    Remove-SSHSession -SSHSession $sshSession
    Write-Host "BYE BYE !!!" -ForegroundColor Green
    Write-Host "`n############################################" -ForegroundColor Magenta
    Write-Host "Last Errors :" -ForegroundColor Yellow
    Write-host "$error" -ForegroundColor Red
    Write-Host "############################################" -ForegroundColor Magenta
    $curDateFinished = Get-Date -Format "dd/MM/yyyy HH/mm/ss"
    Write-Host "`nFinished : $curDateFinished" -ForegroundColor Yellow
    Write-Host " "
    Write-Host " "
    Write-Host "################ LOG END ################"-ForegroundColor Magenta
    Stop-Transcript
    Start-Sleep -Seconds 3
    Exit 0
}

#####################################################################
# Main Code --- Main Code --- Main Code --- Main Code --- Main Code #
#-------------------------------------------------------------------#
#SplashLogo
Write-Host "G.hn - Management Program for G4200-4C" -ForegroundColor Yellow
Write-Host "MATRIXNET ~ Vincent" -ForegroundColor Yellow
Write-Host "Version $version" -ForegroundColor Blue
Write-Host
Write-Host "----------------------------" -ForegroundColor Magenta
write-Host "| Always trust the process |" -ForegroundColor Magenta
Write-Host "----------------------------" -ForegroundColor Magenta
#Start-Sleep -Seconds 3



# Check Program Folder
if (-Not (Test-Path $programdir)){
    New-Item -ItemType Directory -Path $programdir
}

# Start Logging in Program directory (Programdir)
$CurDate = Get-Date -Format "dd-MM-yyyy_HH-mm-ss"
Start-Transcript -Path $programdir\"$ProgramName-$version-$CurDate.log" | Out-Null
Write-Host " "
Write-Host " "
Write-Host "################ LOG BEGIN ################" -ForegroundColor Magenta





##################################
# Begin Loop
$WhileLoopVar = 1
while ($WhileLoopVar -eq 1){
##################################
##################################
# Interactive Menu #
##################################
#Menu items
$list = @('CHECK DEPENDENCIES','CONNECT / DISCONNECT G4200-4C','OPEN SHELL','SHOW CONNECTED GHN CLIENTS','RESTART GHN ENDPOINT','RESTART G4200-4C','EXIT')
 


#menu offset to allow space to write a message above the menu
$xmin = 3
$ymin = 15
 
#Write Menu
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
 
#Highlights the selected line
function Write-Highlighted {
 
    [Console]::SetCursorPosition(1 + $xmin, $cursorY + $ymin)
    Write-Host ">" -BackgroundColor Yellow -ForegroundColor Black -NoNewline
    Write-Host " " + $List[$cursorY] -BackgroundColor Yellow -ForegroundColor Black
    [Console]::SetCursorPosition(0, $cursorY + $ymin)     
}
 
#Undoes highlight
function Write-Normal {
    [Console]::SetCursorPosition(1 + $xmin, $cursorY + $ymin)
    Write-Host "  " + $List[$cursorY]  
}
 
#highlight first item by default
$cursorY = 0
Write-Highlighted
 
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
    "CHECK DEPENDENCIES" {CheckDependencies}
    "CONNECT / DISCONNECT G4200-4C" {ConnectToGhnDevice}
    "OPEN SHELL" {OpenShell}
    "SHOW CONNECTED GHN CLIENTS" {ShowConnectedGhnClients}
    "RESTART GHN ENDPOINT" {RestartGhnEndpoint}
    "RESTART G4200-4C" {Restart-G42004C}
    "EXIT" {EXIT}
}
}
##################################
# End Loop
$WhileLoopVar = 0