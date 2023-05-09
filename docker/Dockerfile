FROM rust:1.68 AS android-bindings-builder
USER root
ENV SDK_URL="https://dl.google.com/android/repository/commandlinetools-linux-8092744_latest.zip" \
    ANDROID_HOME="/usr/local/android-sdk" \
    ANDROID_VERSION=21 \
    ANDROID_PLATFORM=21 \
    ANDROID_BUILD_TOOLS_VERSION=32.0.0 \
    NDK_VERSION="25.2.9519653" \
    PATH="$PATH":/usr/local/bin:/usr/local/google-cloud-sdk/bin:/usr/local/android-sdk/cmdline-tools/bin:/usr/local/android-sdk/platform-tools \
    GCLOUD_URL="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-294.0.0-linux-x86_64.tar.gz"

#NDK_URL="https://dl.google.com/android/repository/android-ndk-r25c-linux.zip" \   
# Install Build Essentials
RUN apt-get update && apt-get install --yes \
    apt-utils \
    binutils \
    build-essential \
    cmake \
    default-jdk \
    file \
    libc6-dev \
    python \
    python3-pip \
    libclang-dev \
    protobuf-compiler

COPY rust-toolchain .
RUN rustup toolchain install $(cat rust-toolchain) \
    && rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android \
    && rustup update \
    && rustup target add --toolchain $(cat rust-toolchain) \
        aarch64-linux-android \
        armv7-linux-androideabi \
        i686-linux-android \
        x86_64-linux-android \
    && rustup component add rustfmt
    #&& cargo install sccache

RUN mkdir -p $ANDROID_HOME \
    && cd $ANDROID_HOME \
    && wget $SDK_URL \
    && unzip commandlinetools-linux-8092744_latest.zip \
    && rm -rf commandlinetools-linux-8092744_latest.zip \
    && yes | sdkmanager --licenses --sdk_root=$ANDROID_HOME \
    && sdkmanager --sdk_root=$ANDROID_HOME \
        "build-tools;$ANDROID_BUILD_TOOLS_VERSION" \
        "ndk;$NDK_VERSION" \
        "platforms;android-$ANDROID_VERSION"

ENV NDK_HOME=${ANDROID_HOME}/ndk/$NDK_VERSION
ENV PATH=$PATH:$NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin \
    SGX_MODE=HW \
    IAS_MODE=DEV \
    #AR=${NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar
    AR_aarch64_linux_android=${NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar \
    AR_armv7-linux-androideabi=${NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar \
    AR_arm-linux-androideabi==${NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar \
    AR_i686-linux-android=${NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar \
    AR_x86_64-linux-android=${NDK_HOME}/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar

RUN cp $NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android21-clang $NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/bin/i686-linux-android-clang
