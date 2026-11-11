#!/bin/sh

set -eu

# Run the setup from this checkout, never whatever scripts/setup.sh happens to
# sit in the current directory.
unset CDPATH
SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)

# --help has to work even without a terminal.
case " $* " in
    *" --help "*|*" -h "*)
        if [ -f "$SCRIPT_DIR/scripts/setup.sh" ]; then
            exec bash "$SCRIPT_DIR/scripts/setup.sh" --help
        fi
        printf '%s\n' "Usage: install.sh [--yes] [--dry-run] [--vm] [--help]"
        exit 0
        ;;
esac

# TTY handling: if stdin is not a terminal, reopen /dev/tty so interactive
# prompts (sudo, confirm, gum) still work when piped or launched from a menu.
# /dev/tty exists even when there is no controlling terminal, so probe it by
# actually opening it rather than testing for the device node.
tty_usable() {
    ( exec 0<>/dev/tty ) 2>/dev/null
}
{
if [ ! -t 0 ]; then
    REAL_TTY=""
    if [ -t 1 ]; then
        REAL_TTY=$(tty 0>&1 2>/dev/null || true)
    elif [ -t 2 ]; then
        REAL_TTY=$(tty 0>&2 2>/dev/null || true)
    fi

    if [ -z "$REAL_TTY" ] || [ "$REAL_TTY" = "not a tty" ]; then
        _CTTY=$(ps -p $$ -o tty= 2>/dev/null | awk '{print $1}' || true)
        if [ -n "$_CTTY" ] && [ "$_CTTY" != "?" ]; then
            case "$_CTTY" in
                /*) REAL_TTY="$_CTTY" ;;
                *)  REAL_TTY="/dev/$_CTTY" ;;
            esac
        fi
    fi

    if [ -n "$REAL_TTY" ] && [ "$REAL_TTY" != "not a tty" ] \
        && ( exec 0<>"$REAL_TTY" ) 2>/dev/null; then
        exec 0<>"$REAL_TTY" 1<>"$REAL_TTY" 2<>"$REAL_TTY"
    elif tty_usable; then
        exec 0<>/dev/tty
    else
        echo "  [ERR]   stdin is not a terminal and no TTY is available." >&2
        echo "  [INFO]  Please run the installer directly: sh install.sh" >&2
        exit 1
    fi
fi

REPO="${CAELESTIA_REPO:-https://github.com/FahmiMj/caelestia-fedora.git}"
BRANCH="${CAELESTIA_BRANCH:-main}"
DEST="${CAELESTIA_DIR:-$HOME/caelestia-fedora}"

if ! command -v git >/dev/null 2>&1; then
    echo "  [ERR]   git is required but not installed." >&2
    exit 1
fi

if [ -f "$SCRIPT_DIR/scripts/setup.sh" ]; then
    if [ ! -t 0 ] && tty_usable; then
        exec bash "$SCRIPT_DIR/scripts/setup.sh" "$@" </dev/tty
    fi
    exec bash "$SCRIPT_DIR/scripts/setup.sh" "$@"
fi

if [ -d "$DEST/.git" ]; then
    echo "  [INFO]  Updating existing checkout at $DEST"
    git -C "$DEST" pull --ff-only --recurse-submodules
elif [ -e "$DEST" ]; then
    echo "  [ERR]   $DEST already exists and is not a git checkout; aborting." >&2
    exit 1
else
    echo "  [INFO]  Cloning $REPO ($BRANCH) into $DEST"
    git clone -b "$BRANCH" --single-branch --depth 1 --recurse-submodules "$REPO" "$DEST"
fi

if [ ! -t 0 ] && tty_usable; then
    exec bash "$DEST/scripts/setup.sh" "$@" </dev/tty
fi
exec bash "$DEST/scripts/setup.sh" "$@"
}
