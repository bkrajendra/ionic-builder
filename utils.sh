#!/bin/bash

# Function to pair the device
pair_device() {
    local DEVICE_IP="$1"
    local PAIRING_PORT="$2"
    local PAIRING_CODE="$3"

    if [[ -z "$DEVICE_IP" || -z "$PAIRING_PORT" || -z "$PAIRING_CODE" ]]; then
        echo "Usage: $0 pair -ip <device_ip> -pt <port> -code <pairing_code>"
        exit 1
    fi

    echo "Pairing with device at $DEVICE_IP:$PAIRING_PORT..."
    adb pair $DEVICE_IP:$PAIRING_PORT <<< $PAIRING_CODE

    if [ $? -eq 0 ]; then
        echo "Pairing successful. Connecting to device..."
        adb connect $DEVICE_IP:5555
        adb devices
    else
        echo "Pairing failed! Please check the pairing details."
        exit 1
    fi
}

# Function to create a new Ionic project
create_ionic_project() {
    local PROJECT_NAME="$1"
    local APP_ID="$2"
    local PLATFORM="$3"

    if [[ -z "$PROJECT_NAME" || -z "$APP_ID" || -z "$PLATFORM" ]]; then
        echo "Usage: $0 new -nw <project_name> -id <app_id> -pf <capacitor|cordova>"
        exit 1
    fi

    echo "Creating new Ionic project: $PROJECT_NAME with ID: $APP_ID on $PLATFORM"

    if [ "$PLATFORM" == "capacitor" ]; then
        ionic start "$PROJECT_NAME" sidemenu --type=angular-standalone --capacitor --package-id="$APP_ID"
    elif [ "$PLATFORM" == "cordova" ]; then
        ionic start "$PROJECT_NAME" sidemenu --type=angular --cordova --package-id="$APP_ID"
    else
        echo "Invalid platform! Choose 'capacitor' or 'cordova'."
        exit 1
    fi

    echo "Ionic project $PROJECT_NAME created successfully!"
}

# Function to build the Ionic project
build_project() {
    local PROJECT_NAME="$1"
    local PLATFORM="$2"

    if [[ -z "$PROJECT_NAME" || -z "$PLATFORM" ]]; then
        echo "Usage: $0 build -nw <project_name> -pf <capacitor|cordova>"
        exit 1
    fi

    echo "Building Ionic project: $PROJECT_NAME"

    cd "$PROJECT_NAME" || { echo "Project not found!"; exit 1; }

    if [ "$PLATFORM" == "capacitor" ]; then
        ionic build
        npx cap add android
        npx cap sync
        cd android && ./gradlew assembleDebug
    elif [ "$PLATFORM" == "cordova" ]; then
        ionic cordova build android
    fi

    echo "Build complete!"
}

# Function to install APK on the device
install_apk() {
    local PROJECT_NAME="$1"
    local PLATFORM="$2"

    if [[ -z "$PROJECT_NAME" || -z "$PLATFORM" ]]; then
        echo "Usage: $0 install -nw <project_name> -pf <capacitor|cordova>"
        exit 1
    fi

    echo "Installing APK for $PROJECT_NAME on device..."

    if [ "$PLATFORM" == "capacitor" ]; then
        APK_PATH="$PROJECT_NAME/android/app/build/outputs/apk/debug/app-debug.apk"
    elif [ "$PLATFORM" == "cordova" ]; then
        APK_PATH="$PROJECT_NAME/platforms/android/app/build/outputs/apk/debug/app-debug.apk"
    fi

    adb install -r "$APK_PATH"
    echo "Installation complete!"
}

# Main script logic to parse arguments
case "$1" in
    pair)
        shift
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -ip) DEVICE_IP="$2"; shift ;;
                -pt) PAIRING_PORT="$2"; shift ;;
                -code) PAIRING_CODE="$2"; shift ;;
                *) echo "Unknown option: $1"; exit 1 ;;
            esac
            shift
        done
        pair_device "$DEVICE_IP" "$PAIRING_PORT" "$PAIRING_CODE"
        ;;
    
    new)
        shift
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -nw) PROJECT_NAME="$2"; shift ;;
                -id) APP_ID="$2"; shift ;;
                -pf) PLATFORM="$2"; shift ;;
                *) echo "Unknown option: $1"; exit 1 ;;
            esac
            shift
        done
        create_ionic_project "$PROJECT_NAME" "$APP_ID" "$PLATFORM"
        ;;

    build)
        shift
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -nw) PROJECT_NAME="$2"; shift ;;
                -pf) PLATFORM="$2"; shift ;;
                *) echo "Unknown option: $1"; exit 1 ;;
            esac
            shift
        done
        build_project "$PROJECT_NAME" "$PLATFORM"
        ;;

    install)
        shift
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -nw) PROJECT_NAME="$2"; shift ;;
                -pf) PLATFORM="$2"; shift ;;
                *) echo "Unknown option: $1"; exit 1 ;;
            esac
            shift
        done
        install_apk "$PROJECT_NAME" "$PLATFORM"
        ;;

    *)
        echo "Usage: $0 {pair|new|build|install} [options]"
        exit 1
        ;;
esac
