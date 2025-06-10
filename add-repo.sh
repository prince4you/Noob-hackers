#!/usr/bin/env bash
clear
# ========================
# Configuration Section
# ========================
REPO_NAME="Noob Hackers"
REPO_URL="https://raw.githubusercontent.com/prince4you/Noob-hackers/main"
REPO_KEY="$REPO_URL/Noob-hackers.key"
REPO_FILE="$PREFIX/etc/apt/sources.list.d/noob-backers.list"
LOGFILE="$HOME/noob_repo_install.log"
PKG_MANAGER="nala"  # Fallback to apt if nala not available

command -v pv >/dev/null 2>&1 || { echo "Installing pv..." && apt-get update >/dev/null 2>&1 && apt-get install -y pv >/dev/null 2>&1 && echo "Done"; }

# ========================
# Color Definitions
# ========================
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
PURPLE='\033[1;35m'
WHITE='\033[1;37m'
RESET='\033[0m'

# Symbols
CHECK="${GREEN}✓${RESET}"
CROSS="${RED}✗${RESET}"
INFO="${BLUE}ℹ${RESET}"
WARN="${YELLOW}⚠${RESET}"
ARROW="${CYAN}➜${RESET}"

# ========================
# Function Definitions
# ========================

# Generate random color
random_color() {
    colors=($RED $GREEN $YELLOW $BLUE $CYAN $PURPLE $WHITE)
    echo "${colors[$RANDOM % ${#colors[@]}]}"
}

# Animation function
animate() {
    local chars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    while :; do
        for char in "${chars[@]}"; do
            printf "\r%s %s" "$char" "$1"
            sleep 0.1
        done
    done
}

# Spinner for long running tasks
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    
    tput civis # Hide cursor
    while [ -d /proc/$pid ]; do
        local temp=${spinstr#?}
        printf "\r[%c] %s" "$spinstr" "$1"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
    done
    
    wait $pid
    local exit_code=$?
    tput cnorm # Restore cursor
    printf "\r[ ] %s\n" "$1"
    return $exit_code
}

# Header display with random colors
header() {
  clear
  COL1=$(random_color)
  COL2=$(random_color)
  COL3=$(random_color)

  echo -e "${COL1}                  ..............."
  echo -e "${COL1}              .........................."
  echo -e "${COL2}           ......',,;;;;;;;;;;;;;;,'......"
  echo -e "${COL2}        ......,;:;,''.....''''''',;::;,......"
  echo -e "${COL3}      .....';c:,'........',,,'......,;cc:'....."
  echo -e "${COL3}     ....':l;''.........',,,,'.......',;co:'...."
  echo -e "${COL1}    ....,lc,'....''.            .......'';ll,...."
  echo -e "${COL1}   ....,l:,'......'              ........',co,...."
  echo -e "${COL2}  ....,o:;,'.......               '......',;lo'...."
  echo -e "${COL2}  ...'ll:;,'..''..                ........',;ol...."
  echo -e "${COL3} ....,oc::,'.'                         ...',,cd,...."
  echo -e "${COL3} ....:oc::;,'''..                    .....'',:d;...."
  echo -e "${COL1} ....:oc:::;,''.',;              .;'......'',cd;...."
  echo -e "${COL1} ....,oc:::;,'.',co.             :l:......'',ld,...."
  echo -e "${COL2}  ....ll:::::;;:lol;             ;lc,'..''',;lc...."
  echo -e "${COL2}  ....'lc::clollodo'             ;c:;,,,'',;ll'...."
  echo -e "${COL3}   ....,lccloool:,..             ...',;;;;;lo'...."
  echo -e "${COL3}    ....'clc;.         V 2.0            .'l:...."
  echo -e "${COL1} "
  echo -e "${COL2}           [ Noob Hackers Repository Setup ]${RESET}"
  #echo -e "${COL3}              [ Repository Setup ]${RESET}"
  echo ""
}

# Check internet connectivity
check_internet() {
    echo -e "${INFO} ${CYAN}Checking internet connection...${RESET}" | pv -qL 50
    
    if ping -c 1 google.com &> /dev/null; then
        echo -e "${CHECK} ${GREEN}Internet connection verified${RESET}" | pv -qL 50
        return 0
    else
        echo -e "${CROSS} ${RED}No internet connection detected${RESET}" | pv -qL 50
        echo -e "${ARROW} ${YELLOW}Please check your network settings and try again${RESET}"
        exit 1
    fi
}

