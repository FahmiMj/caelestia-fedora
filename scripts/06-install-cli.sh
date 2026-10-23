#!/usr/bin/env bash
# Install the `caelestia` CLI in an isolated pipx environment.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/log.sh
source "${SCRIPT_DIR}/lib/log.sh"
# shellcheck source=scripts/lib/privileges.sh
source "${SCRIPT_DIR}/lib/privileges.sh"
# shellcheck source=scripts/lib/packages.sh
source "${SCRIPT_DIR}/lib/packages.sh"

section() { printf '\n  == %s ==\n' "$1"; }

have_cmd() { command -v "$1" >/dev/null 2>&1; }

install_cli() {
    section "Caelestia CLI"
    dnf_install pipx
    pipx ensurepath

    local dir="${CAELESTIA_SRC}/cli"
    git_sync "${CAELESTIA_CLI_REPO}" "${dir}" "${CAELESTIA_REF}"

    # Fedora quickshell isolation fix:
    # The caelestia CLI calls `qs -c caelestia ...` everywhere, but Quickshell
    # treats ~/.config/quickshell/shell.qml (if it exists, e.g. from ml4w) as
    # the default config and ignores subdirectories. So `qs -c caelestia`
    # resolves to the wrong config. Patch the CLI to use path-based launch
    # (`qs -p <dir>`) instead. See install logs, BUG 1/7.
    python3 - "${dir}" <<'PYEOF'
import sys
from pathlib import Path

cli_dir = Path(sys.argv[1])
shell_py = cli_dir / "src" / "caelestia" / "subcommands" / "shell.py"
if not shell_py.exists():
    print(f"WARNING: {shell_py} not found; skipping CLI patch", file=sys.stderr)
    sys.exit(0)

text = shell_py.read_text()

# Add pathlib import if not present
if "from pathlib import Path" not in text:
    text = text.replace("import os\n", "import os\nfrom pathlib import Path\n")

# Add CAEL_QUICKSHELL_DIR constant after the imports
if "CAEL_QUICKSHELL_DIR" not in text:
    marker = "from caelestia.utils.io import fatal, warn\n"
    text = text.replace(
        marker,
        marker + "\nCAEL_QUICKSHELL_DIR = str(Path.home() / \".config\" / \"quickshell\" / \"caelestia\")\n",
    )

# Replace every qs -c caelestia with qs -p <dir>
text = text.replace(
    '["qs", "-c", "caelestia"',
    '["qs", "-p", CAEL_QUICKSHELL_DIR',
)

shell_py.write_text(text)
print(f"patched {shell_py}")
PYEOF

    pipx install --force "${dir}"

    if have_cmd caelestia; then
        ok "caelestia CLI installed: $(caelestia --version 2>/dev/null || echo '?')"
    else
        warn "caelestia is not on PATH in this shell yet; it will be after re-login"
    fi
}

main() { install_cli "$@"; }
main "$@"
