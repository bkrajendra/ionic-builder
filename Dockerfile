# docker push bkrajendra/ionic-builder:ionic-8
FROM ubuntu:24.04

LABEL MAINTAINER="Rajenda Khope <bkrajendra@gmail.com>"
LABEL description="Build environment for Ionic Capacitor and Cordova apps"

ARG JAVA_VERSION=21
ARG NODEJS_VERSION=24
# https://developer.android.com/studio#command-line-tools-only
# commandlinetools-linux-14742923_latest.zip
ARG ANDROID_SDK_VERSION=14742923
# See https://developer.android.com/tools/releases/build-tools
ARG ANDROID_BUILD_TOOLS_VERSION=36.0.0
# See https://developer.android.com/studio/releases/platforms
ARG ANDROID_PLATFORMS_VERSION=36
# See https://gradle.org/releases/
ARG GRADLE_VERSION=8.14.3
# See https://www.npmjs.com/package/@ionic/cli
ARG IONIC_VERSION=7.2.1
# See https://www.npmjs.com/package/@capacitor/cli
ARG CAPACITOR_VERSION=8.1.0
# See https://www.npmjs.com/package/cordova
ARG CORDOVA_VERSION=13.0.0

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
# Use fixed path for global npm so it works regardless of runtime HOME
ENV NPM_CONFIG_PREFIX=/opt/npm-global
ENV PATH=$PATH:/opt/npm-global/bin

WORKDIR /tmp

RUN apt-get update -q \
    && apt-get install -qy --no-install-recommends \
        apt-utils \
        locales \
        gnupg2 \
        ca-certificates \
        build-essential \
        curl \
        usbutils \
        git \
        unzip \
        p7zip-full \
        python3 \
        openjdk-${JAVA_VERSION}-jdk \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Install Gradle
ENV GRADLE_HOME=/opt/gradle
RUN mkdir -p $GRADLE_HOME \
    && curl -fsSL https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -o gradle.zip \
    && unzip -q gradle.zip -d $GRADLE_HOME \
    && rm gradle.zip
ENV PATH=$PATH:${GRADLE_HOME}/gradle-${GRADLE_VERSION}/bin

# Install Android SDK (cmdline-tools must live under .../cmdline-tools/latest/ per Android docs)
ENV ANDROID_HOME=/opt/android-sdk
RUN curl -fsSL "https://dl.google.com/android/repository/commandlinetools-linux-${ANDROID_SDK_VERSION}_latest.zip" -o cmdline-tools.zip \
    && unzip -q cmdline-tools.zip \
    && rm cmdline-tools.zip \
    && mkdir -p $ANDROID_HOME/cmdline-tools/latest \
    && mv cmdline-tools/* $ANDROID_HOME/cmdline-tools/latest/ \
    && rmdir cmdline-tools \
    && yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --sdk_root=$ANDROID_HOME --licenses \
    && $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --sdk_root=$ANDROID_HOME \
        "platform-tools" \
        "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" \
        "platforms;android-${ANDROID_PLATFORMS_VERSION}"
ENV PATH=$PATH:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools

# Install Node.js (nodesource setup)
RUN curl -fsSL https://deb.nodesource.com/setup_${NODEJS_VERSION}.x | bash - \
    && apt-get update -q \
    && apt-get install -qy --no-install-recommends nodejs \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Install Ionic, Capacitor, and Cordova CLIs (Cordova required for utils.sh)
RUN mkdir -p $NPM_CONFIG_PREFIX \
    && npm install -g --no-fund --no-audit \
        @ionic/cli@${IONIC_VERSION} \
        @capacitor/cli@${CAPACITOR_VERSION} \
        cordova@${CORDOVA_VERSION}

# Copy util script and expose as global command (run from anywhere)
COPY utils.sh /opt/utils.sh
RUN chmod +x /opt/utils.sh \
    && ln -sf /opt/utils.sh /usr/local/bin/utils

# Final cleanup of build artifacts
RUN rm -rf /tmp/*

WORKDIR /workdir
