#!/usr/bin/env bash
# Fedora-specific workarounds:
#   * pick a hardware video encoder that actually exists (gpu-screen-recorder
#     defaults to H.264, which many Intel iGPUs cannot encode),
#   * create a wallpaper directory with a default image.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/log.sh
source "${SCRIPT_DIR}/lib/log.sh"

section() { printf '\n  == %s ==\n' "$1"; }

have_cmd() { command -v "$1" >/dev/null 2>&1; }

# Print the best available hardware encoder (h264/hevc/av1/vp9/vp8), or nothing.
detect_encoder() {
    local node out fallback=""
    for node in /dev/dri/renderD*; do
        [[ -e "${node}" ]] || continue
        out="$(vainfo --display drm --device "${node}" 2>/dev/null || true)"
        [[ -n "${out}" ]] || continue
        if grep -qE 'VAProfileH264.*VAEntrypointEnc' <<<"${out}"; then
            printf 'h264'; return 0
        fi
        if grep -qE 'VAProfileHEVC.*VAEntrypointEnc' <<<"${out}"; then
            printf 'hevc'; return 0
        fi
        if grep -qE 'VAProfileAV1.*VAEntrypointEnc' <<<"${out}"; then
            printf 'av1'; return 0
        fi
        if grep -qE 'VAProfileVP9.*VAEntrypointEnc' <<<"${out}"; then
            fallback="vp9"
        fi
        if [[ -z "${fallback}" ]] && grep -qE 'VAProfileVP8.*VAEntrypointEnc' <<<"${out}"; then
            fallback="vp8"
        fi
    done
    printf '%s' "${fallback}"
}

apply_record_fix() {
    section "Screen recording encoder"
    if ! have_cmd gpu-screen-recorder; then
        warn "gpu-screen-recorder is not installed; skipping recorder configuration"
        return 0
    fi
    if ! have_cmd vainfo; then
        warn "vainfo is unavailable; leaving recorder defaults untouched"
        return 0
    fi

    local enc file tmp
    enc="$(detect_encoder)"
    file="${XDG_CONFIG_HOME}/caelestia/cli.json"

    if [[ "${DRY_RUN}" == "1" ]]; then
        info "[dry-run] detect VA-API encoder (found: ${enc:-none}) and update ${file}"
        return 0
    fi

    mkdir -p "$(dirname "${file}")"
    [[ -f "${file}" ]] || printf '{}\n' > "${file}"

    if [[ -z "${enc}" ]]; then
        warn "no hardware video encoder found; screen recording may fail"
        return 0
    fi
    if [[ "${enc}" == "h264" ]]; then
        ok "H.264 hardware encode available; default recorder settings are fine"
        if have_cmd jq && jq -e '.record.extraArgs' "${file}" >/dev/null 2>&1; then
            tmp="$(mktemp)"
            jq 'del(.record.extraArgs)' "${file}" > "${tmp}" && mv "${tmp}" "${file}"
        fi
        return 0
    fi

    info "preferred hardware encoder: ${enc}"
    tmp="$(mktemp)"
    jq --arg c "${enc}" '.record.extraArgs = ["-k", $c]' "${file}" > "${tmp}" \
        && mv "${tmp}" "${file}"
    ok "record.extraArgs set to -k ${enc} in ${file}"
}

setup_wallpapers() {
    section "Wallpapers"
    local dir="${HOME}/Pictures/Wallpapers"
    mkdir -p "${dir}"
    if ! compgen -G "${dir}/*" >/dev/null 2>&1; then
        # Reuse the wallpaper shipped inside the Caelestia shell instead of
        # vendoring a copy in this repository.
        local src="${XDG_CONFIG_HOME}/quickshell/caelestia/assets/wallpaper.webp"
        if [[ -f "${src}" ]]; then
            cp "${src}" "${dir}/caelestia.webp"
            ok "installed default wallpaper"
        else
            warn "no default wallpaper available; add one to ${dir}"
        fi
    else
        ok "wallpaper directory already populated"
    fi
}

main() {
    apply_record_fix
    setup_wallpapers
}

main "$@"
