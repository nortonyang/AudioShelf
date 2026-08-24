#!/bin/zsh

set -euo pipefail

script_directory="${0:A:h}"
repository_root="${script_directory:h}"
application_bundle="${repository_root}/dist/AudioShelf.app"
contents_directory="${application_bundle}/Contents"
module_cache="${repository_root}/.build/clang-module-cache"

cd "${repository_root}"
mkdir -p "${module_cache}"

build_flags=(-c release --product AudioShelf --disable-sandbox)

if [[ "$(xcode-select -p)" == "/Library/Developer/CommandLineTools" ]]; then
    build_sdk="/Library/Developer/CommandLineTools/SDKs/MacOSX15.sdk"
    if [[ ! -d "${build_sdk}" ]]; then
        build_sdk="$(ls -d /Library/Developer/CommandLineTools/SDKs/MacOSX*.sdk 2>/dev/null | sort -V | tail -1 || true)"
    fi
    if [[ -n "${build_sdk}" ]]; then
        env SDKROOT="${build_sdk}" CLANG_MODULE_CACHE_PATH="${module_cache}" \
            swift build "${build_flags[@]}"
    else
        env CLANG_MODULE_CACHE_PATH="${module_cache}" swift build "${build_flags[@]}"
    fi
else
    env CLANG_MODULE_CACHE_PATH="${module_cache}" swift build "${build_flags[@]}"
fi

rm -rf -- "${application_bundle}"
mkdir -p "${contents_directory}/MacOS" "${contents_directory}/Resources"
cp "${repository_root}/.build/release/AudioShelf" "${contents_directory}/MacOS/AudioShelf"
cp "${repository_root}/Resources/Info.plist" "${contents_directory}/Info.plist"
cp "${repository_root}/Resources/AppIcon.icns" "${contents_directory}/Resources/AppIcon.icns"
chmod 755 "${contents_directory}/MacOS/AudioShelf"

if command -v codesign >/dev/null 2>&1; then
    codesign --force --sign - \
        --entitlements "${repository_root}/AudioShelf/AudioShelf.entitlements" \
        "${application_bundle}"
fi

plutil -lint "${contents_directory}/Info.plist"
print "Built ${application_bundle}"
