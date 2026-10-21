#!/bin/bash
# Restart an installed receiver over USB without using the iPad Home button.
set -euo pipefail
export PATH="$PATH:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 DEVICE_UDID /path/to/DeveloperDiskImage.dmg" >&2
  exit 2
fi
device_udid="$1"
developer_image="$2"
bundle_id="com.sheneyan.oldipad.display"

# macOS ships Perl. Its alarm survives exec and bounds a stalled USB command.
bounded() {
  /usr/bin/perl -e 'alarm shift; exec @ARGV; die "Could not execute tool: $!\n"' "$@"
}

for tool in idevice_id ideviceimagemounter idevicedebug; do
  if ! command -v "$tool" >/dev/null; then
    echo "Missing $tool. Install libimobiledevice with Homebrew." >&2
    exit 1
  fi
done

devices="$(bounded 15 idevice_id -l)"
if ! /usr/bin/awk -v target="$device_udid" '$0 == target { found=1 } END { exit !found }' <<< "$devices"; then
  echo "The configured iPad is not connected. Connect its USB cable, unlock it and trust this Mac." >&2
  exit 1
fi

mounted="$(bounded 15 ideviceimagemounter -u "$device_udid" list)"
if [[ "$mounted" != *"ImagePresent: true"* ]]; then
  if [[ ! -f "$developer_image" || ! -f "$developer_image.signature" ]]; then
    echo "The matching developer disk image and .signature are required: $developer_image" >&2
    exit 1
  fi
  bounded 60 ideviceimagemounter -u "$device_udid" mount "$developer_image"
fi

echo "Stopping the existing Legacy Display process..."
stop_status=0
bounded 20 idevicedebug -u "$device_udid" kill "$bundle_id" || stop_status=$?
# libimobiledevice 1.4.0's kill branch leaves its default exit status at -1
# even after sending the kill packet successfully. Do not equate 255 with failure.
if [[ "$stop_status" -eq 142 ]]; then
  echo "Stopping timed out. Check the USB connection, unlock the iPad and retry." >&2
  exit 1
elif [[ "$stop_status" -ne 0 && "$stop_status" -ne 255 ]]; then
  echo "Could not stop Legacy Display (status $stop_status). Check the USB connection and retry." >&2
  exit 1
fi

if ! bounded 20 idevicedebug -u "$device_udid" --detach run "$bundle_id"; then
  echo "Could not launch Legacy Display. Unlock the iPad and retry. If it still fails, check the app installation and signing validity." >&2
  exit 1
fi

open -g -a OpenDisplay
echo "Legacy Display launched after a stop request. If the desktop does not appear, click Connect or Refresh for this iPad in OpenDisplay."
