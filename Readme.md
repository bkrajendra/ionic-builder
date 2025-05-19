# Ionic Builder Image 🏗️🚀

[![Docker Pulls](https://img.shields.io/badge/docker-pulls-blue?logo=docker)](https://hub.docker.com/)  
[![License: MIT](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

---

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Usage](#usage)
  - [Run an Interactive Development Environment](#run-an-interactive-development-environment)
  - [Build an Android APK (Capacitor)](#build-an-android-apk-capacitor)
  - [Build a Cordova Project](#build-a-cordova-project)
  - [Run the Ionic Development Server](#run-the-ionic-development-server)
- [CI/CD Integration](#cicd-integration)
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

## Requirements
- [Docker](https://www.docker.com/) installed
- A valid Ionic project (Capacitor or Cordova)

## Usage

### Run an Interactive Development Environment
```sh
docker run -it --rm -v $(pwd):/app your-image-name bash
```
This mounts your project inside the container, allowing you to run Ionic commands interactively.

### Build an Android APK (Capacitor)
```sh
docker run --rm -v $(pwd):/app your-image-name bash -c "ionic build && npx cap add android && npx cap sync android && cd android && ./gradlew assembleDebug"
```

### Build a Cordova Project
```sh
docker run --rm -v $(pwd):/app your-image-name bash -c "ionic cordova build android"
```

### Run the Ionic Development Server
```sh
docker run -it --rm -p 8100:8100 -v $(pwd):/app your-image-name bash -c "ionic serve --host=0.0.0.0"
```
Access your app at [http://localhost:8100](http://localhost:8100).

## CI/CD Integration
You can use this image in GitHub Actions, GitLab CI, Jenkins, or Bitbucket Pipelines to automate Ionic builds.

**Example: GitHub Actions Workflow**
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Build Ionic App (Capacitor)
        uses: addnab/docker-run-action@v3
        with:
          image: your-image-name
          options: -v ${{ github.workspace }}:/app
          run: |
            ionic build
            npx cap sync android
            cd android
            ./gradlew assembleDebug
```

## Support
For issues, please open an [issue](https://github.com/your-repo/issues) or submit a pull request.

## License
This image is released under the [MIT License](LICENSE).

