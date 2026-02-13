# G.hn-Manager

G.hn-Manager is a comprehensive PowerShell-based tool designed to manage and interact with G.hn devices, such as the G4200-4C and G4206C. It provides an intuitive interactive menu for managing connections, VLANs, endpoints, and performing other administrative tasks. The tool also supports non-interactive execution using command-line arguments or a configuration file for automation.

---

## Key Features

### General
- **Interactive Menu**: Navigate through various management options using an intuitive menu.
- **Non-Interactive Mode**: Execute specific tasks directly via command-line arguments.
- **Configuration File**: Predefine device details (host, username, password) in a `config.json` file for convenience.
- **Logging**: Logs all actions and outputs to a log file for auditing and troubleshooting.

### Device Management
- **SSH Connection Management**: Establishes and manages SSH connections to G.hn devices.
- **Device Reboot**: Restart the G4200-4C or G4206C device with optional automatic confirmation.
- **System Logs**: Fetch and display system logs from the G4200-4C or G4206C device.

### Endpoint Management
- **Show Connected Endpoints**: Display a detailed list of connected G.hn endpoints, including:
  - Interface
  - Master ID
  - Link status
  - Local and remote MAC addresses
  - Physical downstream/upstream speed
  - Wire length
  - Estimated throughput
- **Restart Endpoint**: Restart a specific G.hn endpoint by its MAC address.

### VLAN Management
- **Show Configured VLANs**: Display all configured VLANs in a structured table format, including:
  - VLAN ID
  - Type
  - Description
  - Tagged, untagged, and forbidden ports
- **Add VLAN**: Create a new VLAN with the following options:
  - Validate VLAN ID (must be a number between 1 and 4094).
  - Assign custom tagged, untagged, and forbidden ports.
  - Use default port assignments if no custom ports are specified.
- **Remove VLAN**: Remove an existing VLAN by specifying its VLAN ID. Includes confirmation to prevent accidental deletion.

### Dependency Management
- **Check Dependencies**: Automatically verifies if the required `Posh-SSH` module is installed. If not, prompts the user to install it.

### Update Management
- **Check for Updates**: Automatically checks for the latest version of the tool on GitHub.

---

## Prerequisites

- **PowerShell**: Ensure PowerShell 5.1 or later is installed on your system.
- **Posh-SSH Module**: The script uses the `Posh-SSH` module for SSH connections. The script will install it automatically if not already installed.

---

## Installation

### 1. Using the PowerShell Script

1. Clone or download the repository to your local machine:
   ```bash
   git clone https://github.com/N30X420/Ghn-Manager.git
   ```

2. Navigate to the project directory:
   ```bash
   cd Ghn-Manager
   ```

3. Ensure the script has execution permissions:
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
   ```

4. Run the script:
   ```powershell
   .\Ghn-Manager.ps1
   ```

### 2. Using the Binary Release

1. Download the latest `.exe` release from the [Releases](https://github.com/N30X420/Ghn-Manager/releases) page.

2. Place the `.exe` file in your desired directory.

3. Run the `.exe` file:
   - Double-click the `.exe` file to launch the interactive menu.
   - Alternatively, execute it via the command line for non-interactive tasks:
     ```cmd
     Ghn-Manager.exe -RestartEndpoint -Mac 001e.6e04.147f -Address 192.168.1.1 -Username admin -Password password
     ```

---

## Usage

### 1. Interactive Mode

Run the script or `.exe` without any arguments to use the interactive menu:
```powershell
.\Ghn-Manager.ps1
```
or
```cmd
Ghn-Manager.exe
```

### 2. Non-Interactive Mode

You can pass command-line arguments to execute specific tasks directly.

#### Restart a G.hn Endpoint
```powershell
.\Ghn-Manager.ps1 -RestartEndpoint -Mac 001e.6e04.147f -Address 192.168.1.1 -Username admin -Password password
```
or
```cmd
Ghn-Manager.exe -RestartEndpoint -Mac 001e.6e04.147f -Address 192.168.1.1 -Username admin -Password password
```

#### Restart the G4200-4C or G4206C Device
```powershell
.\Ghn-Manager.ps1 -RestartG42004C -Address 192.168.1.1 -Username admin -Password password
```
or
```cmd
Ghn-Manager.exe -RestartG42004C -Address 192.168.1.1 -Username admin -Password password
```

### 3. Configuration File

The script and `.exe` use a `config.json` file to store default values for the host, username, and password. If the file does not exist, it will be created automatically with default values.

#### Location:
`C:\MATRIXNET\G.hn-Manager\config.json`

#### Example:
```json
{
    "Address": "192.168.1.1",
    "Username": "admin",
    "Password": "password",
    "Model": "G4206C"
}
```

If the configuration file is populated, the script or `.exe` will use these values unless overridden by command-line arguments.

---

## Logging

All actions and outputs are logged to a file for auditing and troubleshooting.

- **Log File Location**:
   `C:\MATRIXNET\G.hn-Manager\G.hn-Manager-<timestamp>.log`

---

## Troubleshooting

### Common Issues

1. **Permission Denied**:
   - Ensure the script has execution permissions:
     ```powershell
     Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
     ```

2. **Posh-SSH Module Not Installed**:
   - The script will prompt to install the module if missing. Ensure you have an active internet connection.

3. **Device Not Reachable**:
   - Verify the IP address or hostname of the device.
   - Check your network connection.
   - Ensure the device is powered on and accessible.

---

## Contributing

Contributions are welcome! Feel free to submit issues or pull requests to improve the script.

---

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

---

## Author

**Vincent**  
GitHub: (https://github.com/N30X420)

---

## Acknowledgments

- Thanks to the developers of the `Posh-SSH` module for enabling extended SSH functionality in PowerShell.
- Inspired by the need for efficient G.hn device management.

---