# Install dependencies
install_dependencies() {
    local required_pkgs=("pv" "nala" "x11-repo" "curl" "termux-apt-repo" "gnupg" "python2" "python")
    local missing_pkgs=()
    
    echo -e "${INFO} ${CYAN}Checking for required packages...${RESET}" | pv -qL 50
    
    # Check which packages are missing
    for pkg in "${required_pkgs[@]}"; do
        if ! dpkg -s "$pkg" &>/dev/null; then
            missing_pkgs+=("$pkg")
        fi
    done
    
    if [ ${#missing_pkgs[@]} -eq 0 ]; then
        echo -e "${CHECK} ${GREEN}All dependencies are already installed${RESET}" | pv -qL 40

        return 0
    fi

    echo -e "${ARROW} ${YELLOW}Installing missing packages: ${missing_pkgs[*]}${RESET}" | pv -qL 40
    
    # Update packages first
    if ! apt update -y &>> "$LOGFILE"; then
        echo -e "${CROSS} ${RED}Failed to update package lists${RESET}" | pv -qL 45
        exit 1
    fi
    
    # Install missing packages
    if ! apt install -y "${missing_pkgs[@]}" &>> "$LOGFILE"; then
        echo -e "${CROSS} ${RED}Failed to install dependencies${RESET}" | pv -qL 45
        echo -e "${ARROW} ${YELLOW}Trying with --fix-missing...${RESET}" | pv -qL 45
        if ! apt install -y --fix-missing "${missing_pkgs[@]}" &>> "$LOGFILE"; then
            exit 1
        fi
    fi
    
    echo -e "${CHECK} ${GREEN}All dependencies installed successfully${RESET}" | pv -qL 50
}

# Add repository
add_repository() {
    echo -e "${INFO} ${CYAN}Setting up ${REPO_NAME} repository...${RESET}" | pv -qL 55
    
    # Create directory if it doesn't exist
    if ! mkdir -p "$(dirname "$REPO_FILE")" &>> "$LOGFILE"; then
        echo -e "${CROSS} ${RED}Failed to create directory for repository file${RESET}" | pv -qL 50
        exit 1
    fi
    
    # Backup existing repo file if it exists
    if [ -f "$REPO_FILE" ]; then
        if ! cp "$REPO_FILE" "${REPO_FILE}.bak" &>> "$LOGFILE"; then
            echo -e "${WARN} ${YELLOW}Failed to backup existing repository file${RESET}" | pv -qL 50
        else
            echo -e "${ARROW} ${YELLOW}Existing repository file backed up to ${REPO_FILE}.bak${RESET}" | pv -qL 50
        fi
    fi
    
    # Create new repo file
    if ! echo "deb [trusted=yes arch=all] $REPO_URL Prince4you main" > "$REPO_FILE"; then
        echo -e "${CROSS} ${RED}Failed to add repository${RESET}" | pv -qL 45
        exit 1
    fi
    
    echo -e "${CHECK} ${GREEN}Repository added successfully${RESET}" | pv -qL 40
}

# Add GPG key
add_gpg_key() {
    echo -e "${INFO} ${CYAN}Adding repository GPG key...${RESET}" | pv -qL 40
    
    if ! command -v curl &> /dev/null; then
        echo -e "${ARROW} ${YELLOW}curl not found, installing...${RESET}" | pv -qL 40
        if ! apt install -y curl &>> "$LOGFILE"; then
            echo -e "${CROSS} ${RED}Failed to install curl${RESET}" | pv -qL 40
            exit 1
        fi
    fi
    
    if ! curl -sL "$REPO_KEY" | apt-key add - &>> "$LOGFILE"; then
        echo -e "${CROSS} ${RED}Failed to add GPG key${RESET}" | pv -qL 40
        exit 1
    fi
    
    echo -e "${CHECK} ${GREEN}GPG key added successfully${RESET}" | pv -qL 40
    
    # Move trusted.gpg file if it exists
    if [ -f "$PREFIX/etc/apt/trusted.gpg" ]; then
        mkdir -p "$PREFIX/etc/apt/trusted.gpg.d/"
        if ! mv "$PREFIX/etc/apt/trusted.gpg" "$PREFIX/etc/apt/trusted.gpg.d/" &>> "$LOGFILE"; then
            echo -e "${WARN} ${YELLOW}Could not move trusted.gpg file (not critical)${RESET}" | pv -qL 50
        else
            echo -e "${ARROW} ${YELLOW}Reorganized GPG keys for better management${RESET}" | pv -qL 40
        fi
    fi
}

# Update package lists
update_packages() {
    echo -e "${INFO} ${CYAN}Updating package lists...${RESET}" | pv -qL 35
    
    # Use nala if available, fallback to apt
    if command -v $PKG_MANAGER &> /dev/null; then
        echo -e "${ARROW} ${YELLOW}Using $PKG_MANAGER for faster downloads${RESET}" | pv -qL 40
        if ! $PKG_MANAGER update &>> "$LOGFILE"; then
            echo -e "${WARN} ${YELLOW}Failed with $PKG_MANAGER, falling back to apt${RESET}"
            if ! apt update &>> "$LOGFILE"; then
                echo -e "${CROSS} ${RED}Failed to update package lists${RESET}" | pv -qL 40
                exit 1
            fi
        fi
    else
        echo -e "${WARN} ${YELLOW}$PKG_MANAGER not found, using apt instead${RESET}"
        if ! apt update &>> "$LOGFILE"; then
            echo -e "${CROSS} ${RED}Failed to update package lists${RESET}" | pv -qL 40
            exit 1
        fi
    fi
    
    echo -e "${CHECK} ${GREEN}Package lists updated successfully${RESET}" | pv -qL 50
}

# Cleanup function
cleanup() {
    echo -e "\n${INFO} ${CYAN}Cleaning up...${RESET}"
    
    # Prompt to view log file
    read -p "$(echo -e "${ARROW} ${YELLOW}Would you like to view the installation log? [y/N]: ${RESET}")" choice
    case "$choice" in
        [Yy]* )
            echo -e "\n${INFO} ${CYAN}Displaying last 20 lines of log:${RESET}"
            tail -n 20 "$LOGFILE"
            ;;
    esac
    
    # Prompt to delete log file
    read -p "$(echo -e "${ARROW} ${YELLOW}Would you like to delete the log file? [y/N]: ${RESET}")" choice
    case "$choice" in
        [Yy]* )
            if rm -f "$LOGFILE"; then
                echo -e "${CHECK} ${GREEN}Log file removed successfully${RESET}" | pv -qL 40
            else
                echo -e "${WARN} ${YELLOW}Could not remove log file${RESET}" | pv -qL 50
            fi
            ;;
        * )
            echo -e "${ARROW} ${YELLOW}Log file preserved at: $LOGFILE${RESET}" | pv -qL 50
            ;;
    esac
}

# ========================
# Main Execution
# ========================

# Initialize log file
echo -e "=== ${REPO_NAME} Repository Installation Log ===" > "$LOGFILE" | pv -qL 50
echo -e "Started at: $(date)\n" >> "$LOGFILE"

# Show header
header

# Check for root
if [ "$(id -u)" -eq 0 ]; then
    echo -e "${WARN} ${RED}Warning: Running as root is not recommended in Termux${RESET}" | pv -qL 45
    sleep 2
fi

# Run all setup functions
check_internet
install_dependencies
add_repository
add_gpg_key
update_packages

# Completion message
echo -e "\n${GREEN}========================================${RESET}" | pv -qL 50
echo -e "${GREEN}✅ ${REPO_NAME} Repository Setup Complete!${RESET}" | pv -qL 50
echo -e "${GREEN}========================================${RESET}\n" | pv -qL 50

echo -e "${ARROW} ${CYAN}You can now install packages from ${REPO_NAME} repository${RESET}" | pv -qL 50
echo ""
apt list | grep "Prince4you"
echo ""
echo -e "${ARROW} ${CYAN}Example: ${WHITE}pkg install banner${RESET}\n" | pv -qL 45

# Cleanup
cleanup

exit 0

