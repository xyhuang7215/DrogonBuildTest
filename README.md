This is just a repository for building tests for the Drogon framework.

```
mkdir build
cd build
conan install .. --build=missing -s compiler.cppstd=17 -s:build_type=Release
cmake  --preset conan-default ..
cmake --build . --config=Release
```