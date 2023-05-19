# Copyright (c) 2018-2022 The MobileCoin Foundation

# Working directory is the root of the project
pwd=$(shell pwd)

.PHONY : build test libs docker_image clean setup-docker all default strip copy_artifacts dist
default: build

export SGX_MODE ?= HW
export IAS_MODE ?= DEV

CARGO_PROFILE ?= mobile
ARCHS = aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android
DOCKER_BUILDER_IMAGE_TAG = gcr.io/mobilenode-211420/android-bindings-builder:1_4
CARGO_BUILD_FLAGS += -Zunstable-options --profile=$(CARGO_PROFILE)
BUILD_DEPS_FOLDER = /tmp/build/deps/
MIN_API_LEVEL = 19
MIN_API_LEVEL_64_BIT = 21
JNI_LIBS_PATH = lib-wrapper/android-bindings/src/main/jniLibs

setup-rust:
	rustup toolchain install $(file < mobilecoin/rust-toolchain)
	rustup component add rustfmt
	rustup target add $(ARCHS)
	rustup update

aarch64-linux-android: CARGO_ENV_FLAGS += \
	ISYSROOT=$(NDK_HOME)/toolchains/llvm/prebuilt/linux-x86_64/sysroot \
	ISYSTEM=$(NDK_HOME)/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/aarch64-linux-android \
	AR=llvm-ar \
	CFLAGS=-Wno-error=unused-but-set-parameter \
	CXX=aarch64-linux-android$(MIN_API_LEVEL_64_BIT)-clang++ \
	CC=aarch64-linux-android$(MIN_API_LEVEL_64_BIT)-clang \
	CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER=aarch64-linux-android$(MIN_API_LEVEL_64_BIT)-clang \
	CARGO_TARGET_DIR=target/aarch64 \
	CMAKE_TARGET_OVERRIDE=aarch64-linux-android$(MIN_API_LEVEL_64_BIT)

armv7-linux-androideabi: CARGO_ENV_FLAGS += \
	ISYSROOT=$(NDK_HOME)/toolchains/llvm/prebuilt/linux-x86_64/sysroot \
	ISYSTEM=$(NDK_HOME)/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/arm-linux-androideabi \
	AR=llvm-ar \
	CFLAGS=-Wno-error=unused-but-set-parameter \
	CXX=armv7a-linux-androideabi$(MIN_API_LEVEL)-clang++ \
	CC=armv7a-linux-androideabi$(MIN_API_LEVEL)-clang \
	CARGO_TARGET_ARMV7_LINUX_ANDROIDEABI_LINKER=armv7a-linux-androideabi$(MIN_API_LEVEL)-clang \
	CARGO_TARGET_DIR=target/armv7 \
	CMAKE_TARGET_OVERRIDE=armv7a-linux-androideabi$(MIN_API_LEVEL)

i686-linux-android: CARGO_ENV_FLAGS += \
	ISYSROOT=$(NDK_HOME)/toolchains/llvm/prebuilt/linux-x86_64/sysroot \
	ISYSTEM=$(NDK_HOME)/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/i686-linux-android \
	AR=llvm-ar \
	CFLAGS="-Wno-error=unused-but-set-parameter -Wno-error=unused-parameter" \
	CXX=i686-linux-android$(MIN_API_LEVEL)-clang++ \
	CC=i686-linux-android$(MIN_API_LEVEL)-clang \
	CARGO_TARGET_I686_LINUX_ANDROID_LINKER=i686-linux-android$(MIN_API_LEVEL)-clang \
	CARGO_TARGET_DIR=target/i686 \
	CMAKE_TARGET_OVERRIDE=i686-linux-android$(MIN_API_LEVEL)

