cmake_minimum_required(VERSION 3.18)
project(rife_plugin)

set(CMAKE_CXX_STANDARD 17)

# ncnn library — download from https://github.com/Tencent/ncnn/releases
# Extract ncnn-YYYYMMDD-android-vulkan.zip contents into android/app/src/main/cpp/ncnn/
# Expected structure: ncnn/{arm64-v8a,armeabi-v7a}/{lib/libncnn.a, include/ncnn/...}
set(NCNN_DIR ${CMAKE_SOURCE_DIR}/ncnn/${ANDROID_ABI})

if(EXISTS ${NCNN_DIR}/lib/libncnn.a)
    message(STATUS "ncnn found at ${NCNN_DIR}")

    add_library(ncnn STATIC IMPORTED)
    set_target_properties(ncnn PROPERTIES
        IMPORTED_LOCATION ${NCNN_DIR}/lib/libncnn.a
    )

    add_library(rife_plugin SHARED
        rife_interpolator.cpp
        jni_bridge.cpp
    )

    target_include_directories(rife_plugin PRIVATE
        ${NCNN_DIR}/include/ncnn
        ${NCNN_DIR}/include
    )

    find_library(VULKAN_LIB vulkan)
    find_library(LOG_LIB log)
    find_library(ANDROID_LIB android)
    find_library(JNIGRAPHICS_LIB jnigraphics)

    target_link_libraries(rife_plugin
        ncnn
        ${VULKAN_LIB}
        ${LOG_LIB}
        ${ANDROID_LIB}
        ${JNIGRAPHICS_LIB}
    )
else()
    message(WARNING "ncnn not found at ${NCNN_DIR} — RIFE native plugin will not be built.")
    message(WARNING "To enable: run ./scripts/setup_rife.sh from project root")
endif()
