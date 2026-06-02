#!/usr/bin/env bash
set -Eeuo pipefail

PARENT_IFACE="${PARENT_IFACE:-enp12s0}"
VLAN_ID="${VLAN_ID:-70}"
CON_NAME="${CON_NAME:-tmp-notes-guest-vlan70}"
VLAN_IFACE="${VLAN_IFACE:-${PARENT_IFACE}.${VLAN_ID}}"
GATEWAY="${GATEWAY:-192.168.70.1}"
EXPECTED_PREFIX="${EXPECTED_PREFIX:-192.168.70.}"

PROXMOX_TARGETS=(192.168.50.99 192.168.50.100 192.168.50.220 192.168.50.251)
LAN_SERVICE_TARGETS=(192.168.50.195 192.168.50.102)
WAN_TEST_TARGET="${WAN_TEST_TARGET:-1.1.1.1}"

usage() {
  cat <<EOF
Usage: $(basename "$0") [full|up|test|status|down]

Commands:
  full    Create VLAN 70, run tests, then delete it again. Default.
  up      Create temporary VLAN 70 NetworkManager connection and leave it up.
  test    Run reachability/isolation tests against an already-up VLAN 70.
  status  Show temporary connection, address, and routes.
  down    Delete the temporary connection and VLAN interface.

Environment overrides:
  PARENT_IFACE=$PARENT_IFACE
  VLAN_ID=$VLAN_ID
  CON_NAME=$CON_NAME
  VLAN_IFACE=$VLAN_IFACE
  GATEWAY=$GATEWAY
EOF
}

log() {
  printf '\n==> %s\n' "$*"
}

warn() {
  printf 'WARN: %s\n' "$*" >&2
}

need_root() {
  if [[ ${EUID} -ne 0 ]]; then
    exec sudo "$0" "$@"
  fi
}

