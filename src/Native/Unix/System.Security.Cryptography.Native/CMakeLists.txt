
project(System.Security.Cryptography.Native)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

# These are happening inside of OpenSSL-defined macros out of our control
add_compile_options(-Wno-cast-align)

add_definitions(-DPIC=1)

if(CMAKE_STATIC_LIB_LINK)
   set(CMAKE_FIND_LIBRARY_SUFFIXES .a)
endif(CMAKE_STATIC_LIB_LINK)

find_package(OpenSSL REQUIRED)
include_directories(SYSTEM ${OPENSSL_INCLUDE_DIR})

set(NATIVECRYPTO_SOURCES
    openssl.cpp
    pal_asn1.cpp
    pal_asn1_print.cpp
    pal_bignum.cpp
    pal_bio.cpp
    pal_dsa.cpp
    pal_ecdsa.cpp
    pal_ecc_import_export.cpp
    pal_eckey.cpp
    pal_err.cpp
    pal_evp.cpp
    pal_evp_pkey.cpp
    pal_evp_pkey_dsa.cpp
    pal_evp_pkey_eckey.cpp
    pal_evp_pkey_rsa.cpp
    pal_evp_cipher.cpp
    pal_hmac.cpp
    pal_pkcs12.cpp
    pal_pkcs7.cpp
    pal_rsa.cpp
    pal_ssl.cpp
    pal_x509.cpp
    pal_x509_name.cpp
    pal_x509_root.cpp
    pal_x509ext.cpp
)

if (FEATURE_DISTRO_AGNOSTIC_SSL)
    if (NOT CMAKE_SYSTEM_NAME STREQUAL Linux)
        message(FATAL_ERROR "FEATURE_DISTRO_AGNOSTIC_SSL can only be enabled for Linux")
    endif()

    list(APPEND NATIVECRYPTO_SOURCES
        opensslshim.cpp
    )
    add_definitions(-DFEATURE_DISTRO_AGNOSTIC_SSL)
endif()

add_library(objlib OBJECT ${NATIVECRYPTO_SOURCES} ${VERSION_FILE_PATH})

add_library(System.Security.Cryptography.Native.OpenSsl
    SHARED
    $<TARGET_OBJECTS:objlib>
)

add_library(System.Security.Cryptography.Native.OpenSsl-Static
    STATIC
    $<TARGET_OBJECTS:objlib>
)

# Disable the "lib" prefix.
set_target_properties(System.Security.Cryptography.Native.OpenSsl PROPERTIES PREFIX "")

# Disable the "lib" prefix and override default name
set_target_properties(System.Security.Cryptography.Native.OpenSsl-Static PROPERTIES PREFIX "")
set_target_properties(System.Security.Cryptography.Native.OpenSsl-Static PROPERTIES OUTPUT_NAME System.Security.Cryptography.Native.OpenSsl CLEAN_DIRECT_OUTPUT 1)

if (FEATURE_DISTRO_AGNOSTIC_SSL)
    add_custom_command(TARGET System.Security.Cryptography.Native.OpenSsl POST_BUILD
        COMMENT "Verifying System.Security.Cryptography.Native.OpenSsl.so dependencies"
        COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/../verify-so.sh 
            $<TARGET_FILE:System.Security.Cryptography.Native.OpenSsl> 
            "Verification failed. System.Security.Cryptography.Native.OpenSsl.so has undefined dependencies. These are likely OpenSSL APIs that need to be added to opensslshim.h"
        VERBATIM
    )

    # Link with libdl.so to get the dlopen / dlsym / dlclose
    target_link_libraries(System.Security.Cryptography.Native.OpenSsl
      dl
    )
else()
    target_link_libraries(System.Security.Cryptography.Native.OpenSsl
      ${OPENSSL_CRYPTO_LIBRARY}
      ${OPENSSL_SSL_LIBRARY}
    )
  
    # On OS X every library emits the manner in which it should be referenced.
    # All of our libraries are referenced via @rpath, which is similar to how Linux and Windows
    # libraries are loaded. The homebrew installation of OpenSSL (libcrypto, libssl) uses the
    # full path to the library installation. This means that this library is not flexible to
    # users installing newer libcrypto in the working directory, or to systems which do not
    # install to the same path as homebrew does.
    #
    # So, after compiling, rewrite the references to libcrypto to be more flexible.
    if (APPLE)
        add_custom_command(TARGET System.Security.Cryptography.Native.OpenSsl POST_BUILD
            COMMAND ${CMAKE_INSTALL_NAME_TOOL} -change /usr/local/opt/openssl/lib/libcrypto.1.0.0.dylib @rpath/libcrypto.1.0.0.dylib $<TARGET_FILE:System.Security.Cryptography.Native.OpenSsl>
            COMMAND ${CMAKE_INSTALL_NAME_TOOL} -change /usr/local/opt/openssl/lib/libssl.1.0.0.dylib @rpath/libssl.1.0.0.dylib $<TARGET_FILE:System.Security.Cryptography.Native.OpenSsl>
            COMMAND ${CMAKE_INSTALL_NAME_TOOL} -add_rpath @loader_path $<TARGET_FILE:System.Security.Cryptography.Native.OpenSsl>
            )
    endif()
endif()

include(configure.cmake)

install_library_and_symbols (System.Security.Cryptography.Native.OpenSsl)
install (TARGETS System.Security.Cryptography.Native.OpenSsl-Static DESTINATION .)
