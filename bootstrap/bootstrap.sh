#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_PATH="$SCRIPT_DIR/packages.toml"
MODE="plan"
SELECTED_GROUPS=()
SELECTED_COMPONENTS=()

usage() {
  cat <<'USAGE'
Usage: bootstrap/bootstrap.sh [options]

Options:
  --plan               Print package plan (default)
  --install            Install packages (Arch only)
  --component <name>   Install only a named component (repeatable)
  --group <name>       Include optional package group (repeatable)
  --help               Show this help

Examples:
  bootstrap/bootstrap.sh --plan
  bootstrap/bootstrap.sh --group wm --group nvim --plan
  bootstrap/bootstrap.sh --group wm --install
  bootstrap/bootstrap.sh --component nvim --install
USAGE
}

is_arch() {
  if [[ ! -r /etc/os-release ]]; then
    return 1
  fi

  # shellcheck disable=SC1091
  source /etc/os-release
  [[ "${ID:-}" == "arch" ]] && return 0
  [[ " ${ID_LIKE:-} " == *" arch "* ]] && return 0
  return 1
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$1" >&2
    exit 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --plan)
      MODE="plan"
      shift
      ;;
    --install)
      MODE="install"
      shift
      ;;
    --component)
      [[ $# -ge 2 ]] || {
        printf 'Missing value for --component\n' >&2
        exit 1
      }
      SELECTED_COMPONENTS+=("$2")
      shift 2
      ;;
    --group)
      [[ $# -ge 2 ]] || {
        printf 'Missing value for --group\n' >&2
        exit 1
      }
      SELECTED_GROUPS+=("$2")
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage
      exit 1
      ;;
  esac
done

if (( ${#SELECTED_COMPONENTS[@]} > 0 && ${#SELECTED_GROUPS[@]} > 0 )); then
  printf 'Use either --component or --group, not both in the same invocation.\n' >&2
  exit 1
fi

[[ -f "$MANIFEST_PATH" ]] || {
  printf 'Manifest not found: %s\n' "$MANIFEST_PATH" >&2
  exit 1
}

require_cmd python3

resolved_lines="$(python3 - "$MANIFEST_PATH" --components "${SELECTED_COMPONENTS[@]}" --groups "${SELECTED_GROUPS[@]}" <<'PY'
import sys
import tomllib

manifest_path = sys.argv[1]
args = sys.argv[2:]
requested_components = []
requested_groups = []
mode = None

for arg in args:
    if arg == "--components":
        mode = "components"
        continue
    if arg == "--groups":
        mode = "groups"
        continue
    if mode == "components":
        requested_components.append(arg)
    elif mode == "groups":
        requested_groups.append(arg)

with open(manifest_path, "rb") as fh:
    data = tomllib.load(fh)

arch = data.get("arch", {})
groups = data.get("groups", {})
components = data.get("components", {})

missing = []

if requested_components:
    pacman = []
    aur = []
    for component in requested_components:
        section = components.get(component)
        if section is None:
            missing.append(component)
            continue
        pacman.extend(section.get("pacman", []))
        aur.extend(section.get("aur", []))
else:
    pacman = list(arch.get("pacman", []))
    aur = list(arch.get("aur", []))

    for group in requested_groups:
        section = groups.get(group)
        if section is None:
            missing.append(group)
            continue
        pacman.extend(section.get("pacman", []))
        aur.extend(section.get("aur", []))


def uniq(items):
    seen = set()
    out = []
    for item in items:
        if item in seen:
            continue
        seen.add(item)
        out.append(item)
    return out


for group in missing:
    print(f"MISSING\t{group}")

for pkg in uniq(pacman):
    print(f"PACMAN\t{pkg}")

for pkg in uniq(aur):
    print(f"AUR\t{pkg}")
PY
)"

PACMAN_PKGS=()
AUR_PKGS=()
MISSING_GROUPS=()

while IFS=$'\t' read -r kind value; do
  [[ -n "${kind:-}" ]] || continue
  case "$kind" in
    PACMAN)
      PACMAN_PKGS+=("$value")
      ;;
    AUR)
      AUR_PKGS+=("$value")
      ;;
    MISSING)
      MISSING_GROUPS+=("$value")
      ;;
  esac
done <<< "$resolved_lines"

if (( ${#MISSING_GROUPS[@]} > 0 )); then
  if (( ${#SELECTED_COMPONENTS[@]} > 0 )); then
    printf 'Unknown component(s): %s\n' "${MISSING_GROUPS[*]}" >&2
  else
    printf 'Unknown group(s): %s\n' "${MISSING_GROUPS[*]}" >&2
  fi
  exit 1
fi

printf 'Mode: %s\n' "$MODE"
if (( ${#SELECTED_COMPONENTS[@]} > 0 )); then
  printf 'Components: %s\n' "${SELECTED_COMPONENTS[*]}"
  printf 'Groups: (n/a)\n'
elif (( ${#SELECTED_GROUPS[@]} == 0 )); then
  printf 'Components: (none)\n'
  printf 'Groups: (none)\n'
else
  printf 'Components: (none)\n'
  printf 'Groups: %s\n' "${SELECTED_GROUPS[*]}"
fi

printf '\n[pacman]\n'
for pkg in "${PACMAN_PKGS[@]}"; do
  printf '  %s\n' "$pkg"
done

printf '\n[aur]\n'
for pkg in "${AUR_PKGS[@]}"; do
  printf '  %s\n' "$pkg"
done

if [[ "$MODE" == "plan" ]]; then
  exit 0
fi

if ! is_arch; then
  printf 'Install mode only supports Arch-based systems.\n' >&2
  exit 1
fi

require_cmd sudo
require_cmd pacman

if (( ${#PACMAN_PKGS[@]} > 0 )); then
  sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"
fi

if (( ${#AUR_PKGS[@]} > 0 )); then
  require_cmd paru
  paru -S --needed --noconfirm "${AUR_PKGS[@]}"
fi
