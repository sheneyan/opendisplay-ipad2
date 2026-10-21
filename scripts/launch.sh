#!/bin/bash
# Launch an installed receiver over USB without using the iPad Home button.
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 DEVICE_UDID /path/to/DeveloperDiskImage.dmg" >&2
  exit 2
fi
device_udid="$1"
developer_image="$2"
bundle_id="com.sheneyan.oldipad.display"

for tool in idevice_id ideviceimagemounter idevicedebug; do
  if ! command -v "$tool" >/dev/null; then
    echo "Missing $tool. Install libimobiledevice with Homebrew." >&2
    exit 1
  fi
done

devices="$(idevice_id -l)"
if ! /usr/bin/awk -v target="$device_udid" '$0 == target { found=1 } END { exit !found }' <<< "$devices"; then
  echo "The configured iPad is not connected. Connect its USB cable, unlock it and trust this Mac." >&2
  exit 1
fi

mounted="$(ideviceimagemounter -u "$device_udid" list)"
if [[ "$mounted" != *"ImagePresent: true"* ]]; then
  if [[ ! -f "$developer_image" || ! -f "$developer_image.signature" ]]; then
    echo "The matching developer disk image and .signature are required: $developer_image" >&2
    exit 1
  fi
  ideviceimagemounter -u "$device_udid" mount "$developer_image"
fi

if ! idevicedebug -u "$device_udid" --detach run "$bundle_id"; then
  echo "Could not launch Legacy Display. Unlock the iPad and retry. If it still fails, check the app installation and signing validity." >&2
  exit 1
fi

/usr/bin/open -g -a OpenDisplay
echo "Legacy Display launched. If the desktop does not appear, click Connect for this iPad in OpenDisplay."
