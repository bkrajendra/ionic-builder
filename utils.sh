#!/bin/bash
# Ionic/Capacitor/Cordova build and device utilities.
# Usage: utils {pair|new|build|install|help} [options]
# Can be run as 'utils' (global) or via /opt/utils.sh. For build/install, run from project root to auto-detect.

set -e

readonly SCRIPT_NAME="${0##*/}"

usage() {
    echo "Usage: $SCRIPT_NAME {pair|new|build|install|help} [options]"
    echo ""
    echo "Commands:"
    echo "  pair    Pair a device for wireless ADB"
    echo "          -ip <device_ip> -pt <pairing_port> -code <pairing_code> [-adb <adb_port>]"
    echo "  new     Create a new Ionic project"
    echo "          -nw <project_name> -id <app_id> -pf <capacitor|cordova> [-t <template>]"
    echo "  build   Build Android APK (from project root: -nw and -pf optional)"
    echo "          [-nw <project_name>] -pf <capacitor|cordova>"
    echo "  install Install built APK on connected device (from project root: -nw and -pf optional)"
    echo "          [-nw <project_name>] -pf <capacitor|cordova>"
    echo "  help    Show this message"
    exit 0
}

# Detect Ionic project root: current dir or nearest parent with package.json + ionic/capacitor/cordova markers.
# Outputs the project root path (relative or .) or nothing.
detect_project_root() {
    local dir
    dir="$(pwd)"
    local cwd="$dir"
    local max_depth=5
    while [[ "$max_depth" -gt 0 ]]; do
        if [[ -f "$dir/package.json" ]]; then
            if [[ -f "$dir/ionic.config.json" ]] || \
               [[ -f "$dir/capacitor.config.json" || -f "$dir/capacitor.config.ts" ]] || \
               [[ -f "$dir/config.xml" || -d "$dir/platforms/android" ]]; then
                if [[ "$dir" == "$cwd" ]]; then
                    echo "."
                else
                    realpath --relative-to="$cwd" "$dir" 2>/dev/null || echo "$dir"
                fi
                return
            fi
        fi
        [[ "$dir" == "/" ]] && break
        dir="$(dirname "$dir")"
        ((max_depth--)) || true
    done
}

# Detect platform (capacitor|cordova) in the given project directory. Outputs platform or nothing.
detect_platform() {
    local project_dir="$1"
    if [[ -f "$project_dir/capacitor.config.json" || -f "$project_dir/capacitor.config.ts" ]] || [[ -d "$project_dir/android" ]]; then
        echo "capacitor"
        return
    fi
    if [[ -f "$project_dir/config.xml" || -d "$project_dir/platforms/android" ]]; then
        echo "cordova"
        return
    fi
}

require_cmd() {
    if ! command -v "$1" &>/dev/null; then
        echo "Error: $1 is not installed or not in PATH." >&2
        exit 1
    fi
}

# Require a value for an option (next arg must be non-empty and not another option)
require_value() {
    if [[ -z "${2:-}" || "$2" == -* ]]; then
        echo "Error: Option $1 requires a value." >&2
        exit 1
    fi
}

# --- pair ---
pair_device() {
    local DEVICE_IP="$1"
    local PAIRING_PORT="$2"
    local PAIRING_CODE="$3"
    local ADB_PORT="${4:-5555}"

    if [[ -z "$DEVICE_IP" || -z "$PAIRING_PORT" || -z "$PAIRING_CODE" ]]; then
        echo "Usage: $SCRIPT_NAME pair -ip <device_ip> -pt <port> -code <pairing_code> [-adb <adb_port>]" >&2
        exit 1
    fi

    require_cmd adb

    echo "Pairing with device at $DEVICE_IP:$PAIRING_PORT..."
    if ! adb pair "$DEVICE_IP:$PAIRING_PORT" <<< "$PAIRING_CODE"; then
        echo "Pairing failed! Check the pairing details and that the device is in wireless pairing mode." >&2
        exit 1
    fi

    echo "Pairing successful. Connecting on port $ADB_PORT..."
    adb connect "$DEVICE_IP:$ADB_PORT"
    adb devices
}

