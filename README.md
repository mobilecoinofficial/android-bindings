![](./img/mobilecoin_logo.png)

# android-bindings
Library with a JNI interface to the shared rust code of MobileCoin.

## License
android-bindings is available under open-source licenses. Look for the *LICENSE* file in each crate for more information.

## Cryptography Notice
This distribution includes cryptographic software. Your country may have restrictions on the use of encryption software. Please check your country's laws before downloading or using this software.

## Repository Structure
|Directory |Description |
| :-- | :-- |
| [docker](./docker) | Dockerfile for the builder image. |
| [lib-wrapper](./lib-wrapper) | An Android library project to embedd the native libraries. |
| [mobilecoin](./mobilecoin) | MobileCoin submodule. |
| [src](./src) | JNI bridge between Java and Rust. |


## Build Instructions

* Using Docker
```
make build
```
* Host machine
```
make libs
```
