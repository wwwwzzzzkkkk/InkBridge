#!/usr/bin/env bash
set -euo pipefail

action="${1:-build}"
script_directory="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
workspace_project="${script_directory%/scripts}/HarmonyPad"
default_deveco_project="${HOME}/DevEcoStudioProjects/InkBridgeHarmony"
authorized_signed_project="${HOME}/Desktop/pad/HarmonyPad"
deveco_project="${INKBRIDGE_DEVECO_PROJECT:-$default_deveco_project}"
deveco_sdk="/Applications/DevEco-Studio.app/Contents/sdk"
hvigor="/Applications/DevEco-Studio.app/Contents/tools/hvigor/bin/hvigorw"
hdc="/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc"
wireless_port="${INKBRIDGE_HDC_PORT:-10178}"

if [[ "$action" == "wireless" ]]; then
  if [[ ! -x "$hdc" ]]; then
    printf '未找到 hdc：%s\n' "$hdc" >&2
    exit 2
  fi

  tcp_targets=()
  while IFS= read -r target_id; do
    [[ -n "$target_id" ]] && tcp_targets+=("$target_id")
  done < <("$hdc" list targets -v | awk '$2 == "TCP" && $3 == "Connected" { print $1 }')
  if [[ "${#tcp_targets[@]}" -eq 1 ]]; then
    printf '无线调试已经连接：%s\n' "${tcp_targets[0]}"
    exit 0
  fi

  usb_targets=()
  while IFS= read -r target_id; do
    [[ -n "$target_id" ]] && usb_targets+=("$target_id")
  done < <("$hdc" list targets -v | awk '$2 == "USB" && $3 == "Connected" { print $1 }')
  if [[ "${#usb_targets[@]}" -ne 1 ]]; then
    printf '首次开启无线调试需要且只能连接一台 USB 平板；当前数量：%s\n' "${#usb_targets[@]}" >&2
    exit 4
  fi

  usb_target="${usb_targets[0]}"
  tablet_ip="$("$hdc" -t "$usb_target" shell ifconfig wlan0 2>/dev/null \
    | awk '/inet addr:/ { sub(/^.*inet addr:/, ""); sub(/[[:space:]].*$/, ""); print; exit }')"
  if [[ ! "$tablet_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    printf '未能读取平板 Wi-Fi 地址，请确认平板已连接局域网。\n' >&2
    exit 6
  fi

  printf '开启平板无线调试：%s:%s…\n' "$tablet_ip" "$wireless_port"
  "$hdc" -t "$usb_target" tmode port "$wireless_port"
  "$hdc" tconn "$tablet_ip:$wireless_port"
  if ! "$hdc" list targets -v \
    | awk -v target="$tablet_ip:$wireless_port" '$1 == target && $2 == "TCP" && $3 == "Connected" { found = 1 } END { exit !found }'; then
    printf '无线调试连接未建立，请检查 VPN、防火墙和局域网。\n' >&2
    exit 7
  fi
  printf '无线调试配置完成：%s:%s\n' "$tablet_ip" "$wireless_port"
  exit 0
fi

has_signing_config() {
  [[ -f "$1/build-profile.json5" ]] \
    && ! rg -q '"signingConfigs"\s*:\s*\[\s*\]' "$1/build-profile.json5"
}

# The normal mirror is kept credential-free. For a real-device install, reuse
# the already authorized DevEco project in place; never copy its signing data.
if [[ "$action" == "install" ]] \
  && [[ -z "${INKBRIDGE_DEVECO_PROJECT:-}" ]] \
  && ! has_signing_config "$deveco_project" \
  && has_signing_config "$authorized_signed_project"; then
  deveco_project="$authorized_signed_project"
fi

if [[ ! -f "$workspace_project/AppScope/app.json5" ]] \
  || ! rg -q '"bundleName": "com\.zhekuan\.inkbridge"' "$workspace_project/AppScope/app.json5"; then
  printf '无法确认笔迹桥 HarmonyOS 源码目录：%s\n' "$workspace_project" >&2
  exit 2
fi

mkdir -p "$deveco_project"

rsync_args=(
  -a
  --delete
  --exclude .DS_Store
  --exclude .hvigor/
  --exclude .idea/
  --exclude entry/build/
  --exclude oh_modules/
)

# DevEco automatic signing may write a local, credential-bearing signing
# profile in the ASCII build mirror. Preserve it without reading or printing it.
if has_signing_config "$deveco_project"; then
  # Preserve only the project-level signing profile. Module build profiles are
  # source-controlled and may contain required native CMake configuration.
  rsync_args+=(--exclude /build-profile.json5)
fi

printf '同步正式源码到 DevEco 英文构建目录…\n'
rsync "${rsync_args[@]}" "$workspace_project/" "$deveco_project/"

if [[ "$action" == "sync" ]]; then
  printf '同步完成：%s\n' "$deveco_project"
  exit 0
fi

if [[ ! -x "$hvigor" ]]; then
  printf '未找到 hvigor：%s\n' "$hvigor" >&2
  exit 2
fi

app_version="$(tr -d '[:space:]' < "$workspace_project/../VERSION")"
printf '构建笔迹桥 HarmonyOS %s…\n' "$app_version"
(
  cd "$deveco_project"
  DEVECO_SDK_HOME="$deveco_sdk" "$hvigor" \
    assembleHap --mode module \
    -p product=default \
    -p module=entry@default \
    -p buildMode=debug \
    --no-daemon
)

output_dir="$deveco_project/entry/build/default/outputs/default"
unsigned_hap="$output_dir/entry-default-unsigned.hap"
signed_hap=""
while IFS= read -r candidate; do
  signed_hap="$candidate"
  break
done < <(find "$output_dir" -maxdepth 1 -type f -name '*.hap' ! -name '*unsigned*' -print | sort)

if [[ -n "$signed_hap" ]]; then
  printf '已生成签名安装包：%s\n' "$signed_hap"
else
  printf '编译完成，但 DevEco 本地自动签名尚未配置。\n'
  printf '未签名包：%s\n' "$unsigned_hap"
fi

if [[ "$action" != "install" ]]; then
  exit 0
fi

if [[ -z "$signed_hap" ]]; then
  printf '需要先在 DevEco Studio 中为英文构建目录启用自动调试签名。\n' >&2
  exit 3
fi
if [[ ! -x "$hdc" ]]; then
  printf '未找到 hdc：%s\n' "$hdc" >&2
  exit 2
fi

tcp_targets=()
while IFS= read -r target_id; do
  [[ -n "$target_id" ]] && tcp_targets+=("$target_id")
done < <("$hdc" list targets -v | awk '$2 == "TCP" && $3 == "Connected" { print $1 }')
usb_targets=()
while IFS= read -r target_id; do
  [[ -n "$target_id" ]] && usb_targets+=("$target_id")
done < <("$hdc" list targets -v | awk '$2 == "USB" && $3 == "Connected" { print $1 }')

target="${INKBRIDGE_HDC_TARGET:-}"
transport="指定目标"
if [[ -n "$target" ]]; then
  if ! "$hdc" list targets -v \
    | awk -v target="$target" '$1 == target && $3 == "Connected" { found = 1 } END { exit !found }'; then
    printf '指定的调试设备未连接：%s\n' "$target" >&2
    exit 4
  fi
elif [[ "${#tcp_targets[@]}" -eq 1 ]]; then
  target="${tcp_targets[0]}"
  transport="无线 TCP"
elif [[ "${#tcp_targets[@]}" -gt 1 ]]; then
  printf '检测到多台无线调试设备，请通过 INKBRIDGE_HDC_TARGET 指定目标。\n' >&2
  exit 4
elif [[ "${#usb_targets[@]}" -eq 1 ]]; then
  target="${usb_targets[0]}"
  transport="USB"
else
  printf '没有唯一可用的平板调试设备；无线数量：%s，USB 数量：%s\n' \
    "${#tcp_targets[@]}" "${#usb_targets[@]}" >&2
  exit 4
fi

printf '安装到平板 %s（%s）…\n' "$target" "$transport"
"$hdc" -t "$target" install -r "$signed_hap"
launch_output="$("$hdc" -t "$target" shell aa start -a EntryAbility -b com.zhekuan.inkbridge 2>&1)"
printf '%s\n' "$launch_output"
if printf '%s\n' "$launch_output" | rg -qi '(^|[^a-z])(error|failed)([^a-z]|$)'; then
  printf '安装成功，但应用未能启动；请确认平板已解锁。\n' >&2
  exit 5
fi
printf '安装并启动完成。\n'