# --- new ---
create_ionic_project() {
    local PROJECT_NAME="$1"
    local APP_ID="$2"
    local PLATFORM="$3"
    local TEMPLATE="${4:-sidemenu}"

    if [[ -z "$PROJECT_NAME" || -z "$APP_ID" || -z "$PLATFORM" ]]; then
        echo "Usage: $SCRIPT_NAME new -nw <project_name> -id <app_id> -pf <capacitor|cordova> [-t <template>]" >&2
        exit 1
    fi

    if [[ -d "$PROJECT_NAME" ]]; then
        echo "Error: Directory '$PROJECT_NAME' already exists." >&2
        exit 1
    fi

    echo "Creating Ionic project: $PROJECT_NAME (id=$APP_ID, platform=$PLATFORM, template=$TEMPLATE)"

    if [[ "$PLATFORM" == "capacitor" ]]; then
        ionic start "$PROJECT_NAME" "$TEMPLATE" --type=angular-standalone --capacitor --package-id="$APP_ID"
    elif [[ "$PLATFORM" == "cordova" ]]; then
        ionic start "$PROJECT_NAME" "$TEMPLATE" --type=angular --cordova --package-id="$APP_ID"
    else
        echo "Invalid platform. Use 'capacitor' or 'cordova'." >&2
        exit 1
    fi

    echo "Ionic project '$PROJECT_NAME' created successfully."
}

# --- build ---
build_project() {
    local PROJECT_NAME="$1"
    local PLATFORM="$2"

    if [[ -z "$PROJECT_NAME" || -z "$PLATFORM" ]]; then
        echo "Usage: $SCRIPT_NAME build -nw <project_name> -pf <capacitor|cordova>" >&2
        exit 1
    fi

    if [[ ! -d "$PROJECT_NAME" ]]; then
        echo "Error: Project directory '$PROJECT_NAME' not found. Run from the directory that contains it." >&2
        exit 1
    fi

    echo "Building Ionic project: $PROJECT_NAME (platform=$PLATFORM)"

    cd "$PROJECT_NAME"

    if [[ "$PLATFORM" == "capacitor" ]]; then
        ionic build
        # Ensure Capacitor Android platform: install @capacitor/android if missing, then add native project if needed
        if ! npm list @capacitor/android &>/dev/null; then
            echo "Installing @capacitor/android..."
            npm install @capacitor/android
        fi
        if [[ ! -d android ]]; then
            echo "Adding Android platform..."
            npx cap add android
        fi
        npx cap sync
        cd android
        if [[ ! -x ./gradlew ]]; then
            chmod +x ./gradlew
        fi
        ./gradlew assembleDebug
        cd ..
    elif [[ "$PLATFORM" == "cordova" ]]; then
        ionic cordova build android
    else
        echo "Invalid platform. Use 'capacitor' or 'cordova'." >&2
        exit 1
    fi

    cd - >/dev/null
    echo "Build complete."
}

# --- install ---
install_apk() {
    local PROJECT_NAME="$1"
    local PLATFORM="$2"

    if [[ -z "$PROJECT_NAME" || -z "$PLATFORM" ]]; then
        echo "Usage: $SCRIPT_NAME install -nw <project_name> -pf <capacitor|cordova>" >&2
        exit 1
    fi

    local APK_PATH
    if [[ "$PLATFORM" == "capacitor" ]]; then
        APK_PATH="$PROJECT_NAME/android/app/build/outputs/apk/debug/app-debug.apk"
    elif [[ "$PLATFORM" == "cordova" ]]; then
        APK_PATH="$PROJECT_NAME/platforms/android/app/build/outputs/apk/debug/app-debug.apk"
    else
        echo "Invalid platform. Use 'capacitor' or 'cordova'." >&2
        exit 1
    fi

    if [[ ! -f "$APK_PATH" ]]; then
        echo "Error: APK not found at $APK_PATH. Run '$SCRIPT_NAME build -nw $PROJECT_NAME -pf $PLATFORM' first." >&2
        exit 1
    fi

    require_cmd adb

    echo "Installing APK for $PROJECT_NAME on device..."
    adb install -r "$APK_PATH"
    echo "Installation complete."
}

