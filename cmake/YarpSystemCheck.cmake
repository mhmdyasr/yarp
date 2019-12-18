# Copyright (C) 2006-2019 Istituto Italiano di Tecnologia (IIT)
# Copyright (C) 2006-2010 RobotCub Consortium
# All rights reserved.
#
# This software may be modified and distributed under the terms of the
# BSD-3-Clause license. See the accompanying LICENSE file for details.


#########################################################################
# Include required CMake modules

include(TestBigEndian)
include(CheckCXXCompilerFlag)
include(CheckIncludeFiles)
include(CheckIncludeFileCXX)
include(CheckTypeSize)

# Ensure that install directories are set
include(GNUInstallDirs)


#########################################################################
# C++14 is required
# These variables are used by try_compile, so they must be set here

set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)


#########################################################################
# Check whether system is big- or little- endian

unset(YARP_BIG_ENDIAN)
unset(YARP_LITTLE_ENDIAN)

test_big_endian(IS_BIG_ENDIAN)
if(${IS_BIG_ENDIAN})
  set(YARP_BIG_ENDIAN 1)
else()
  set(YARP_LITTLE_ENDIAN 1)
endif()


#########################################################################
# Check size of pointers

check_type_size("void *" YARP_POINTER_SIZE)


#########################################################################
# Find 32, 64 and optionally 128-bit floating point types and check whether
# floating point types are IEC559

unset(YARP_FLOAT32)
unset(YARP_FLOAT64)
unset(YARP_FLOAT128)

set(YARP_FLOAT32_IS_IEC559 0)
set(YARP_FLOAT64_IS_IEC559 0)
set(YARP_FLOAT128_IS_IEC559 0)

set(YARP_HAS_FLOAT128_T 0)


