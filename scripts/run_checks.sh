#!/bin/zsh

set -euo pipefail

script_directory="${0:A:h}"
repository_root="${script_directory:h}"
module_cache="${repository_root}/.build/clang-module-cache"
store_check_directory="$(mktemp -d)"

trap 'rm -rf -- "${store_check_directory}"' EXIT

cd "${repository_root}"
mkdir -p "${module_cache}"

for source_file in AudioShelf/**/*.swift AudioShelfCore/*.swift AudioShelfTests/*.swift Tests/CoreChecks/*.swift; do
    swiftc -frontend -parse "${source_file}"
done

if rg -n 'import SwiftData|@Model|@Query|ModelContext' AudioShelf -g '*.swift'; then
    print -u2 "检查失败：应用源码仍包含 SwiftData 依赖。"
    exit 1
fi

plutil -lint Resources/Info.plist AudioShelf/AudioShelf.entitlements AudioShelf.xcodeproj/project.pbxproj

if [[ ! -f Resources/AppIcon.icns ]]; then
    print -u2 "检查失败：缺少 Resources/AppIcon.icns。"
    exit 1
fi

if [[ "$(sips -g pixelWidth Resources/AppIcon.icns 2>/dev/null | awk '/pixelWidth/ {print $2}')" != "1024" ]]; then
    print -u2 "检查失败：应用图标缺少 1024px 表示。"
    exit 1
fi

run_flags=(run --disable-sandbox AudioShelfCoreChecks)
swiftc_sdk_flags=()
if [[ "$(xcode-select -p)" == "/Library/Developer/CommandLineTools" ]]; then
    build_sdk="/Library/Developer/CommandLineTools/SDKs/MacOSX15.sdk"
    if [[ ! -d "${build_sdk}" ]]; then
        build_sdk="$(ls -d /Library/Developer/CommandLineTools/SDKs/MacOSX*.sdk 2>/dev/null | sort -V | tail -1 || true)"
    fi
    if [[ -n "${build_sdk}" ]]; then
        swiftc_sdk_flags=(-sdk "${build_sdk}")
        env SDKROOT="${build_sdk}" CLANG_MODULE_CACHE_PATH="${module_cache}" \
            swift "${run_flags[@]}"
    else
        env CLANG_MODULE_CACHE_PATH="${module_cache}" swift "${run_flags[@]}"
    fi
else
    env CLANG_MODULE_CACHE_PATH="${module_cache}" swift "${run_flags[@]}"
fi

swiftc -parse-as-library -swift-version 5 "${swiftc_sdk_flags[@]}" \
    -module-cache-path "${module_cache}" \
    AudioShelfCore/*.swift \
    AudioShelf/Models/*.swift \
    AudioShelf/Services/LibraryStore.swift \
    Tests/StoreChecks/main.swift \
    -o "${store_check_directory}/AudioShelfStoreChecks"
"${store_check_directory}/AudioShelfStoreChecks"

print "AudioShelf checks: passed"
