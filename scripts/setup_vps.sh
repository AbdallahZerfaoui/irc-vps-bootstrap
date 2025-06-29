#!/bin/bash

# =================================================================
# Debian VPS Initialization Script
#
# This script will:
# 1. Update the system.
# 2. Set a custom, colorful bash prompt for root and new users.
# 3. Install a set of useful tools (git, htop, ufw, etc.).
# 4. Install Docker and Docker Compose.
# 5. Configure a basic firewall (UFW).
# 6. Create three new users with sudo and docker privileges.
#
# USAGE: Run as root on a fresh Debian system.
# ./setup_vps.sh
# =================================================================

# --- Script Configuration ---
# List of new users to create
USERS=("main" "abdallah" "tobias")

# The fancy new bash prompt
NEW_PS1="PS1='\\[\\033[1;32m\\]\\u@\\h\\[\\033[0;36m\\]:\\[\\033[1;34m\\]\\w\\[\\033[0m\\]# '"

# --- Helper Functions ---
print_info() {
    echo -e "\n\e[1;36m[INFO] $1\e[0m"
}

print_success() {
    echo -e "\e[1;32m[SUCCESS] $1\e[0m"
}

print_error() {
    echo -e "\e[1;31m[ERROR] $1\e[0m" >&2
}

# --- Pre-flight Check ---
# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
   print_error "This script must be run as root."
   exit 1
fi

# --- Main Execution ---

# 1. System Update
print_info "Updating package lists and upgrading the system..."
apt-get update
apt-get upgrade -y
print_success "System updated."

# 2. Set Custom Bash Prompt for root
print_info "Setting custom bash prompt for root user..."
# Avoid adding the line if it already exists
if ! grep -qF "$NEW_PS1" /root/.bashrc; then
    echo -e "\n# Custom PS1 Prompt\n$NEW_PS1" >> /root/.bashrc
    print_success "Custom prompt added to /root/.bashrc"
else
    print_info "Custom prompt already exists for root."
fi

# 3. Install Essential Tools
print_info "Installing essential tools: sudo, ufw, git, curl, htop, fail2ban, etc..."
apt-get install -y \
    sudo \
    ufw \
    git \
    curl \
    wget \
    htop \
    neofetch \
    unzip \
    zip \
    fail2ban \
    vim \
    nano \
    ca-certificates \
    gnupg
print_success "Essential tools installed."

# 4. Install Docker and Docker Compose
print_info "Installing Docker and Docker Compose..."
# Add Docker's official GPG key
install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
fi

# Set up the repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine, CLI, Containerd, and Compose plugin
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
print_success "Docker and Docker Compose installed."

# 5. Configure Firewall (UFW)
print_info "Configuring basic firewall (UFW)..."
ufw allow OpenSSH # IMPORTANT: Allow SSH connections
ufw allow http    # Allow standard web traffic
ufw allow https   # Allow secure web traffic
# --- ADD THIS PART ---
print_info "Allowing custom Docker application ports..."
ufw allow 5550/tcp # Custom port for Docker app 1
ufw allow 5555/tcp # Custom port for Docker app 2
ufw allow 5556/tcp # Custom port for Docker app 3
# --- END OF ADDITION ---
ufw --force enable
print_success "Firewall enabled. Status:"
ufw status

# 6. Add New Users
print_info "Creating new users: ${USERS[*]}..."
for user in "${USERS[@]}"; do
    if id "$user" &>/dev/null; then
        print_info "User '$user' already exists. Skipping creation."
    else
        # Create user with home directory and bash as default shell
        useradd -m -s /bin/bash "$user"
        print_success "User '$user' created."

        # Add user to sudo and docker groups
        usermod -aG sudo "$user"
        usermod -aG docker "$user"
        print_success "User '$user' added to 'sudo' and 'docker' groups."

        # Set custom prompt for the new user
        USER_BASHRC="/home/$user/.bashrc"
        echo -e "\n# Custom PS1 Prompt\n$NEW_PS1" >> "$USER_BASHRC"
        chown "$user":"$user" "$USER_BASHRC"
        print_success "Custom prompt added for user '$user'."
    fi
done

# 7. Clone the IRC Project Repositories
mkdir branches
print_info "Cloning IRC project repositories..."
# Clone the main repository
git clone -b main https://github.com/AbdallahZerfaoui/IRC.git branches/main
print_success "Cloned main repository."

# Clone the abdallah branch
git clone -b dev-abdallah https://github.com/AbdallahZerfaoui/IRC.git branches/dev-abdallah
print_success "Cloned abdallah branch."

# Clone the tobias branch
git clone -b dev-tobias https://github.com/AbdallahZerfaoui/IRC.git branches/dev-tobias
print_success "Cloned tobias branch."

# --- Final Instructions ---
echo
echo -e "\e[1;32m===============================================================\e[0m"
print_success "VPS Initialization Script Finished!"
echo -e "\e[1;33m"
echo "IMPORTANT NEXT STEPS:"
echo "1. You MUST set a password for each new user. Run the following commands:"
for user in "${USERS[@]}"; do
    echo "   passwd $user"
done
echo
echo "2. It is recommended to reboot the server to apply all changes:"
echo "   reboot"
echo
echo "3. After rebooting, log out of the 'root' account and log back in"
echo "   using one of your new user accounts (e.g., 'ssh main@your_vps_ip')."
echo -e "\e[1;32m===============================================================\e[0m"
echo

# Source the new .bashrc for the current root session to see the change immediately
source /root/.bashrc
