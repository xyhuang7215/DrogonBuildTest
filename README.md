This is just a repository for building tests for the Drogon framework.

```
conan install . --build=missing -s compiler.cppstd=17 -s build_type=Debug -c tools.cmake.cmaketoolchain:generator="Ninja Multi-Config"
cmd.exe /c ".\build\generators\conanbuild.bat && cmake --preset conan-default  . && cmake --build ./build --config Debug" 
```