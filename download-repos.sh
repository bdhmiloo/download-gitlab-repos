#!/bin/bash

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
script_name=$(basename "$0")
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
clone_location="${1:-$(pwd)}"

# GitLab configuration
gitlab_group_id="${GITLAB_GROUP_ID}"
gitlab_api_url="${GITLAB_BASE_URL}"
gitlab_base_url="${GITLAB_BASE_GIT_URL}"
encoded_group_id=$(echo "$gitlab_group_id" | sed 's|/|%2F|g')

# Initialize arrays
declare -a repo_array=()
declare -a exclude_list=()
exclude_file="${script_dir}/.exclude-list"

# Functions
usage() {
    printf "Usage: ./%s [clone_location]\n" "$script_name"
    printf "Example: ./%s /path/to/clone\n" "$script_name"
    exit 1
}

should_exclude() {
    local repo="$1"
    for excluded in "${exclude_list[@]}"; do
        if [ "$repo" = "$excluded" ]; then
            return 0  # true, should exclude
        fi
    done
    return 1  # false, should not exclude
}

# Load exclusion list
if [ -f "$exclude_file" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        [[ $line =~ ^#.*$ || -z $line ]] && continue  # Skip comments and empty lines
        exclude_list+=("$line")
    done < "$exclude_file"
else
    echo -e "${YELLOW}Warning: Exclude list file '$exclude_file' not found${NC}"
fi

# Validate arguments
if [ "$#" -eq 1 ] && [ "$1" == "help" ]; then
    usage
fi

if [ $# -gt 1 ]; then
    usage
fi

# Check required environment variables
check_env_vars() {
    local missing_vars=()

    [ -z "${GITLAB_TOKEN:-}" ] && missing_vars+=("GITLAB_TOKEN")
    [ -z "${GITLAB_GROUP_ID:-}" ] && missing_vars+=("GITLAB_GROUP_ID")
    [ -z "${GITLAB_BASE_URL:-}" ] && missing_vars+=("GITLAB_BASE_URL")
    [ -z "${GITLAB_BASE_GIT_URL:-}" ] && missing_vars+=("GITLAB_BASE_GIT_URL")

    if [ ${#missing_vars[@]} -ne 0 ]; then
        echo -e "${RED}Error: Missing required environment variables:${NC}"
        printf "${RED}  - %s${NC}\n" "${missing_vars[@]}"
        usage
    fi
}

check_env_vars

# Fetch repositories
echo -e "${BLUE}Fetching repository list from GitLab...${NC}"
repos=$(curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
    "${gitlab_api_url}/groups/${encoded_group_id}/projects?per_page=100" \
    | jq -r '.[].path_with_namespace')

if [ -z "$repos" ]; then
    echo -e "${RED}Error: No repositories found or invalid GitLab token${NC}"
    exit 1
fi

# Build repository array
while IFS= read -r line; do
    repo_array+=("$line")
done <<< "$repos"

echo -e "${GREEN}Found ${#repo_array[@]} repositories${NC}"

# Clone repositories
for repo in "${repo_array[@]}"
do
    if should_exclude "$repo"; then
        echo -e "${YELLOW}Skipping excluded repository: ${repo#${gitlab_group_id}/}${NC}"
        continue
    fi

    repo_path="${clone_location}/${repo#${gitlab_group_id}/}"

    if [ -d "$repo_path" ]; then
        echo -e "${YELLOW}Repository ${repo#${gitlab_group_id}/} already exists at $repo_path, skipping...${NC}"
    else
        echo -e "${GREEN}Cloning ${repo#${gitlab_group_id}/} into ${repo_path}...${NC}"
        mkdir -p "$(dirname "$repo_path")"
        git clone "${gitlab_base_url}${repo}.git" "$repo_path" &
    fi
done

wait

echo -e "${GREEN}Cloning completed.${NC}"