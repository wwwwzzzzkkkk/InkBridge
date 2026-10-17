#!/bin/zsh
set -euo pipefail
script_dir="${0:A:h}"
project_dir="${script_dir:h}"
app_dir="${1:-${project_dir}/笔迹桥.app}"
build_dir="${INKBRIDGE_SWIFT_BUILD_DIR:-/private/tmp/InkBridgeSwiftBuild}"

swift build --jobs 1 --package-path "${project_dir}" --scratch-path "${build_dir}"
binary_dir="$(swift build --package-path "${project_dir}" --scratch-path "${build_dir}" --show-bin-path)"
mkdir -p "${app_dir}/Contents/MacOS" "${app_dir}/Contents/Resources/public"
cp "${script_dir}/AppBundle/Info.plist" "${app_dir}/Contents/Info.plist"
cp "${binary_dir}/MacPDFAnnotator" "${app_dir}/Contents/MacOS/MacPDFAnnotator"
cp "${project_dir}/local-server.mjs" "${app_dir}/Contents/Resources/local-server.mjs"
rsync -a --delete --exclude '.DS_Store' "${project_dir}/public/" "${app_dir}/Contents/Resources/public/"
cp "${script_dir}/AppBundle/AppIcon.icns" "${app_dir}/Contents/Resources/AppIcon.icns"
chmod +x "${app_dir}/Contents/MacOS/MacPDFAnnotator"
xattr -cr "${app_dir}"
codesign --force --deep --sign - "${app_dir}"
