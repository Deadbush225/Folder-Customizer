# Generic Linux Desktop Integration Framework

This framework provides standardized desktop integration for Linux applications with minimal configuration.

## Project Structure Requirements

To use this framework, your project must follow this structure:

```
your-project/
├── manifest.json          # Required: App metadata + desktop config
├── install.sh             # The generic desktop integration script
├── install/               # Required: Built application directory
│   ├── YourApp            # Main executable
│   ├── *.so*              # Shared libraries (optional)
│   └── other-files...     # Additional files
├── Icons/                 # Optional: Application icons
│   ├── YourApp.png        # Main icon
│   └── other-icons...
└── other-project-files...
```

## Required Files

### 1. manifest.json

Unified configuration with desktop integration:

```json
{
	"name": "Your Application Name",
	"version": "1.0.0",
	"description": "Brief description of your application",
	"desktop": {
		"desktop_name": "Display Name",
		"generic_name": "Generic Name",
		"comment": "Short description for menu",
		"categories": "Utility;Development;",
		"keywords": "keyword1;keyword2;keyword3",
		"mime_types": "application/x-custom",
		"executable": "YourApp",
		"icon_path": "Icons/YourApp.png",
		"package_id": "com.yourcompany.yourapp",
		"supports_files": true,
		"cli_helper": false
	}
}
```

### 2. install/ directory

Must contain your built application and dependencies.

## Desktop Configuration Options

The `desktop` section in `manifest.json` supports the following options:
"comment": "Detailed description for desktop file",
"categories": "Utility;Development;",
"keywords": "keyword1;keyword2;keyword3;",
"mime_types": "application/x-yourformat;",
"executable": "YourExecutableName",
"icon_path": "Icons/YourIcon.png",
"package_id": "your-app-id",
"supports_files": true,
"cli_helper": false
}

````

#### Configuration Options

| Field            | Description                           | Default            |
| ---------------- | ------------------------------------- | ------------------ |
| `desktop_name`   | Name shown in application menu        | From manifest.json |
| `generic_name`   | Generic application type              | Empty              |
| `comment`        | Description tooltip                   | From manifest.json |
| `categories`     | Desktop file categories               | "Utility;"         |
| `keywords`       | Search keywords (semicolon-separated) | Empty              |
| `mime_types`     | Supported file types                  | Empty              |
| `executable`     | Main executable filename              | Auto-detected      |
| `icon_path`      | Path to icon file                     | Auto-detected      |
| `package_id`     | System package identifier             | Auto-generated     |
| `supports_files` | Accept file arguments (%F)            | false              |
| `cli_helper`     | Has command-line helper tools         | false              |

## Usage

### Installation

```bash
# Copy the framework script to your project
cp generic-desktop-install.sh your-project/install.sh
chmod +x install.sh

# Install your application
./install.sh

# System-wide installation (requires sudo)
sudo ./install.sh
````

### Validation

```bash
# Check if desktop integration is working
./install.sh --validate
```

### Uninstallation

```bash
# Remove the application
./install.sh --uninstall
```

### Options

```bash
./install.sh --help          # Show help
./install.sh -y              # Skip confirmation prompts
./install.sh -d              # Enable debug output
```

## Auto-Detection Features

### Executable Detection

If `executable` is not specified in the desktop section, the framework will look for:

1. Exact app name from manifest.json
2. App name without spaces
3. App name in lowercase
4. "main"
5. "app"

### Icon Detection

If `icon_path` is not specified, the framework will look for:

- `Icons/{AppName}.{png,ico,svg}`
- `Icons/{AppNameNoSpaces}.{png,ico,svg}`
- `Icons/icon.{png,ico,svg}`
- `Icons/logo.{png,ico,svg}`

## Desktop File Generation

The framework generates compliant `.desktop` files with:

- Application menu integration
- File association support (if enabled)
- Search keywords
- Proper categorization
- Multiple actions (if applicable)

## Installation Locations

### User Installation (default)

- Executable: `~/.local/bin/{package_id}`
- Libraries: `~/.local/lib/{package_id}/`
- Desktop file: `~/.local/share/applications/{package_id}.desktop`
- Icon: `~/.local/share/icons/hicolor/256x256/apps/{package_id}.png`

### System Installation (with sudo)

- Executable: `/usr/bin/{package_id}`
- Libraries: `/usr/lib/{package_id}/`
- Desktop file: `/usr/share/applications/{package_id}.desktop`
- Icon: `/usr/share/icons/hicolor/256x256/apps/{package_id}.png`

## Examples

### Minimal Setup

Only `manifest.json` required:

```json
{
	"name": "My Cool App",
	"version": "1.0.0",
	"description": "Does cool things"
}
```

The framework will auto-detect everything else.

### Advanced Setup

With custom desktop integration:

```json
// manifest.json
{
	"name": "Advanced Editor",
	"version": "2.1.0",
	"description": "Advanced text editor with syntax highlighting",
	"desktop": {
		"desktop_name": "Advanced Editor",
		"generic_name": "Text Editor",
		"comment": "Advanced text editor with syntax highlighting and plugins",
		"categories": "Development;TextEditor;",
		"keywords": "editor;text;code;development;programming;",
		"mime_types": "text/plain;text/x-c;text/x-cpp;application/javascript;",
		"executable": "advanced-editor",
		"icon_path": "Icons/editor-icon.png",
		"package_id": "advanced-editor",
		"supports_files": true,
		"cli_helper": false
	}
}
```

## Integration with Build Systems

### CMake Integration

Add to your CMakeLists.txt:

```cmake
# Copy framework script during build
configure_file(
    ${CMAKE_SOURCE_DIR}/scripts/generic-desktop-install.sh
    ${CMAKE_BINARY_DIR}/install.sh
    COPYONLY
)

# Make it executable
file(CHMOD ${CMAKE_BINARY_DIR}/install.sh
     PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                 GROUP_READ GROUP_EXECUTE
                 WORLD_READ WORLD_EXECUTE)
```

### Makefile Integration

```makefile
install-desktop: build
	cp scripts/generic-desktop-install.sh ./install.sh
	chmod +x install.sh
	./install.sh

.PHONY: install-desktop
```

## Supported Desktop Environments

Tested and working on:

- GNOME
- KDE Plasma
- XFCE
- MATE
- Cinnamon
- Elementary OS
- Pop!\_OS
- Ubuntu Unity

## Troubleshooting

### Common Issues

**Application doesn't appear in menu:**

```bash
./install.sh --validate
update-desktop-database ~/.local/share/applications
```

**Icon not showing:**

```bash
gtk-update-icon-cache ~/.local/share/icons/hicolor
```

**Executable not found:**
Check that the executable name in the desktop section of manifest.json matches the actual file.

**Permission errors:**
Ensure the install/ directory and files have correct permissions.

### Debug Mode

```bash
./install.sh --debug
```

Shows all detected configuration values and paths.

## Contributing

To extend this framework:

1. Add new configuration options to the JSON parsing section
2. Update the `generate_desktop_file()` function for new desktop file features
3. Add validation checks in the validate action
4. Update this documentation

## License

This framework is designed to be embedded in your projects. Feel free to modify and redistribute as needed.
