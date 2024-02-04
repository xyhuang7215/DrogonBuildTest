import os
from conan import ConanFile
from conan.tools.cmake import CMake

class CompressorRecipe(ConanFile):
    settings = "os", "compiler", "build_type", "arch"
    generators = "CMakeToolchain", "CMakeDeps"

    def requirements(self):
        self.requires("drogon/1.9.2")
    
    def build_requirements(self):
        # Build requirements
        self.build_requires("cmake/[>=3.23]")
        self.build_requires("ninja/1.11.1")
    
    # def build(self):
    #     cmake = CMake(self)
    #     cmake.configure()
    #     cmake.build()

    def layout(self):
        self.folders.generators = os.path.join("build", "generators")
        self.folders.build = "build"