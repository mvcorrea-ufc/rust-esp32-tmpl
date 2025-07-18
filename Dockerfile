# Use the 'slim' version of Debian for a significantly smaller footprint.
FROM debian:bullseye-slim

# Set the APT frontend to non-interactive to avoid prompts during the build.
ENV DEBIAN_FRONTEND=noninteractive

# --- Dependency Installation ---
# Update packages and install essential dependencies for compilation (build-essential),
# hardware communication (libudev-dev), script downloading (curl), version control (git),
# the SSH server, and sudo for elevated privileges.
RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    libudev-dev \
    curl \
    git \
    neovim usbutils \
    openssh-server \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# --- User and Toolchain Installation ---

# Create a 'vscode' user with a standard UID. Podman's userns_mode will handle mapping.
RUN useradd -m -s /bin/bash -u 1000 vscode
# Set a simple password ('vscode').
RUN echo 'vscode:vscode' | chpasswd
# Add the user to the 'dialout' group for serial port access.
RUN usermod -aG dialout vscode
# Grant passwordless sudo privileges to the 'vscode' user.
RUN echo "vscode ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/vscode && \
    chmod 0440 /etc/sudoers.d/vscode
# Update sshd_config to robustly enable password auth and disable root login.
RUN sed -i 's/^#?PermitRootLogin .* /PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/^#?PasswordAuthentication .* /PasswordAuthentication yes/' /etc/ssh/sshd_config


# Switch to the 'vscode' user to install the Rust toolchain in their home directory.
USER vscode
WORKDIR /home/vscode

# Install Rust via rustup.
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
# Add the Cargo bin directory to the user's PATH.
ENV PATH="/home/vscode/.cargo/bin:${PATH}"

# Install the cross-compilation target for the ESP32-C3.
RUN rustup target add riscv32imc-unknown-none-elf

# Install espflash and ldproxy for the user.
RUN cargo install espflash ldproxy

# Create the .ssh directory as the 'vscode' user for correct ownership.
RUN mkdir /home/vscode/.ssh && chmod 700 /home/vscode/.ssh

# Ensure the vscode user owns their home directory as a safeguard.
RUN chown -R vscode:vscode /home/vscode /workspace

# --- Finalization ---
# Set the default working directory for the project.
WORKDIR /workspace

# Expose port 22 to allow external SSH connections.
EXPOSE 22

# Default command to start the container. The UID/GID mapping handles permissions.
CMD ["/usr/sbin/sshd", "-D"]

