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

### Adding GitHub Secrets
To add GitHub secrets for your repository, follow these steps:

1. **Access Repository Settings**
   - Go to your GitHub repository in your web browser
   - Click on the "Settings" tab at the top of your repository page

2. **Navigate to Secrets**
   - In the left sidebar, click on "Secrets and variables"
   - Select "Actions"

3. **Add a New Secret**
   - Click on the "New repository secret" button
   - Enter the following details:
     - **Name**: Enter the name of your secret (e.g., `DOCKERHUB_USERNAME` or `DOCKERHUB_TOKEN`)
     - **Value**: Enter the value of your secret (e.g., your DockerHub username or access token)
   - Click "Add secret" to save it

4. **Repeat for Additional Secrets**
   - If you need to add more secrets (like `DOCKERHUB_TOKEN`), repeat the process

These secrets will be securely stored and can be used in your GitHub Actions workflows using the syntax:
```yaml
${{ secrets.SECRET_NAME }}
```

## Support
For issues, please open an [issue](https://github.com/your-repo/issues) or submit a pull request.

## License
This image is released under the [MIT License](LICENSE).

