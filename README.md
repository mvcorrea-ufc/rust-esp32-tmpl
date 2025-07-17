# Rust on ESP32 (RISC-V) Template with Podman and VS Code

This is a template for starting Rust projects on RISC-V ESP32 microcontrollers (like the ESP32-C3, C6, S3, H2), using a containerized development environment with Podman and VS Code for remote development.

The project is structured as a **Cargo Workspace**, making it easy to manage multiple related crates (e.g., firmware, libraries) in the future.

## Features

-   **Cargo Workspace:** The project is organized in `workspace/blink`, allowing for easy expansion.
-   **Optimized and Isolated Environment:** Uses a `debian:slim` image for a lightweight container. All dependencies (Rust, `espflash`, etc.) are contained within it.
-   **"Blink" Example:** Includes starter code that blinks an LED using the `esp-hal` crate.
-   **Multi-Chip Support:** Easily adaptable for different MCUs in the ESP32 RISC-V family.
-   **VS Code Integration:** Configured for remote development via SSH, allowing you to edit, compile, and flash from within the container directly from your editor.

---

## How to Use This Template

Follow these steps to clone this template, set up the environment, and push it to your own new repository.

### 1. Create Your Own Repository from This Template

1.  **Create a new repository on GitHub/GitLab.** Choose a name for your project. Do **not** initialize it with a README, .gitignore, or license file, as we will use the ones from the template.
2.  **Clone this template repository** to your local machine using the `--bare` option. This creates a bare clone that includes the complete history but no working directory.
    ```bash
    git clone --bare <TEMPLATE_REPOSITORY_URL>
    cd <TEMPLATE_REPOSITORY_NAME>.git
    ```
3.  **Push the mirrored repository** to your new, empty repository.
    ```bash
    # Replace <YOUR_NEW_REPO_URL> with the URL of the repository you created in step 1.
    git push --mirror <YOUR_NEW_REPO_URL>
    ```
4.  **Remove the temporary local clone.**
    ```bash
    cd ..
    rm -rf <TEMPLATE_REPOSITORY_NAME>.git
    ```
5.  **Clone your new repository** to your local machine. This is where you will work.
    ```bash
    git clone <YOUR_NEW_REPO_URL>
    cd <YOUR_NEW_REPOSITORY_NAME>
    ```

You now have a new project with the complete history of the template, ready for you to start committing your own changes.

### 2. Build and Start the Container

With Podman and Podman Compose installed, run the following commands in your terminal at the project root:

```bash
# Build the container image (this may take a few minutes the first time)
podman-compose build

# Start the container in detached mode (in the background)
podman-compose up -d
```

### 3. Connect with VS Code

1.  Open VS Code.
2.  Open the command palette (`Ctrl+Shift+P` or `Cmd+Shift+P`).
3.  Type and select **"Remote-SSH: Connect to Host..."**.
4.  Select **"Add New SSH Host..."** and enter: `ssh vscode@localhost -p 2222`.
5.  When prompted, the password is `vscode`.
6.  A new VS Code window will open. Click **"Open Folder"** and open the `/home/vscode/project` directory.

### 4. Configure the USB Device

For the container to access your ESP32's USB port, you need to edit `podman-compose.yml`.

1.  **On your host computer**, find the device path (usually `/dev/ttyUSB0` or `/dev/ttyACM0`).
    ```bash
    ls /dev/tty*
    ```
2.  Open `podman-compose.yml` and uncomment the `devices` section, replacing the placeholder with your device path.
3.  **Restart the container** to apply the changes:
    ```bash
    podman-compose down && podman-compose up -d
    ```
4.  Reconnect the VS Code SSH session if necessary.

### 5. Compile and Flash

1.  Open a new terminal inside VS Code (`Terminal > New Terminal`).
2.  Run the command to compile, flash, and monitor the `blink` crate:
    ```bash
    # The -p flag specifies which package in the workspace to build and run
    cargo espflash flash -p blink --monitor
    ```

---

## Adapting for Other Microcontrollers (ESP32-C6, S3, H2)

This template defaults to the ESP32-C3. To adapt it, you'll need to modify the configuration files inside the `workspace/blink` directory.

### Step 1: Modify `workspace/blink/Cargo.toml`

Change the `features` for `esp-hal`, `esp-backtrace`, and `esp-println` to match your chip.

### Step 2: Modify `workspace/blink/.cargo/config.toml`

Check the `esp-hal` documentation for your chip and adjust the build `target` if necessary (e.g., to `riscv32imac-unknown-none-elf` for an ESP32-C6).

### Step 3: Update the `Dockerfile` (If Necessary)

If you changed the build `target`, ensure it's installed in the container. Uncomment the corresponding `RUN rustup target add ...` line in the root `Dockerfile` and rebuild the image with `podman-compose build`.

### Step 4: Check the LED Pin

The code in `workspace/blink/src/main.rs` uses `gpio8`. Check your board's schematic and adjust the pin if needed.