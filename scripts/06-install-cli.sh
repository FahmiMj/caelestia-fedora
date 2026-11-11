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
# shellcheck source=scripts/lib/install-fs.sh
source "${SCRIPT_DIR}/lib/install-fs.sh"

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

src_root = Path(sys.argv[1]) / "src" / "caelestia"
if not src_root.is_dir():
    print(f"WARNING: {src_root} not found; skipping CLI patch", file=sys.stderr)
    sys.exit(0)

# Every subcommand that talks to the running shell uses this argv prefix.
OLD = '["qs", "-c", "caelestia"'
NEW = '["qs", "-p", CAEL_QUICKSHELL_DIR'
CONST = 'CAEL_QUICKSHELL_DIR = str(Path.home() / ".config" / "quickshell" / "caelestia")\n'

patched = []
for path in sorted(src_root.rglob("*.py")):
    text = path.read_text()
    if OLD not in text:
        continue

    if "CAEL_QUICKSHELL_DIR" not in text:
        lines = text.splitlines(keepends=True)
        last_import = 0
        for idx, line in enumerate(lines):
            if line.startswith(("import ", "from ")):
                last_import = idx + 1
        block = ""
        if "from pathlib import Path" not in text:
            block += "from pathlib import Path\n"
        block += CONST
        lines.insert(last_import, "\n" + block)
        text = "".join(lines)

    path.write_text(text.replace(OLD, NEW))
    patched.append(str(path))

if not patched:
    print(
        "WARNING: no 'qs -c caelestia' invocations found; CLI left unpatched",
        file=sys.stderr,
    )
else:
    for path in patched:
        print(f"patched {path}")
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