x86_64-linux-android: CARGO_ENV_FLAGS += \
	ISYSROOT=$(NDK_HOME)/toolchains/llvm/prebuilt/linux-x86_64/sysroot \
	ISYSTEM=$(NDK_HOME)/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/include/x86_64-linux-android \
	AR=llvm-ar \
	CFLAGS=-Wno-error=unused-but-set-parameter \
	CXX=x86_64-linux-android$(MIN_API_LEVEL_64_BIT)-clang++ \
	CC=x86_64-linux-android$(MIN_API_LEVEL_64_BIT)-clang \
	CARGO_TARGET_X86_64_LINUX_ANDROID_LINKER=x86_64-linux-android$(MIN_API_LEVEL_64_BIT)-clang \
	CARGO_TARGET_DIR=target/x86_64 \
	CMAKE_TARGET_OVERRIDE=x86_64-linux-android$(MIN_API_LEVEL_64_BIT)

$(ARCHS):
	$(CARGO_ENV_FLAGS) cargo build \
		$(CARGO_BUILD_FLAGS) \
		--target $@

libs: $(ARCHS) strip copy_artifacts

publish: libs
	cd lib-wrapper && \
	./gradlew build && \
	./gradlew publish

ci: setup-docker
	docker run \
		--rm \
		-e MAVEN_USER \
		-e MAVEN_PASSWORD \
		-v $(pwd):/home/rust/ \
		-v $(BUILD_DEPS_FOLDER):/usr/local/cargo/git \
		-w /home/rust \
		$(DOCKER_BUILDER_IMAGE_TAG) \
		make publish

copy_artifacts:
	mkdir -p $(JNI_LIBS_PATH)/arm64-v8a
	mkdir -p $(JNI_LIBS_PATH)/armeabi-v7a
	mkdir -p $(JNI_LIBS_PATH)/x86
	mkdir -p $(JNI_LIBS_PATH)/x86_64
	cp -f target/aarch64/aarch64-linux-android/$(CARGO_PROFILE)/libmobilecoin_android.so $(JNI_LIBS_PATH)/arm64-v8a/libmobilecoin.so
	cp -f target/armv7/armv7-linux-androideabi/$(CARGO_PROFILE)/libmobilecoin_android.so $(JNI_LIBS_PATH)/armeabi-v7a/libmobilecoin.so
	cp -f target/i686/i686-linux-android/$(CARGO_PROFILE)/libmobilecoin_android.so $(JNI_LIBS_PATH)/x86/libmobilecoin.so
	cp -f target/x86_64/x86_64-linux-android/$(CARGO_PROFILE)/libmobilecoin_android.so $(JNI_LIBS_PATH)/x86_64/libmobilecoin.so

strip:
	llvm-strip target/aarch64/aarch64-linux-android/$(CARGO_PROFILE)/libmobilecoin_android.so
	llvm-strip target/armv7/armv7-linux-androideabi/$(CARGO_PROFILE)/libmobilecoin_android.so
	llvm-strip target/i686/i686-linux-android/$(CARGO_PROFILE)/libmobilecoin_android.so
	llvm-strip target/x86_64/x86_64-linux-android/$(CARGO_PROFILE)/libmobilecoin_android.so

build: setup-docker
	docker run \
		--rm \
		-v $(pwd):/home/rust/ \
		-v $(BUILD_DEPS_FOLDER):/usr/local/cargo/git \
		-w /home/rust \
		$(DOCKER_BUILDER_IMAGE_TAG) \
		make libs

dist: build
	tar -czf android-bindings.tar.gz -C build .

docker_image:
	docker build \
		-t $(DOCKER_BUILDER_IMAGE_TAG) \
		docker

publish_docker_image: docker_image
	docker image push $(DOCKER_BUILDER_IMAGE_TAG)

clean:
	docker run \
		--rm \
		-v $(pwd):/home/rust/ \
		-v $(BUILD_DEPS_FOLDER):/usr/local/cargo/git \
		-w /home/rust/ \
		$(DOCKER_BUILDER_IMAGE_TAG) \
		cargo clean

bash: setup-docker
	docker run \
		--rm \
		-it \
		-v $(pwd):/home/rust/ \
		-v $(BUILD_DEPS_FOLDER):/usr/local/cargo/git \
		-w /home/rust/ \
		$(DOCKER_BUILDER_IMAGE_TAG) \
		bash

setup-docker: docker_image
	mkdir -p $(BUILD_DEPS_FOLDER)

all: setup-docker clean dist
