set -e

resources="${TARGET_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}"

for source in "${SRCROOT}"/Runner/*.lproj/InfoPlist.strings; do
  [ -f "$source" ] || continue
  lproj="$(basename "$(dirname "$source")")"
  target="${resources}/${lproj}/InfoPlist.strings"
  name="$(plutil -extract CFBundleDisplayName raw -o - "$source")"
  mkdir -p "$(dirname "$target")"
  plutil -convert binary1 -o "$target" "$source"
  plutil -replace CFBundleDisplayName -string "${name}${APP_DISPLAY_NAME_SUFFIX}" "$target"
done
