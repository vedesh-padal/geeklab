#!/bin/bash

# Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
NC="\033[0m" # No Color

# Helper to display header
print_header() {
    echo -e "\n${YELLOW}== $1 ==${NC}"
}

# APT Packages
check_apt_updates() {
    print_header "APT Packages with Updates"
    apt list --upgradable 2>/dev/null | tail -n +2 > /tmp/apt-upgrades.txt

    if [[ ! -s /tmp/apt-upgrades.txt ]]; then
        echo "No APT updates available."
        return
    fi

    awk -F' ' '{printf "%-30s %s → %s\n", $1, $2, $3}' /tmp/apt-upgrades.txt
}

# SNAP Packages
check_snap_updates() {
    print_header "Snap Packages with Updates"
    snap refresh --list > /tmp/snap-upgrades.txt

    if [[ ! -s /tmp/snap-upgrades.txt ]]; then
        echo "No Snap updates available."
        return
    fi

    tail -n +2 /tmp/snap-upgrades.txt | awk '{printf "%-30s %s → %s\n", $1, $2, $4}'
}

# FLATPAK Packages
check_flatpak_updates() {
    print_header "Flatpak Packages with Updates"
    flatpak remote-ls --updates --columns=name,application,version > /tmp/flatpak-upgrades.txt

    if [[ ! -s /tmp/flatpak-upgrades.txt ]]; then
        echo "No Flatpak updates available."
        return
    fi

    cat /tmp/flatpak-upgrades.txt
}

# Install updates selectively
install_updates() {
    echo -e "\n${YELLOW}Which updates do you want to install?${NC}"
    echo "1. All"
    echo "2. Only APT"
    echo "3. Only Snap"
    echo "4. Only Flatpak"
    echo "5. Select manually"
    echo "6. Skip all"
    read -rp "Choose option [1-6]: " choice

    case $choice in
        1)
            sudo apt upgrade -y
            sudo snap refresh
            flatpak update -y
            ;;
        2)
            sudo apt upgrade -y
            ;;
        3)
            sudo snap refresh
            ;;
        4)
            flatpak update -y
            ;;
        5)
            manual_update_menu
            ;;
        *)
            echo "Skipping updates."
            ;;
    esac
}

# Manual selection
manual_update_menu() {
    echo -e "${YELLOW}Manual Update Options${NC}"
    echo -e "\nAPT:"
    awk -F' ' '{print NR ". " $1}' /tmp/apt-upgrades.txt
    read -rp "Enter APT packages to update (e.g., 1 3 4): " apt_choices
    for i in $apt_choices; do
        pkg=$(awk -v i="$i" 'NR==i {print $1}' /tmp/apt-upgrades.txt)
        sudo apt install -y "$pkg"
    done

    echo -e "\nSnap:"
    tail -n +2 /tmp/snap-upgrades.txt | awk '{print NR ". " $1}'
    read -rp "Enter Snap packages to refresh: " snap_choices
    for i in $snap_choices; do
        pkg=$(tail -n +2 /tmp/snap-upgrades.txt | awk -v i="$i" 'NR==i {print $1}')
        sudo snap refresh "$pkg"
    done

    echo -e "\nFlatpak:"
    awk 'NR>1 {print NR-1 ". " $1}' /tmp/flatpak-upgrades.txt
    read -rp "Enter Flatpak packages to update: " flatpak_choices
    for i in $flatpak_choices; do
        pkg=$(awk 'NR>1 {print NR-1 ". " $1}' /tmp/flatpak-upgrades.txt | awk -v i="$i" 'NR==i {print $2}')
        flatpak update -y "$pkg"
    done
}

main() {
    echo -e "${GREEN}Checking for available updates...${NC}"
    check_apt_updates
    check_snap_updates
    check_flatpak_updates

    install_updates
}

main