# --- main ---
case "${1:-}" in
    pair)
        shift
        DEVICE_IP="" PAIRING_PORT="" PAIRING_CODE="" ADB_PORT="5555"
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -ip)   require_value "$1" "${2:-}"; DEVICE_IP="$2";   shift 2 ;;
                -pt)   require_value "$1" "${2:-}"; PAIRING_PORT="$2"; shift 2 ;;
                -code) require_value "$1" "${2:-}"; PAIRING_CODE="$2"; shift 2 ;;
                -adb)  require_value "$1" "${2:-}"; ADB_PORT="$2";    shift 2 ;;
                *)     echo "Unknown option: $1" >&2; exit 1 ;;
            esac
        done
        pair_device "$DEVICE_IP" "$PAIRING_PORT" "$PAIRING_CODE" "$ADB_PORT"
        ;;

    new)
        shift
        PROJECT_NAME="" APP_ID="" PLATFORM="" TEMPLATE="sidemenu"
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -nw) require_value "$1" "${2:-}"; PROJECT_NAME="$2"; shift 2 ;;
                -id) require_value "$1" "${2:-}"; APP_ID="$2";        shift 2 ;;
                -pf) require_value "$1" "${2:-}"; PLATFORM="$2";      shift 2 ;;
                -t)  require_value "$1" "${2:-}"; TEMPLATE="$2";       shift 2 ;;
                *)   echo "Unknown option: $1" >&2; exit 1 ;;
            esac
        done
        create_ionic_project "$PROJECT_NAME" "$APP_ID" "$PLATFORM" "$TEMPLATE"
        ;;

    build)
        shift
        PROJECT_NAME="" PLATFORM=""
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -nw) require_value "$1" "${2:-}"; PROJECT_NAME="$2"; shift 2 ;;
                -pf) require_value "$1" "${2:-}"; PLATFORM="$2";      shift 2 ;;
                *)   echo "Unknown option: $1" >&2; exit 1 ;;
            esac
        done
        if [[ -z "$PROJECT_NAME" ]]; then
            PROJECT_NAME="$(detect_project_root)"
            if [[ -z "$PROJECT_NAME" ]]; then
                echo "Error: Not in an Ionic project. Use -nw <project_name> or run from project root." >&2
                exit 1
            fi
        fi
        if [[ -z "$PLATFORM" ]]; then
            PLATFORM="$(detect_platform "$PROJECT_NAME")"
            if [[ -z "$PLATFORM" ]]; then
                echo "Error: Could not detect platform. Use -pf capacitor or -pf cordova." >&2
                exit 1
            fi
        fi
        build_project "$PROJECT_NAME" "$PLATFORM"
        ;;

    install)
        shift
        PROJECT_NAME="" PLATFORM=""
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -nw) require_value "$1" "${2:-}"; PROJECT_NAME="$2"; shift 2 ;;
                -pf) require_value "$1" "${2:-}"; PLATFORM="$2";      shift 2 ;;
                *)   echo "Unknown option: $1" >&2; exit 1 ;;
            esac
        done
        if [[ -z "$PROJECT_NAME" ]]; then
            PROJECT_NAME="$(detect_project_root)"
            if [[ -z "$PROJECT_NAME" ]]; then
                echo "Error: Not in an Ionic project. Use -nw <project_name> or run from project root." >&2
                exit 1
            fi
        fi
        if [[ -z "$PLATFORM" ]]; then
            PLATFORM="$(detect_platform "$PROJECT_NAME")"
            if [[ -z "$PLATFORM" ]]; then
                echo "Error: Could not detect platform. Use -pf capacitor or -pf cordova." >&2
                exit 1
            fi
        fi
        install_apk "$PROJECT_NAME" "$PLATFORM"
        ;;

    help|--help|-h)
        usage
        ;;

    *)
        echo "Usage: $SCRIPT_NAME {pair|new|build|install|help} [options]" >&2
        exit 1
        ;;
esac