macro(CHECK_FLOATING_POINT_IS_IEC559 _type)
  string(REPLACE " " "_" _type_s "${_type}")
  file(WRITE "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${_type_s}-is_iec559.cpp"
"#include <limits>
int main() {
  return std::numeric_limits<${_type}>::is_iec559 ? 1 : 0;
}
")

  try_run(YARP_${_type_s}_IS_IEC559
          _unused
          "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}"
          "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${_type_s}-is_iec559.cpp")
endmacro()

check_floating_point_is_iec559("float")
check_floating_point_is_iec559("double")
check_floating_point_is_iec559("long double")



check_type_size("float" SIZEOF_FLOAT)
check_type_size("double" SIZEOF_DOUBLE)
check_type_size("long double" SIZEOF_LONG_DOUBLE)

if(YARP_float_IS_IEC559)
  set(YARP_FLOAT32 "float")
  set(YARP_FLOAT32_IS_IEC559 1)
elseif(SIZEOF_FLOAT EQUAL 4)
  set(YARP_FLOAT32 "float")
elseif(SIZEOF_DOUBLE EQUAL 4)
  set(YARP_FLOAT32 "double")
elseif(SIZEOF_LONG_DOUBLE EQUAL 4)
  set(YARP_FLOAT32 "long double")
endif()
if(NOT YARP_FLOAT32)
  message(FATAL_ERROR "Cannot find a 32-bit floating point type")
endif()

if(YARP_double_IS_IEC559)
  set(YARP_FLOAT64 "double")
  set(YARP_FLOAT64_IS_IEC559 1)
elseif(SIZEOF_DOUBLE EQUAL 8)
  set(YARP_FLOAT64 "double")
elseif(SIZEOF_LONG_DOUBLE EQUAL 8)
  set(YARP_FLOAT64 "long double")
elseif(SIZEOF_FLOAT EQUAL 8)
  set(YARP_FLOAT64 "float")
endif()
if(NOT YARP_FLOAT64)
  message(FATAL_ERROR "Cannot find a 64-bit floating point type")
endif()

if(YARP_long_double_IS_IEC559)
  set(YARP_FLOAT128 "long double")
  set(YARP_FLOAT128_IS_IEC559 1)
elseif(SIZEOF_LONG_DOUBLE EQUAL 16)
  set(YARP_FLOAT128 "long double")
elseif(SIZEOF_DOUBLE EQUAL 16)
  set(YARP_FLOAT128 "double")
elseif(SIZEOF_FLOAT EQUAL 16)
  set(YARP_FLOAT128 "float")
endif()
if(YARP_FLOAT128)
  set(YARP_HAS_FLOAT128_T 1)
endif()


#########################################################################
# Check the maximum number of digits for the exponent for floating point types

macro(CHECK_FLOATING_POINT_EXPONENT_DIGITS _type)
  file(WRITE "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${_type}-exp-dig.cpp"
"#include <algorithm>
#include <cfloat>
#include <cmath>
int main()
{
    return std::max (
        static_cast<int>(std::floor(std::log10(${_type}_MAX_EXP))) + 1,
        static_cast<int>(std::floor(std::log10(${_type}_MIN_EXP))) + 1);
}
")
  try_run(YARP_${_type}_EXP_DIG
          _unused
          "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}"
          "${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${_type}-exp-dig.cpp")
endmacro()

check_floating_point_exponent_digits(FLT)
check_floating_point_exponent_digits(DBL)
check_floating_point_exponent_digits(LDBL)

#########################################################################
# Set up compile flags

add_definitions(-DBUILDING_YARP)

# on windows, we have to tell ace how it was compiled
if(WIN32)
  ## check if we are using the CYGWIN compiler
  if(NOT CYGWIN)
    add_definitions(-DWIN32 -D_WINDOWS)
  else()
    add_definitions(-DCYGWIN)
  endif()

  ## check if we are using the MINGW compiler
  if(MINGW)
    add_definitions("-mms-bitfields" "-mthreads" "-pipe")
  endif()

  ## check if we are using the MSVC compiler
  if(MSVC)
    # ACE uses a bunch of functions MSVC warns about.
    # The warnings make sense in general, but not in this case.
    # this gets rids of deprecated unsafe crt functions
    add_definitions(-D_CRT_SECURE_NO_DEPRECATE)
    # this gets rid of warning about deprecated POSIX names
    add_definitions(-D_CRT_NONSTDC_NO_DEPRECATE)
    # disable deprecated warnings generated by ACE
    add_definitions(-D_WINSOCK_DEPRECATED_NO_WARNINGS)
    add_definitions(-D_WINSOCK_DEPRECATED_NO_WARNINGS)

    # Check whether colored output is available on Windows console.
    set(YARP_HAS_WIN_VT_SUPPORT 0)
    if(NOT CMAKE_SYSTEM_VERSION VERSION_LESS 10.0.10586)
      set(YARP_HAS_WIN_VT_SUPPORT 1)
    endif()

    # Traditionally, we add "d" postfix to debug libraries
    set(CMAKE_DEBUG_POSTFIX "d")
  endif()
else()

    macro(YARP_CHECK_AND_APPEND_CXX_COMPILER_FLAG _out _flag)
      string(TOUPPER "${_flag}" _VAR)
      string(REGEX REPLACE " .+" "" _VAR "${_VAR}")
      string(REGEX REPLACE "[^A-Za-z0-9]" "_" _VAR "${_VAR}")
      set(_VAR CXX_HAS${_VAR})
      check_cxx_compiler_flag("${_flag}" ${_VAR})
      if(${_VAR})
        set(${_out} "${${_out}} ${_flag}")
      endif()
      unset(_VAR)
    endmacro()

    ## Wanted warnings flags ##
    unset(WANTED_WARNING_FLAGS)
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wall")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wextra")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wsign-compare")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wpointer-arith")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Winit-self")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wnon-virtual-dtor")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wcast-align")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wunused")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wunused-but-set-variable")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wvla")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wmissing-include-dirs")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wlogical-op")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wreorder")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wsizeof-pointer-memaccess")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Woverloaded-virtual")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wtautological-undefined-compare")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wmismatched-new-delete")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wparentheses-equality")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wundef")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wredundant-decls")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wunknown-pragmas")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wunused-result")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wc++11-compat")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wc++14-compat")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wc++17-compat")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wheader-guard")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wignored-attributes")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wnewline-eof")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wdangling-else")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wgcc-compat")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wmicrosoft-exists")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wstatic-inline-explicit-instantiation")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wmisleading-indentation")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wtautological-compare")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Winconsistent-missing-override")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wsuggest-override")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wmaybe-uninitialized")
    yarp_check_and_append_cxx_compiler_flag(WANTED_WARNING_FLAGS "-Wnull-conversion")

    ## Unwanted warning flags ##
    unset(UNWANTED_WARNING_FLAGS)
    yarp_check_and_append_cxx_compiler_flag(UNWANTED_WARNING_FLAGS "-Wno-unused-parameter") # FIXME Enable later


    ## Experimental warning flags ##
    # FIXME Those warnings should be enabled later
    unset(EXPERIMENTAL_WARNING_FLAGS)
    yarp_check_and_append_cxx_compiler_flag(EXPERIMENTAL_WARNING_FLAGS "-Wconversion")
    yarp_check_and_append_cxx_compiler_flag(EXPERIMENTAL_WARNING_FLAGS "-Wcast-qual")
    yarp_check_and_append_cxx_compiler_flag(EXPERIMENTAL_WARNING_FLAGS "-Wsign-conversion")
    yarp_check_and_append_cxx_compiler_flag(EXPERIMENTAL_WARNING_FLAGS "-Wold-style-cast")
    yarp_check_and_append_cxx_compiler_flag(EXPERIMENTAL_WARNING_FLAGS "-Winline")
    yarp_check_and_append_cxx_compiler_flag(EXPERIMENTAL_WARNING_FLAGS "-Wfloat-equal")


    ## Visibility hidden flags ##
    unset(VISIBILITY_HIDDEN_FLAGS)
    yarp_check_and_append_cxx_compiler_flag(VISIBILITY_HIDDEN_FLAGS "-fvisibility=hidden")
    yarp_check_and_append_cxx_compiler_flag(VISIBILITY_HIDDEN_FLAGS "-fvisibility-inlines-hidden")


    ## Deprcated declarations flags ##
    unset(DEPRECATED_DECLARATIONS_FLAGS)
    yarp_check_and_append_cxx_compiler_flag(DEPRECATED_DECLARATIONS_FLAGS "-Wdeprecated-declarations")


    ## Hardening flags ##
    unset(HARDENING_FLAGS)
    check_cxx_compiler_flag("-Wformat" CXX_HAS_WFORMAT)
    if(CXX_HAS_WFORMAT)
      check_cxx_compiler_flag("-Wformat=2" CXX_HAS_WFORMAT_2)
      if(CXX_HAS_WFORMAT_2)
        set(HARDENING_FLAGS "-Wformat=2")
      else()
        set(HARDENING_FLAGS "-Wformat")
      endif()
      yarp_check_and_append_cxx_compiler_flag(HARDENING_FLAGS "-Wformat-security")
      yarp_check_and_append_cxx_compiler_flag(HARDENING_FLAGS "-Wformat-y2k")
      yarp_check_and_append_cxx_compiler_flag(HARDENING_FLAGS "-Wformat-nonliteral")
    endif()
    yarp_check_and_append_cxx_compiler_flag(HARDENING_FLAGS "-fstack-protector --param=ssp-buffer-size=4")
    yarp_check_and_append_cxx_compiler_flag(HARDENING_FLAGS "-Wl,-zrelro")
    yarp_check_and_append_cxx_compiler_flag(HARDENING_FLAGS "-Wl,-znow")
    yarp_check_and_append_cxx_compiler_flag(HARDENING_FLAGS "-fPIE -pie")


    ## C++11 flags ##
    unset(CXX11_FLAGS)
    check_cxx_compiler_flag("-std=c++11" CXX_HAS_STD_CXX11)
    check_cxx_compiler_flag("-std=c++0x" CXX_HAS_STD_CXX0X)
    if(CXX_HAS_STD_CXX11)
      set(CXX11_FLAGS "-std=c++11")
    elseif(CXX_HAS_STD_CXX0X)
      set(CXX11_FLAGS "-std=c++0x")
    endif()

    ## C++14 flags ##
    unset(CXX14_FLAGS)
    check_cxx_compiler_flag("-std=c++14" CXX_HAS_STD_CXX14)
    check_cxx_compiler_flag("-std=c++1y" CXX_HAS_STD_CXX1Y)
    if(CXX_HAS_STD_CXX14)
      set(CXX14_FLAGS "-std=c++14")
    elseif(CXX_HAS_STD_CXX1Y)
      set(CXX14_FLAGS "-std=c++1y")
    endif()

    ## C++17 flags ##
    unset(CXX14_FLAGS)
    check_cxx_compiler_flag("-std=c++17" CXX_HAS_STD_CXX17)
    check_cxx_compiler_flag("-std=c++1z" CXX_HAS_STD_CXX1Z)
    if(CXX_HAS_STD_CXX17)
      set(CXX17_FLAGS "-std=c++17")
    elseif(CXX_HAS_STD_CXX1Z)
      set(CXX17_FLAGS "-std=c++1z")
    endif()


    ## Error and warning flags ##
    check_cxx_compiler_flag("-Werror" CXX_HAS_WERROR)
    check_cxx_compiler_flag("-Wfatal-errors" CXX_HAS_WFATAL_ERROR)
endif()


#########################################################################
# Try to locate some system headers

check_include_files(execinfo.h YARP_HAS_EXECINFO_H)
check_include_files(sys/wait.h YARP_HAS_SYS_WAIT_H)
check_include_files(sys/types.h YARP_HAS_SYS_TYPES_H)
check_include_files(sys/prctl.h YARP_HAS_SYS_PRCTL_H)
# Even if <csignal> is c++11, on some platforms it it still missing
check_include_files(csignal YARP_HAS_CSIGNAL)
check_include_files(signal.h YARP_HAS_SIGNAL_H)
check_include_files(sys/signal.h YARP_HAS_SYS_SIGNAL_H)
check_include_files(netdb.h YARP_HAS_NETDB_H)
check_include_files(dlfcn.h YARP_HAS_DLFCN_H)
check_include_files(ifaddrs.h YARP_HAS_IFADDRS_H)
