#!/bin/bash
# Author: Antonio D'Angelo

# Function to check if a command is installed
check_command() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install a package using Homebrew on macOS
install_with_brew() {
    brew install "$1"
}

# Function to install a package using APT on Debian-based systems
install_with_apt() {
    sudo apt-get update
    sudo apt-get install -y "$1"
}

# Function to install a package using DNF on Fedora
install_with_dnf() {
    sudo dnf install -y "$1"
}

# Function to install a package using Pacman on Arch Linux
install_with_pacman() {
    sudo pacman -Syu --noconfirm "$1"
}

# Function to install deepsecrets using pip
install_deepsecrets() {
    pip install deepsecrets
}


# Check and install dependencies
echo "Checking dependencies..."

# jq
if ! check_command "jq"; then
    echo "jq is not installed. Installing..."
    if [ "$(uname)" == "Darwin" ]; then
        install_with_brew "jq"
    elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
        if command -v apt-get &> /dev/null; then
            install_with_apt "jq"
        elif command -v dnf &> /dev/null; then
            install_with_dnf "jq"
        elif command -v pacman &> /dev/null; then
            install_with_pacman "jq"
        else
            echo "Unsupported package manager. Please install jq manually."
            exit 1
        fi
    else
        echo "Unsupported operating system. Please install jq manually."
        exit 1
    fi
fi

# Check and install Python 3
if ! check_command "python3"; then
    echo "Python 3 is not installed. Installing..."
    install_with_brew "python" # This may need to be adjusted based on the user's system
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    python3 get-pip.py
    rm get-pip.py
fi

# Check and install pip
if ! check_command "pip"; then
    echo "pip is not installed. Installing..."
    install_with_brew "python" # This may need to be adjusted based on the user's system
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    python3 get-pip.py
    rm get-pip.py
fi

# Check and install deepsecrets
if ! check_command "deepsecrets"; then
    echo "deepsecrets is not installed. Installing..."
    install_deepsecrets
fi

# Check and install git
if ! check_command "git"; then
    echo "git is not installed. Installing..."
    install_git
fi

# Prompt user for GitLab personal access token
read -s -p "Enter your GitLab personal access token: " GITLAB_ACCESS_TOKEN

# GitLab API URL to get the list of groups associated with the access token
GROUPS_API_URL="https://gitlab.com/api/v4/groups?private_token=$GITLAB_ACCESS_TOKEN"

# Fetching groups
groups=$(curl -s "$GROUPS_API_URL" | jq -r '.[] | "\(.id) \(.path) \(.name)"')

# Check if groups is null or empty
if [ -z "$groups" ] || [ "$groups" == "null" ]; then
    echo "Error fetching GitLab groups. Please check your GitLab Access Token."
    exit 1
fi

# Display available groups for selection
echo "Available GitLab Groups:"
echo "$groups"

# Prompt user to choose a group
read -p "Enter the ID of the GitLab group you want to use: " GROUP_ID

# GitLab API URL to get the list of projects under the selected group
GROUP_API_URL="https://gitlab.com/api/v4/groups/$GROUP_ID/projects?private_token=$GITLAB_ACCESS_TOKEN"

# Folder to store all repositories
OUTPUT_FOLDER="gitlab_repositories"

# Clone all repositories using the git protocol
echo "Cloning Repositories..."
mkdir -p "$OUTPUT_FOLDER"

# Fetching repositories
repo_urls=$(curl -s "$GROUP_API_URL" | jq -r '.[].http_url_to_repo')

# Check if repo_urls is null or empty
if [ -z "$repo_urls" ] || [ "$repo_urls" == "null" ]; then
    echo "Error fetching repository URLs. Please check your GitLab Access Token and group ID."
    exit 1
fi

# Iterate over repo_urls and clone each repository
for repo_url in $repo_urls; do
    # Extract the repository name without the .git extension
    repo_name=$(basename "$repo_url" .git)

    # Extract the repo_url without the https:// prefix
    repo_url_without_protocol=${repo_url#*@}

    # Construct the repo URL with access token for HTTPS
    repo_url_with_token="https://oauth2:${GITLAB_ACCESS_TOKEN}@${repo_url_without_protocol}"

    # Remove any extra "https://" at the beginning or after the '@' symbol - i know...there is for sure some smarter way to handle this
    repo_url_with_token="${repo_url_with_token#https://}"
    repo_url_with_token="${repo_url_with_token/@https:\/\//@}"

    # Ensure "oauth2" has "https://" before it
    repo_url_with_token="${repo_url_with_token/oauth2/https://oauth2}"

    git clone "$repo_url_with_token" "$OUTPUT_FOLDER/$repo_name"
done

# Run deepsecrets for each repository
echo "Running deepsecrets..."
for repo_folder in "$OUTPUT_FOLDER"/*; do
    if [ -d "$repo_folder" ]; then
        repo_name=$(basename "$repo_folder")
        target_dir="$repo_folder"

        # Run deepsecrets
        deepsecrets --target-dir "$target_dir" --outfile "report-$repo_name.json"

        echo "Deepsecrets completed for $repo_name. Report saved to report-$repo_name.json"
    fi
done

echo "Task completed!"
