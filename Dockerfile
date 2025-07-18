# Use the 'slim' version of Debian for a significantly smaller footprint.
FROM debian:bullseye-slim

# Set the APT frontend to non-interactive to avoid prompts during the build.
ENV DEBIAN_FRONTEND=noninteractive

# --- Dependency Installation ---
# Update packages and install essential dependencies for compilation (build-essential),
# hardware communication (libudev-dev), script downloading (curl), version control (git),
# and the SSH server for remote development.
RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    libudev-dev \
    curl \
    git \
    neovim usbutils \
    openssh-server \
    && rm -rf /var/lib/apt/lists/*

# --- Rust Installation ---
# Install Rust via rustup, the recommended tool for managing Rust toolchains.
# The '-y' flag automates the installation.
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
# Add the Cargo bin directory to the system's PATH.
ENV PATH="/root/.cargo/bin:${PATH}"

# --- ESP Toolchain Installation ---
# Install the cross-compilation target for the base RISC-V architecture (IMC).
# This target is used by the ESP32-C3.
RUN rustup target add riscv32imc-unknown-none-elf

# To use other RISC-V ESP32 chips, you will need different targets.
# Uncomment the lines below according to your needs.
#
# For ESP32-C6 and ESP32-S3 (which use the 'A' extension for atomics):
# RUN rustup target add riscv32imac-unknown-none-elf
#
# For ESP32-H2 (which uses 'A' and 'F' extensions for floating point):
# RUN rustup target add riscv32imafc-unknown-none-elf

# Install espflash (for flashing the firmware to the chip) and ldproxy (for the linker).
RUN cargo install espflash ldproxy

# --- User and SSH Configuration ---
# Create a 'vscode' user to avoid working as root in day-to-day tasks.
RUN useradd -m -s /bin/bash vscode
# Set a simple password ('vscode'). For production or exposed environments,
# it is HIGHLY recommended to use SSH key-based authentication.
RUN echo 'vscode:vscode' | chpasswd
# Add the user to the 'sudo' group (for administrative tasks) and 'dialout' (for serial port access).
RUN usermod -aG sudo vscode
RUN usermod -aG dialout vscode

# Configure the SSH server.
RUN mkdir -p /var/run/sshd /home/vscode/.ssh && chmod 700 /home/vscode/.ssh

# Update sshd_config to robustly enable password auth and disable root login.
RUN sed -i 's/^#?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/^#?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Ensure the vscode user owns their home directory.
RUN chown -R vscode:vscode /home/vscode

# --- Finalization ---
# Set the default working directory for the project.
WORKDIR /workspace

# Expose port 22 to allow external SSH connections.
EXPOSE 22

# Default command to start the container:
# 1. Fix ownership of the mounted workspace volume.
# 2. Run the SSH daemon in the foreground.
CMD ["sh", "-c", "chown -R vscode:vscode /workspace && /usr/sbin/sshd -D"]
