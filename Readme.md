# Ionic Builder Image 🏗️🚀

[![Docker Pulls](https://img.shields.io/badge/docker-pulls-blue?logo=docker)](https://hub.docker.com/)  
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

[![Build and Push Docker Image](https://github.com/bkrajendra/ionic-builder/actions/workflows/docker-build-push.yml/badge.svg)](https://github.com/bkrajendra/ionic-builder/actions/workflows/docker-build-push.yml)

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Docker Usage](#docker-usage)
  - [Pull the image](#pull-the-image)
  - [Build the image locally](#build-the-image-locally)
  - [Interactive shell](#interactive-shell)
  - [Build Android APK](#build-android-apk)
  - [Run the Ionic dev server](#run-the-ionic-dev-server)
- [Utils script](#utils-script)
  - [Overview](#utils-overview)
  - [pair — wireless ADB pairing](#pair--wireless-adb-pairing)
  - [new — create Ionic project](#new--create-ionic-project)
  - [build — build Android APK](#build--build-android-apk)
  - [install — install APK on device](#install--install-apk-on-device)
  - [help](#help)
- [Support](#support)
- [License](#license)

---

## Overview

This Docker image provides a **self-contained environment** for building [Ionic](https://ionicframework.com/) projects using **Capacitor** or **Cordova**. It eliminates the need to install Android Studio, Node.js, or other dependencies on your local machine. Perfect for:

- 🚀 **Building** Ionic Capacitor and Cordova projects
- 🛠️ **Running a dev environment** without local setup
- 🤖 **CI/CD pipelines** for automated Ionic app builds

## Features

- ✅ Pre-installed: **Node.js, npm, Ionic CLI, Capacitor CLI, Cordova CLI**
- ✅ **Android SDK, Gradle, Java** (for Android builds)
- ✅ No need for **Android Studio** on the host
- ✅ Works in **local dev & CI/CD environments**
- ✅ Supports **Capacitor & Cordova**
- ✅ **Utils script** for pairing devices, creating projects, building, and installing APKs

## Requirements

- [Docker](https://www.docker.com/) installed
- For Android builds: an Ionic project (Capacitor or Cordova)

---

## Docker Usage

The container’s working directory is **`/workdir`**. Mount your project (or the folder that contains it) there so commands run in the right place.

**Image name:** `bkrajendra/ionic-builder:ionic-8` (or the tag from [Docker Hub](https://hub.docker.com/r/bkrajendra/ionic-builder)).

### Avoiding `node_modules` / esbuild issues (Windows or mixed host)

If your project was edited or `npm install` was run on **Windows**, the host’s `node_modules` contains Windows-specific binaries. Mounting that into the Linux container causes **esbuild** (and other native addons) to fail. Fix: **don’t mount `node_modules`** — use an anonymous volume so the container has its own Linux `node_modules`:

- Add a second volume: **`-v /workdir/node_modules`** (same path inside the container).
- Docker overlays that path with an empty volume, so the host’s `node_modules` is not used.
- Run **`npm install`** or **`npm ci`** once inside the container (or in your one-shot `docker run ... bash -c "..."`) so dependencies are installed for Linux.

All examples below use this pattern where relevant.

### Pull the image

```bash
docker pull bkrajendra/ionic-builder:ionic-8
```

### Build the image locally

```bash
git clone https://github.com/bkrajendra/ionic-builder.git
cd ionic-builder
docker build -t bkrajendra/ionic-builder:ionic-8 .
```

### Interactive shell

Mount your project and open a shell. Use this to run any Ionic/Capacitor/Cordova commands or the [utils script](#utils-script). The extra **`-v /workdir/node_modules`** keeps the host’s `node_modules` out of the container (avoids esbuild/Windows compatibility issues). Use **`--network host`** so the container can reach your Android device for wireless ADB (pair, connect, install).

```bash
# From your project root (or the folder that contains your project)
docker run -it --rm --network host -v "$(pwd)":/workdir -v /workdir/node_modules bkrajendra/ionic-builder:ionic-8 bash
```

Inside the container you’re in `/workdir` (your project). Run **`npm install`** or **`npm ci`** once so dependencies are installed for Linux, then run `ionic`, `npx cap`, or **`utils`** as needed.

**Windows (Git Bash):** Git Bash can convert paths so Docker mounts the wrong directory (e.g. under `Program Files\Git`). Use a **Windows-style path** and still exclude `node_modules`:

```bash
# Prefer: use Windows path (Git for Windows)
docker run -it --rm --network host -v "$(pwd -W):/workdir" -v /workdir/node_modules bkrajendra/ionic-builder:ionic-8 bash
```

If `pwd -W` is not available, use `cygpath`:

```bash
docker run -it --rm --network host -v "$(cygpath -w "$(pwd)"):/workdir" -v /workdir/node_modules bkrajendra/ionic-builder:ionic-8 bash
```

Or use **PowerShell** or **CMD** from your project directory:

```powershell
# PowerShell
docker run -it --rm --network host -v "${PWD}:/workdir" -v /workdir/node_modules bkrajendra/ionic-builder:ionic-8 bash
```

```cmd
REM CMD (run from your project directory)
docker run -it --rm --network host -v "%CD%:/workdir" -v /workdir/node_modules bkrajendra/ionic-builder:ionic-8 bash
```

### Build Android APK

Run from the host; the container will build and exit. Mount the directory that **contains** your Ionic project so that the project folder name matches what you pass to the script. Use **`-v /workdir/node_modules`** so the container uses Linux-built dependencies. Add **`--network host`** if you will use the same container for device install (e.g. `utils install`) so ADB can reach the device.  
*(On Git Bash use the same [volume fix](#interactive-shell) as for the interactive shell, e.g. `$(pwd -W)`.)*

**Capacitor (manual commands):**

```bash
docker run --rm --network host -v "$(pwd)":/workdir -v /workdir/node_modules bkrajendra/ionic-builder:ionic-8 bash -c "
  npm ci && ionic build && npx cap sync android && cd android && ./gradlew assembleDebug
"
```

**Cordova:**

```bash
docker run --rm --network host -v "$(pwd)":/workdir -v /workdir/node_modules bkrajendra/ionic-builder:ionic-8 bash -c "
  npm ci && ionic cordova build android
"
```

Or use the [utils script](#build--build-android-apk) inside the container (e.g. after `docker run -it --network host ... bash`); run `npm ci` once in the container before using the script.

### Run the Ionic dev server

```bash
docker run -it --rm --network host -v "$(pwd)":/workdir -v /workdir/node_modules bkrajendra/ionic-builder:ionic-8 bash -c "
  npm ci && ionic serve --host=0.0.0.0
"
```

*(On Git Bash use `$(pwd -W)` for the first volume.)* With `--network host`, the app is reachable at [http://localhost:8100](http://localhost:8100). Run `npm ci` once so dependencies exist in the container.

---

## Utils script

The image includes a helper script that is available as a **global command** so you can run it from anywhere:

- **`utils`** — call from any directory (recommended)
- **`/opt/utils.sh`** — full path (same behavior)

Use it to pair a device, create a new Ionic project, build an Android APK, or install the APK. For **build** and **install**, if you run from the **project root**, the script auto-detects the project and platform (Capacitor vs Cordova), so you can omit **`-nw`** and **`-pf`**.

**General form:**

```bash
utils <command> [options]
```

**Quick help:**

```bash
utils help
```

### Utils overview

| Command   | Description                          |
|----------|--------------------------------------|
| `pair`   | Pair a device for wireless ADB       |
| `new`    | Create a new Ionic project           |
| `build`  | Build Android debug APK              |
| `install`| Install the built APK on a device    |
| `help`   | Show usage and options               |

### pair — wireless ADB pairing

Pair an Android device for wireless debugging, then connect over ADB.

```bash
utils pair -ip <device_ip> -pt <pairing_port> -code <pairing_code> [-adb <adb_port>]
```

| Option   | Required | Description                                      |
|----------|----------|--------------------------------------------------|
| `-ip`    | Yes      | Device IP address                                |
| `-pt`    | Yes      | Pairing port (shown on device)                   |
| `-code`  | Yes      | Pairing code (shown on device)                   |
| `-adb`   | No       | ADB connection port (default: `5555`)            |

**Example:**

```bash
utils pair -ip 192.168.1.100 -pt 37123 -code 123456
```

**If you paired manually** (e.g. `adb pair IP:port` + code) and `adb devices` is empty: pairing alone is not enough — you must **connect** on the ADB port. On Android 11+ wireless debugging, the device shows “Connect to IP:**port**” (often not 5555). Run:
```bash
adb connect 172.16.1.16:<port>
```
Use the port shown on the device, then run `adb devices` again.

### new — create Ionic project

Scaffold a new Ionic app with Capacitor or Cordova.

```bash
utils new -nw <project_name> -id <app_id> -pf <capacitor|cordova> [-t <template>]
```

| Option   | Required | Description                                      |
|----------|----------|--------------------------------------------------|
| `-nw`    | Yes      | Project (folder) name                            |
| `-id`    | Yes      | Application / package ID (e.g. `com.example.app`) |
| `-pf`    | Yes      | `capacitor` or `cordova`                         |
| `-t`     | No       | Ionic template (default: `sidemenu`), e.g. `tabs`, `blank` |

**Examples:**

```bash
utils new -nw myapp -id com.example.myapp -pf capacitor
utils new -nw myapp -id com.example.myapp -pf cordova -t tabs
```

### build — build Android APK

Build a debug Android APK. From the **project root** you can omit `-nw` and `-pf` (auto-detected).

```bash
utils build [-nw <project_name>] [-pf <capacitor|cordova>]
```

| Option   | Required | Description                |
|----------|----------|----------------------------|
| `-nw`    | No*      | Project folder name (or `.` for current dir). *Omit when run from project root.* |
| `-pf`    | No*      | `capacitor` or `cordova`. *Omit to auto-detect from project.* |

**Examples:**

```bash
# From project root: auto-detect project and platform
utils build

# From project root: specify platform only
utils build -pf capacitor

# From parent directory: specify project (and optionally platform)
utils build -nw myapp -pf capacitor
```

### install — install APK on device

Install the built debug APK on a connected device (USB or already paired wireless). From the **project root** you can omit `-nw` and `-pf`.

```bash
utils install [-nw <project_name>] [-pf <capacitor|cordova>]
```

Options are the same as for `build`. Run `build` first; if the APK is missing, the script will report an error.

**Examples:**

```bash
# From project root (auto-detect)
utils install

# From project root with platform
utils install -pf capacitor

# From parent directory
utils install -nw myapp -pf capacitor
```

### help

Show usage and all commands:

```bash
utils help
# or
utils --help
```

---


### Adding GitHub Secrets

To use private registries or store credentials:

1. Open your repo on GitHub → **Settings** → **Secrets and variables** → **Actions**.
2. Click **New repository secret**.
3. Set **Name** (e.g. `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN`) and **Value**.
4. Use in workflows: `${{ secrets.SECRET_NAME }}`.

---

## Support

For issues or improvements, open an [issue](https://github.com/bkrajendra/ionic-builder/issues) or submit a pull request.

## License

This project is released under the [MIT License](LICENSE).