require_cmds() {
  local missing=()
  for cmd in nmcli ip nmap curl awk cut sudo; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done
  if (( ${#missing[@]} > 0 )); then
    printf 'Missing required command(s): %s\n' "${missing[*]}" >&2
    exit 1
  fi
}

preflight() {
  require_cmds

  if ! nmcli -t -f RUNNING general | grep -qx running; then
    echo "NetworkManager is not running; refusing to continue." >&2
    exit 1
  fi

  if ! ip link show "$PARENT_IFACE" >/dev/null 2>&1; then
    echo "Parent interface $PARENT_IFACE does not exist." >&2
    exit 1
  fi

  if ! ip -4 addr show "$PARENT_IFACE" | grep -q '192\.168\.50\.85/'; then
    warn "$PARENT_IFACE does not currently show expected aeolus LAN address 192.168.50.85."
    warn "Continuing, but verify you are on aeolus before using this for production validation."
  fi
}

connection_exists() {
  nmcli -t -f NAME connection show | grep -Fxq "$CON_NAME"
}

connection_active() {
  nmcli -t -f NAME connection show --active | grep -Fxq "$CON_NAME"
}

vlan_ip() {
  ip -4 -o addr show dev "$VLAN_IFACE" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1
}

delete_temp_routes() {
  local target
  for target in "$WAN_TEST_TARGET" "${PROXMOX_TARGETS[@]}" "${LAN_SERVICE_TARGETS[@]}"; do
    ip route del "${target}/32" via "$GATEWAY" dev "$VLAN_IFACE" 2>/dev/null || true
  done
}

down() {
  log "Removing temporary VLAN test connection"
  if connection_active; then
    nmcli -w 10 connection down "$CON_NAME" || true
  fi
  if connection_exists; then
    nmcli connection delete "$CON_NAME" || true
  fi
  if ip link show "$VLAN_IFACE" >/dev/null 2>&1; then
    ip link delete "$VLAN_IFACE" || true
  fi
  delete_temp_routes
  log "Cleanup complete"
}

up() {
  preflight

  if connection_exists || ip link show "$VLAN_IFACE" >/dev/null 2>&1; then
    warn "Existing $CON_NAME/$VLAN_IFACE found; removing it before recreating."
    down
  fi

  log "Creating temporary VLAN $VLAN_ID on $PARENT_IFACE"
  nmcli connection add \
    type vlan \
    con-name "$CON_NAME" \
    ifname "$VLAN_IFACE" \
    dev "$PARENT_IFACE" \
    id "$VLAN_ID" \
    connection.autoconnect no \
    ipv4.method auto \
    ipv4.never-default yes \
    ipv4.ignore-auto-dns yes \
    ipv4.dhcp-timeout 20 \
    ipv6.method disabled

  log "Bringing up $CON_NAME"
  nmcli -w 30 connection up "$CON_NAME"

  local ip_addr=""
  for _ in {1..20}; do
    ip_addr="$(vlan_ip)"
    [[ -n "$ip_addr" ]] && break
    sleep 1
  done

  if [[ -z "$ip_addr" ]]; then
    echo "VLAN interface came up but did not receive an IPv4 lease." >&2
    echo "Run: sudo $0 down" >&2
    exit 1
  fi

  if [[ "$ip_addr" != "$EXPECTED_PREFIX"* ]]; then
    warn "Received $ip_addr, expected an address starting with $EXPECTED_PREFIX."
  fi

  status
}

status() {
  log "NetworkManager connection"
  nmcli -f NAME,UUID,TYPE,DEVICE,AUTOCONNECT connection show "$CON_NAME" 2>/dev/null || true

  log "Interface address"
  ip -br addr show "$VLAN_IFACE" 2>/dev/null || true

  log "Routes on $VLAN_IFACE"
  ip route show dev "$VLAN_IFACE" 2>/dev/null || true

  log "Main default route"
  ip route show default || true
}

add_test_routes() {
  local target
  for target in "$WAN_TEST_TARGET" "${PROXMOX_TARGETS[@]}" "${LAN_SERVICE_TARGETS[@]}"; do
    ip route replace "${target}/32" via "$GATEWAY" dev "$VLAN_IFACE"
  done
}

test_vlan() {
  preflight

  local ip_addr tmp_proxmox="" tmp_services=""
  ip_addr="$(vlan_ip)"
  if [[ -z "$ip_addr" ]]; then
    echo "$VLAN_IFACE has no IPv4 address. Run: sudo $0 up" >&2
    exit 1
  fi

  log "Using $VLAN_IFACE address $ip_addr"
  trap 'rm -f "${tmp_proxmox:-}" "${tmp_services:-}"; delete_temp_routes; trap - RETURN' RETURN
  add_test_routes

  log "Gateway ping"
  ping -I "$VLAN_IFACE" -c 3 -W 2 "$GATEWAY"

  log "Gateway DNS port from VLAN interface"
  nmap -e "$VLAN_IFACE" -sT -Pn -p 53 "$GATEWAY"

  log "WAN test through VLAN route to $WAN_TEST_TARGET"
  curl -4 --interface "$ip_addr" -I --max-time 8 "http://${WAN_TEST_TARGET}/" || {
    warn "WAN HTTP test failed. This may be policy/DNS related; continue to isolation checks."
  }

  tmp_proxmox="$(mktemp)"
  tmp_services="$(mktemp)"

  log "Guest isolation check: Proxmox management should NOT be open"
  nmap -e "$VLAN_IFACE" -sT -Pn --max-retries 1 --host-timeout 20s \
    -p 22,8006,9100 "${PROXMOX_TARGETS[@]}" | tee "$tmp_proxmox"

  if grep -Eq '^(22|8006|9100)/tcp[[:space:]]+open' "$tmp_proxmox"; then
    warn "One or more Proxmox management ports are open from VLAN $VLAN_ID."
  else
    log "OK: no Proxmox management ports reported open from VLAN $VLAN_ID."
  fi

  log "Guest isolation check: LAN game/backend ports should NOT be open"
  nmap -e "$VLAN_IFACE" -sT -Pn --max-retries 1 --host-timeout 20s \
    -p 25565,25575 "${LAN_SERVICE_TARGETS[@]}" | tee "$tmp_services"

  if grep -Eq '^(25565|25575)/tcp[[:space:]]+open' "$tmp_services"; then
    warn "One or more LAN service ports are open from VLAN $VLAN_ID."
  else
    log "OK: no LAN game/backend ports reported open from VLAN $VLAN_ID."
  fi
}

full() {
  trap down EXIT
  up
  test_vlan
  log "Full test finished; reverting temporary VLAN connection"
}

main() {
  local action="${1:-full}"
  case "$action" in
    full|up|test|status|down)
      need_root "$@"
      "$action"
      ;;
    -h|--help|help)
      usage
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
}

main "$@"
