#!/usr/bin/env bash
# Update Caelestia on Fedora: pull the latest installer code and re-run setup.
export PATH="$HOME/.local/bin:$PATH"

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=scripts/lib/log.sh
source "${SCRIPT_DIR}/scripts/lib/log.sh"
# shellcheck source=scripts/lib/privileges.sh
source "${SCRIPT_DIR}/scripts/lib/privileges.sh"

section() {
    echo
    echo "-------------------------------------------------------------"
    echo "  $1"
    echo "-------------------------------------------------------------"
}

export BUNDLE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$BUNDLE_DIR" || die "Could not enter $BUNDLE_DIR"

exec 9>"${XDG_RUNTIME_DIR:-/tmp}/caelestia-update.lock"
flock -n 9 || { echo "Another Caelestia update is already running."; exit 1; }

section "Step 1 - Source Code Update"

info "Checking dependencies..."
for cmd in git bash; do
    if ! command -v "$cmd" &> /dev/null; then
        die "Required command '$cmd' is missing. Please install it first."
    fi
done

if [ -d "$BUNDLE_DIR/.git" ]; then
    info "Fetching remote branches..."
    git -C "$BUNDLE_DIR" fetch origin || warn "Failed to fetch from origin. Network issue?"

    STASHED=0
    if ! git -C "$BUNDLE_DIR" diff-index --quiet HEAD --; then
        warn "You have uncommitted changes in the repository."
        info "Stashing your local changes..."
        git -C "$BUNDLE_DIR" stash -m "Auto-stash before Caelestia update" || die "Failed to stash changes."
        STASHED=1
    fi

    BRANCH="${CAELESTIA_BRANCH:-main}"
    info "Using branch: $BRANCH"

    info "Checking out $BRANCH..."
    git -C "$BUNDLE_DIR" checkout "$BRANCH" || die "Failed to checkout $BRANCH"

    info "Pulling latest changes for $BRANCH..."
    git -C "$BUNDLE_DIR" pull origin "$BRANCH" || die "Failed to pull from origin/$BRANCH"

    if [[ -f "$BUNDLE_DIR/.gitmodules" ]]; then
        info "Syncing submodules..."
        git -C "$BUNDLE_DIR" submodule sync --recursive >/dev/null 2>&1 || true
        git -C "$BUNDLE_DIR" submodule update --init --recursive || \
            die "Failed to initialize submodules"
    fi

    if [ "$STASHED" -eq 1 ]; then
        echo
        warn "Your local uncommitted changes were backed up to the git stash to allow a clean update."
        warn "If you need to recover them, you can manually run 'git stash pop' later."
    fi
else
    warn "Not a git repository. Skipping source code update."
fi

section "Step 2 - Re-run Installer"

if [[ -f "$HOME/.config/caelestia/install.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    . "$HOME/.config/caelestia/install.env"
    set +a
fi

bash "$BUNDLE_DIR/install.sh"

section "Update Completed Successfully"
echo
info "Caelestia has been updated. Log out and back in to apply all changes."
