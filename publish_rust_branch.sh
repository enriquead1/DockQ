#!/usr/bin/env bash
# Publish the experimental Rust implementation to an existing personal GitHub fork.
set -euo pipefail

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    cat <<'EOF'
Usage: bash publish_rust_branch.sh [GITHUB_USERNAME]

First create a fork of https://github.com/wallnerlab/DockQ on GitHub.
This script asks for your username if omitted, creates rust-implementation,
commits the Rust implementation and its validation files, and pushes to your fork.
It keeps origin unchanged and uses a remote named personal with SSH authentication.
Your SSH public key must be registered with GitHub. If setup is needed, the
script displays instructions before making repository changes.
EOF
    exit 0
fi

if (( $# > 1 )); then
    printf 'Usage: bash publish_rust_branch.sh [GITHUB_USERNAME]\n' >&2
    exit 1
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd -- "$script_dir"
git rev-parse --show-toplevel > /dev/null

username=${1:-}
if [[ -z "$username" ]]; then
    read -r -p 'Your GitHub username: ' username
fi
if [[ ! "$username" =~ ^[A-Za-z0-9]([A-Za-z0-9-]{0,37}[A-Za-z0-9])?$ ]]; then
    printf 'Invalid GitHub username: %s\n' "$username" >&2
    exit 1
fi

branch=rust-implementation
remote=personal
fork_url="git@github.com:${username}/DockQ.git"
https_url="https://github.com/${username}/DockQ.git"
fork_page="https://github.com/${username}/DockQ"

# A previous attempt may have staged these files before its commit failed.
# Allow that state, but do not include unrelated staged work in our commit.
while IFS= read -r -d '' staged_path; do
    case "$staged_path" in
        rust/*|compat/*|RUST_MIGRATION_PLAN.md|.github/workflows/rust.yml|.github/workflows/rust-release.yml|publish_rust_branch.sh) ;;
        *)
            printf 'Unrelated staged change: %s. Commit or unstage it, then rerun this script.\n' "$staged_path" >&2
            exit 1
            ;;
    esac
done < <(git diff --cached --name-only -z)
if [[ -n "$(git ls-files -u)" ]]; then
    printf 'Resolve the existing Git merge conflicts before running this script.\n' >&2
    exit 1
fi

existing_url=$(git remote get-url "$remote" 2>/dev/null || true)
if [[ -n "$existing_url" ]]; then
    case "$existing_url" in
        "$fork_url"|"$https_url"|"${https_url%.git}") ;;
        *)
            printf 'Remote %s already points to %s. No changes made.\n' "$remote" "$existing_url" >&2
            exit 1
            ;;
    esac
    push_url=$(git remote get-url --push "$remote")
    if [[ "$push_url" != "$existing_url" ]]; then
        printf 'Remote %s has a separate push URL (%s). Resolve this before publishing.\n' "$remote" "$push_url" >&2
        exit 1
    fi
fi

current_branch=$(git branch --show-current)
if [[ "$current_branch" != "$branch" ]] && git show-ref --verify --quiet "refs/heads/$branch"; then
    printf 'Branch %s already exists. Switch to it and rerun this script.\n' "$branch" >&2
    exit 1
fi

printf '\nChecking SSH authentication with GitHub (no GitHub account password is needed).\n'
printf 'On the first connection SSH may ask you to confirm the GitHub host key.\n'
ssh_status=0
ssh_output=$(ssh -o ConnectTimeout=15 -T git@github.com 2>&1) || ssh_status=$?
printf '%s\n' "$ssh_output"
# GitHub returns status 1 even when SSH authentication succeeds.
if [[ "$ssh_status" != 1 || "$ssh_output" != *'successfully authenticated'* ]]; then
    printf '\nSSH authentication is not ready. In your browser open:\n'
    printf 'https://github.com/settings/ssh/new\n'
    printf 'Add your SSH PUBLIC key as an authentication key, then rerun this script.\n'
    if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
        printf '\nYour public key (also available in %s):\n' "$HOME/.ssh/id_ed25519.pub"
        cat -- "$HOME/.ssh/id_ed25519.pub"
    elif [[ -f "$HOME/.ssh/id_rsa.pub" ]]; then
        printf '\nYour public key (also available in %s):\n' "$HOME/.ssh/id_rsa.pub"
        cat -- "$HOME/.ssh/id_rsa.pub"
    else
        printf 'No default public key was found. See https://docs.github.com/en/authentication/connecting-to-github-with-ssh\n'
    fi
    printf '\nIf the error concerns host verification, resolve it before adding a key.\n'
    exit 1
fi

authenticated_user=${ssh_output#*Hi }
authenticated_user=${authenticated_user%%!*}
if [[ "${authenticated_user,,}" != "${username,,}" ]]; then
    printf 'SSH authenticated as %s, but you entered %s. Rerun with the matching account.\n' "$authenticated_user" "$username" >&2
    exit 1
fi

printf 'Checking access to %s ...\n' "$fork_page"
if ! git ls-remote "$fork_url" HEAD > /dev/null; then
    printf '\nCould not access your fork. Create it at https://github.com/wallnerlab/DockQ/fork\n' >&2
    printf 'Then rerun this script. Expected repository: %s\n' "$fork_page" >&2
    exit 1
fi

# Verify commit identity before changing branches or staging files.
git var GIT_AUTHOR_IDENT > /dev/null
git var GIT_COMMITTER_IDENT > /dev/null

if [[ "$current_branch" != "$branch" ]]; then
    git switch -c "$branch"
fi
if [[ -z "$existing_url" ]]; then
    git remote add "$remote" "$fork_url"
elif [[ "$existing_url" != "$fork_url" ]]; then
    git remote set-url "$remote" "$fork_url"
fi

git add -- rust/ compat/ RUST_MIGRATION_PLAN.md \
    .github/workflows/rust.yml .github/workflows/rust-release.yml \
    publish_rust_branch.sh

if ! git diff --cached --quiet; then
    git diff --cached --stat
    git commit -m 'Add experimental Rust implementation and compatibility tests'
else
    printf 'No new implementation changes to commit; pushing the existing branch.\n'
fi

# A normal push rejects conflicting remote history; never force-push.
git push -u "$remote" "$branch"
printf '\nPublished: %s/tree/%s\n' "$fork_page" "$branch"
