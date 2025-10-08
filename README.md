# GitLab Repository Downloader

A shell script to bulk clone repositories from a GitLab group, with support for exclusions and color-coded output.

## Prerequisites

- Git
- curl
- jq
- Bash (recommended)
- GitLab access token

## Environment Variables

Set the following environment variables before running the script:

```bash
export GITLAB_TOKEN="your-gitlab-token"
export GITLAB_BASE_URL="https://sgts.gitlab-dedicated.com/api/v4"
export GITLAB_BASE_GIT_URL="git@sgts.gitlab-dedicated.com:"
export GITLAB_GROUP_ID="your-group-id"
```

## Usage

```bash
./download-repos.sh [clone_location]
```

- If no `clone_location` is provided, the current directory will be used.
- Run `./download-repos.sh help` for usage instructions.

### Creating an Alias

Add this to your `~/.bashrc` or `~/.zshrc`:

```bash
alias util-download-repos="~/Developer/scripts/download-repos/download-repos.sh"
```

## Excluding Repositories

Create a `.exclude-list` file in the same directory as the script to specify repositories to skip:

```text
# One repository per line
your-grou-id/repo-to-skip
your-grou-id/another-repo-to-skip
```

Lines starting with `#` or empty lines are ignored.

## Features

- Parallel repository cloning
- Repository exclusion support via `.exclude-list`
- Color-coded output for status and errors
- Environment variable configuration

## Troubleshooting

- If you see `Warning: Exclude list file '.exclude-list' not found`, create the file in the script directory.
- If you see an error about missing environment variables, ensure all required variables are exported.
- The script expects to be run with Bash and may not work with other shells.

## License

MIT License

