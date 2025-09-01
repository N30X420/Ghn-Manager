# G.hn-Manager

G.hn-Manager is a PowerShell-based tool designed to manage and interact with G.hn devices, such as the G4200-4C. It provides an interactive menu for managing connections, restarting endpoints, and performing other administrative tasks. The tool also supports non-interactive execution using command-line arguments or a configuration file.

---

## Features

- **Interactive Menu**: Navigate through various management options using an intuitive menu.
- **Non-Interactive Mode**: Execute specific tasks directly via command-line arguments.
- **Configuration File**: Predefine device details (host, username, password) in a `config.json` file for convenience.
- **Dependency Management**: Automatically checks and installs required dependencies (e.g., `Posh-SSH` module).
- **Logging**: Logs all actions and outputs to a log file for auditing and troubleshooting.
- **SSH Connection Management**: Establishes and manages SSH connections to G.hn devices.
- **Endpoint Management**: Restart specific G.hn endpoints by MAC address.
- **Device Reboot**: Restart the G4200-4C device with optional automatic confirmation.
- **Binary Release**: A compiled `.exe` version is available for users who prefer not to run the PowerShell script directly.

---

## Prerequisites

- **PowerShell**: Ensure PowerShell is installed on your system (required for the script version).
- **Posh-SSH Module**: The script uses the `Posh-SSH` module for SSH connections. The script will install it automatically if not already installed.

---

## Installation

### 1. Using the PowerShell Script

1. Clone or download the repository to your local machine:
   ```bash
   git clone https://github.com/your-repo/Ghn-Manager.git
   ```

2. Navigate to the project directory:
   ```bash
   cd Ghn-Manager
   ```

3. Ensure the script has execution permissions:
   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
   ```

### 2. Using the Binary Release

1. Download the latest `.exe` release from the [Releases](https://github.com/your-repo/Ghn-Manager/releases) page.

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

#### Restart the G4200-4C Device
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
`C:\MATRIXNET\G.hn-Manager-1.0\config.json`

#### Example:
```json
{
    "Address": "192.168.1.1",
    "Username": "admin",
    "Password": "password"
}
```

If the configuration file is populated, the script or `.exe` will use these values unless overridden by command-line arguments.

---

## Features in Detail

### Interactive Menu Options

1. **Check Dependencies**:
   - Verifies if the `Posh-SSH` module is installed.
   - Installs the module if missing.

2. **Connect / Disconnect G4200-4C**:
   - Establishes or terminates an SSH connection to the G4200-4C device.

3. **Open Shell**:
   - Opens an interactive shell session with the G.hn device.

4. **Show Connected G.hn Endpoints**:
   - Displays a list of connected G.hn endpoints.

5. **Restart G.hn Endpoint**:
   - Restarts a specific G.hn endpoint by its MAC address.

6. **Restart G4200-4C**:
   - Restarts the G4200-4C device with optional automatic confirmation.

7. **Exit**:
   - Closes the program and cleans up resources.

---

## Logging

All actions and outputs are logged to a file for auditing and troubleshooting.

- **Log File Location**:
  `C:\MATRIXNET\G.hn-Manager-1.0\G.hn-Manager-1.0-<timestamp>.log`

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
   - Device is offline

---

## Contributing

Contributions are welcome! Feel free to submit issues or pull requests to improve the script.

---

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

---

## Author

**Vincent**  
GitHub: [Vincent](https://github.com/your-profile)

---

## Acknowledgments

- Thanks to the developers of the `Posh-SSH` module for enabling extended SSH functionality in PowerShell.
- Inspired by the need for efficient G.hn device management.

