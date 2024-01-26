# ##############################################################################
# function drogon_create_views(target source_path output_path
# [TRUE to use_path_as_namespace] [prefixed namespace])
# ##############################################################################
function(drogon_create_views arg)
  if(ARGC LESS 3)
    message(STATUS "arguments error when calling drogon_create_views")
    return()
  endif()
  file(MAKE_DIRECTORY ${ARGV2})
  file(GLOB_RECURSE SCP_LIST ${ARGV1}/*.csp)
  foreach(cspFile ${SCP_LIST})
    file(RELATIVE_PATH
         inFile
         ${CMAKE_CURRENT_SOURCE_DIR}
         ${cspFile})
    if(ARGC GREATER 3 AND ARGV3)
      string(REPLACE "/"
                     "_"
                     f1
                     ${inFile})
      string(REPLACE "\\"
                     "_"
                     f2
                     ${f1})
      string(REPLACE ".csp"
                     ""
                     outputFile
                     ${f2})
      set(p2ns "")
      if("${ARGV3}" STREQUAL "TRUE")
        set(p2ns "--path-to-namespace")
      endif()
      if ( (ARGC EQUAL 5) AND ( NOT "${ARGV4}" STREQUAL "") )
        string(REPLACE "::" "_" nSpace ${ARGV4})
        set(outputFile "${nSpace}_${outputFile}")
        set(ns -n ${ARGV4})
      else()
        set(ns "")
      endif()
      add_custom_command(OUTPUT ${ARGV2}/${outputFile}.h ${ARGV2}/${outputFile}.cc
                         COMMAND drogon_ctl
                                 ARGS
                                 create
                                 view
                                 ${inFile}
                                 ${p2ns}
                                 -o
                                 ${ARGV2}
                                 ${ns}
                         DEPENDS ${cspFile}
                         WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                         VERBATIM)
      set(VIEWSRC ${VIEWSRC} ${ARGV2}/${outputFile}.cc)
    else()
      get_filename_component(classname ${cspFile} NAME_WE)
      add_custom_command(OUTPUT ${ARGV2}/${classname}.h ${ARGV2}/${classname}.cc
                         COMMAND drogon_ctl
                                 ARGS
                                 create
                                 view
                                 ${inFile}
                                 -o
                                 ${ARGV2}
                         DEPENDS ${cspFile}
                         WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                         VERBATIM)
      set(VIEWSRC ${VIEWSRC} ${ARGV2}/${classname}.cc)
    endif()
  endforeach()
  target_sources(${ARGV0} PRIVATE ${VIEWSRC})
endfunction(drogon_create_views)


#==================================================================================================#
# Adapted and re-written from Catch2 to work with Drogon Test                                      #
#                                                                                                  #
#  Usage                                                                                           #
# 1. make sure this module is in the path or add this otherwise:                                   #
#    set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake_modules/")              #
# 2. make sure that you've enabled testing option for the project by the call:                     #
#    enable_testing()                                                                              #
# 3. add the lines to the script for testing target (sample CMakeLists.txt):                       #
#        project(testing_target)                                                                   #
#        enable_testing()                                                                          #
#                                                                                                  #
#        file(GLOB SOURCE_FILES "*.cpp")                                                           #
#        add_executable(${PROJECT_NAME} ${SOURCE_FILES})                                           #
#                                                                                                  #
#        include(ParseAndAddDrogonTests)                                                          #
#        ParseAndAddDrogonTests(${PROJECT_NAME})                                                   #
#==================================================================================================#

cmake_minimum_required(VERSION 3.5)

# This removes the contents between
#  - block comments (i.e. /* ... */) 
#  - full line comments (i.e. // ... ) 
# contents have been read into '${CppCode}'.
# !keep partial line comments
function(RemoveComments CppCode)
  string(ASCII 2 CMakeBeginBlockComment)
  string(ASCII 3 CMakeEndBlockComment)
  string(REGEX REPLACE "/\\*" "${CMakeBeginBlockComment}" ${CppCode} "${${CppCode}}")
  string(REGEX REPLACE "\\*/" "${CMakeEndBlockComment}" ${CppCode} "${${CppCode}}")
  string(REGEX REPLACE "${CMakeBeginBlockComment}[^${CMakeEndBlockComment}]*${CMakeEndBlockComment}" "" ${CppCode} "${${CppCode}}")
  string(REGEX REPLACE "\n[ \t]*//+[^\n]+" "\n" ${CppCode} "${${CppCode}}")

  set(${CppCode} "${${CppCode}}" PARENT_SCOPE)
endfunction()

# Worker function
function(ParseFile SourceFile TestTarget)
	set(FullSourcePath ${CMAKE_CURRENT_SOURCE_DIR}/${SourceFile})
    if(NOT EXISTS ${FullSourcePath})
        return()
    endif()
    file(STRINGS ${FullSourcePath} Contents NEWLINE_CONSUME)

    # Remove block and fullline comments
    RemoveComments(Contents)

    # Find definition of test names
    string(REGEX MATCHALL "[ \t]*DROGON_TEST[ \t]*\\\([a-zA-Z0-9_]+\\\)" Tests "${Contents}")

    foreach(TestLine ${Tests})
        # Strip newlines
        string(REGEX REPLACE "\\\\\n|\n" "" TestLine "${TestLine}")

        # Get the name of the test
		string(REGEX REPLACE "[ \t]*DROGON_TEST[ \t]*" "" TestLine "${TestLine}")
        string(REGEX MATCHALL "[a-zA-Z0-9_]+" TestName "${TestLine}")

        # Validate that a test name and tags have been provided
        list(LENGTH TestName TestNameLength)
        if(NOT TestNameLength EQUAL 1)
            message(FATAL_ERROR "${TestName} in ${SourceFile} is not a valid test name."
				" Either a bug in the Drogon Test CMake parser or a bug in the test itself")
        endif()

        # Add the test and set its properties
        add_test(NAME "${TestName}" COMMAND ${TestTarget} -r ${TestName} ${AdditionalCatchParameters})

    endforeach()
endfunction()

# entry point
function(ParseAndAddDrogonTests TestTarget)
    get_target_property(SourceFiles ${TestTarget} SOURCES)
    foreach(SourceFile ${SourceFiles})
        ParseFile(${SourceFile} ${TestTarget})
    endforeach()
endfunction()