# declaration of function

set(VPVL2_BASE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/..")
function(get_source_directory output dir)
  set(${output} "${VPVL2_BASE_DIR}/${dir}" PARENT_SCOPE)
endfunction()

function(get_build_directory output source_dir)
  string(TOLOWER ${CMAKE_BUILD_TYPE} CMAKE_BUILD_TYPE_TOLOWER)
  set(BUILD_DIRECTORY "build-${CMAKE_BUILD_TYPE_TOLOWER}")
  set(${output} "${${source_dir}}/${BUILD_DIRECTORY}" PARENT_SCOPE)
endfunction()

function(get_local_library_directory_named output source_dir lib_dir)
  string(TOLOWER ${CMAKE_BUILD_TYPE} CMAKE_BUILD_TYPE_TOLOWER)
  get_build_directory(build_dir ${source_dir})
  if(MSVC)
    set(${output} "${build_dir}/${lib_dir}/${CMAKE_BUILD_TYPE_TOLOWER}" PARENT_SCOPE)
  else()
    set(${output} "${build_dir}/${lib_dir}" PARENT_SCOPE)
  endif()
endfunction()

function(get_local_library_directory output source_dir)
  get_local_library_directory_named(output_to_reassign ${source_dir} "lib")
  set(${output} ${output_to_reassign} PARENT_SCOPE)
endfunction()

function(get_install_directory output dir)
  get_source_directory(source_dir ${dir})
  string(TOLOWER ${CMAKE_BUILD_TYPE} CMAKE_BUILD_TYPE_TOLOWER)
  set(build_dir "build-${CMAKE_BUILD_TYPE_TOLOWER}")
  set(${output} "${source_dir}/${build_dir}/install-root" PARENT_SCOPE)
endfunction()

function(vpvl2_set_library_properties target public_headers)
  # create as a framework if build on darwin environment
  if(WIN32 AND BUILD_SHARED_LIBS)
    set_target_properties(${target} PROPERTIES PREFIX "" SUFFIX .dll IMPORT_SUFFIX ${CMAKE_IMPORT_LIBRARY_SUFFIX})
  elseif(APPLE)
    if(BUILD_SHARED_LIBS AND FRAMEWORK)
      install(TARGETS vpvl2 DESTINATION .)
      set_target_properties(${target} PROPERTIES FRAMEWORK true PROPERTIES PUBLIC_HEADER "${public_headers}")
    endif()
    set_target_properties(vpvl2 PROPERTIES INSTALL_NAME_DIR "${CMAKE_INSTALL_PREFIX}/lib")
  endif()
endfunction()

function(vpvl2_set_warnings)
  if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" OR "${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang" OR CMAKE_COMPILER_IS_GNUC)
  # set more warnings when clang or gcc is selected
    add_definitions(-W -Wall -Wextra -Wformat=2 -Wstrict-aliasing=2 -Wwrite-strings)
  elseif(MSVC)
    # disable some specified warnings on MSVC
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} /EHsc /wd4068 /wd4819" CACHE STRING "disable warnings of C4068 (for clang pragma) and C4819" FORCE)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /EHsc /wd4068 /wd4355 /wd4819" CACHE STRING "disable warnings of C4068 (for clang pragma), C4355 (for glog) and C4819" FORCE)
    # disable _CRT_SECURE_NO_WARNINGS for surpressing warnings from vpvl2/Common.h
    add_definitions(-D_CRT_SECURE_NO_WARNINGS -D_CRT_SECURE_NO_DEPRECATE -D_SCL_SECURE_NO_WARNINGS)
  endif()
endfunction()

function(vpvl2_link_bullet target)
  target_link_libraries(${target} ${BULLET_DYNAMICS_LIB}
                                  ${BULLET_COLLISION_LIB}
                                  ${BULLET_SOFTBODY_LIB}
                                  ${BULLET_MULTITHREADED_LIB}
                                  ${BULLET_LINEARMATH_LIB})
endfunction()

function(vpvl2_find_bullet)
  get_install_directory(BULLET_INSTALL_DIR "bullet-src")
  find_path(BULLET_INCLUDE_DIR NAMES btBulletCollisionCommon.h PATH_SUFFIXES include/bullet PATHS ${BULLET_INSTALL_DIR} NO_DEFAULT_PATH)
  find_library(BULLET_LINEARMATH_LIB LinearMath PATH_SUFFIXES lib64 lib32 lib PATHS ${BULLET_INSTALL_DIR} NO_DEFAULT_PATH)
  find_library(BULLET_COLLISION_LIB BulletCollision PATH_SUFFIXES lib64 lib32 lib PATHS ${BULLET_INSTALL_DIR} NO_DEFAULT_PATH)
  find_library(BULLET_DYNAMICS_LIB BulletDynamics PATH_SUFFIXES lib64 lib32 lib PATHS ${BULLET_INSTALL_DIR} NO_DEFAULT_PATH)
  find_library(BULLET_MULTITHREADED_LIB BulletMultiThreaded PATH_SUFFIXES lib64 lib32 lib PATHS ${BULLET_INSTALL_DIR} NO_DEFAULT_PATH)
  find_library(BULLET_SOFTBODY_LIB BulletSoftBody PATH_SUFFIXES lib64 lib32 lib PATHS ${BULLET_INSTALL_DIR} NO_DEFAULT_PATH)
  include_directories(${BULLET_INCLUDE_DIR})
endfunction()

function(vpvl2_link_assimp target)
  if(VPVL2_LINK_ASSIMP3 OR VPVL2_LINK_ASSIMP)
    target_link_libraries(${target} ${ASSIMP_LIBRARY})
  endif()
endfunction()

function(vpvl2_find_assimp)
  if(VPVL2_LINK_ASSIMP3 OR VPVL2_LINK_ASSIMP)
    get_install_directory(ASSIMP_INSTALL_DIR "assimp-src")
    if(VPVL2_LINK_ASSIMP3)
      find_path(ASSIMP_INCLUDE_DIR NAMES assimp/Importer.hpp PATH_SUFFIXES include PATHS ${ASSIMP_INSTALL_DIR} NO_DEFAULT_PATH)
      find_library(ASSIMP_LIBRARY assimp assimpD PATH_SUFFIXES lib64 lib32 lib PATHS ${ASSIMP_INSTALL_DIR} NO_DEFAULT_PATH)
    elseif(VPVL2_LINK_ASSIMP)
      find_path(ASSIMP_INCLUDE_DIR NAMES assimp/assimp.h PATH_SUFFIXES include PATHS ${ASSIMP_INSTALL_DIR} NO_DEFAULT_PATH)
      find_library(ASSIMP_LIBRARY assimp PATH_SUFFIXES lib64 lib32 lib PATHS ${ASSIMP_INSTALL_DIR} NO_DEFAULT_PATH)
    endif()
    include_directories(${ASSIMP_INCLUDE_DIR})
  endif()
endfunction()

function(vpvl2_link_vpvl target)
  if(VPVL2_LINK_VPVL)
    target_link_libraries(${target} ${VPVL_LIBRARY})
  endif()
endfunction()

function(vpvl2_find_vpvl)
  if(VPVL2_LINK_VPVL)
    get_install_directory(VPVL_INSTALL_DIR "libvpvl")
    find_path(VPVL_INCLUDE_DIR NAMES vpvl/vpvl.h PATH_SUFFIXES include PATHS ${VPVL_INSTALL_DIR} NO_DEFAULT_PATH)
    find_library(VPVL_LIBRARY vpvl PATH_SUFFIXES lib64 lib32 lib PATHS ${VPVL_INSTALL_DIR} NO_DEFAULT_PATH)
    include_directories(${VPVL_INCLUDE_DIR} ${VPVL_CONFIG_DIR})
  endif()
endfunction()

function(vpvl2_find_sfml)
  if(VPVL2_ENABLE_EXTENSIONS_APPLICATIONCONTEXT AND VPVL2_LINK_SFML)
    find_library(SFML_GRAPHICS_LIBRARY sfml-graphics)
    find_library(SFML_SYSTEM_LIBRARY sfml-system)
    find_library(SFML_WINDOW_LIBRARY sfml-window)
    find_path(SFML_INCLUDE_DIR SFML/System.h)
    include_directories(${SFML_INCLUDE_DIR})
  endif()
endfunction()

function(vpvl2_find_openmp)
  if(VPVL2_ENABLE_OPENMP)
    find_package(OpenMP)
    if(OPENMP_FOUND)
      set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${OpenMP_C_FLAGS}")
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${OpenMP_CXX_FLAGS}")
    endif()
  endif()
endfunction()

function(vpvl2_link_icu target)
  if(ICU_LIBRARY_I18N AND ICU_LIBRARY_UC)
    target_link_libraries(${target} ${ICU_LIBRARY_I18N} ${ICU_LIBRARY_UC})
  endif()
endfunction()

function(vpvl2_find_icu)
  if(VPVL2_ENABLE_EXTENSIONS_STRING)
    if(MSVC)
      get_source_directory(ICU_INSTALL_DIR "icu4c-src")
    else()
      get_install_directory(ICU_INSTALL_DIR "icu4c-src")
    endif()
    find_path(ICU_INCLUDE_DIR unicode/unistr.h PATH_SUFFIXES include PATHS ${ICU_INSTALL_DIR} NO_DEFAULT_PATH)
    find_library(ICU_LIBRARY_I18N icui18n icuin PATH_SUFFIXES lib64 lib32 lib PATHS ${ICU_INSTALL_DIR} NO_DEFAULT_PATH)
    find_library(ICU_LIBRARY_UC icuuc PATH_SUFFIXES lib64 lib32 lib PATHS ${ICU_INSTALL_DIR} NO_DEFAULT_PATH)
    include_directories(${ICU_INCLUDE_DIR})
  endif()
endfunction()

function(vpvl2_link_tbb target)
  if(TBB_LIBRARY)
    target_link_libraries(${target} ${TBB_LIBRARY} ${TBB_PROXY_LIBRARY} ${TBB_MALLOC_LIBRARY} ${TBB_MALLOC_PROXY_LIBRARY})
  endif()
endfunction()

function(vpvl2_find_tbb)
  if(VPVL2_LINK_INTEL_TBB)
    get_source_directory(TBB_SOURCE_DIRECTORY "tbb-src")
    if(WIN32 AND CMAKE_BUILD_TYPE STREQUAL "Debug")
      find_library(TBB_LIBRARY tbb_debug PATH_SUFFIXES lib PATHS ${TBB_SOURCE_DIRECTORY} NO_DEFAULT_PATH)
      find_library(TBB_PROXY_LIBRARY tbbproxy_debug PATH_SUFFIXES lib PATHS ${TBB_SOURCE_DIRECTORY} NO_DEFAULT_PATH)
      find_library(TBB_MALLOC_LIBRARY tbbmalloc_debug PATH_SUFFIXES lib PATHS ${TBB_SOURCE_DIRECTORY} NO_DEFAULT_PATH)
      find_library(TBB_MALLOC_PROXY_LIBRARY tbbmalloc_proxy_debug PATH_SUFFIXES lib PATHS ${TBB_SOURCE_DIRECTORY} NO_DEFAULT_PATH)
    else()
      find_library(TBB_LIBRARY tbb PATH_SUFFIXES lib PATHS ${TBB_SOURCE_DIRECTORY} NO_DEFAULT_PATH)
      find_library(TBB_MALLOC_LIBRARY tbbmalloc PATH_SUFFIXES lib PATHS ${TBB_SOURCE_DIRECTORY} NO_DEFAULT_PATH)
      if(WIN32)
        find_library(TBB_PROXY_LIBRARY tbbproxy PATH_SUFFIXES lib PATHS ${TBB_SOURCE_DIRECTORY} NO_DEFAULT_PATH)
        find_library(TBB_MALLOC_PROXY_LIBRARY tbbmalloc_proxy PATH_SUFFIXES lib PATHS ${TBB_SOURCE_DIRECTORY} NO_DEFAULT_PATH)
      endif()
    endif()
    find_path(TBB_INCLUDE_DIR tbb/tbb.h PATH_SUFFIXES include PATHS ${TBB_SOURCE_DIRECTORY} NO_DEFAULT_PATH)
    include_directories(${TBB_INCLUDE_DIR})
  endif()
endfunction()

function(vpvl2_link_zlib target)
  if(ZLIB_LIBRARY)
    target_link_libraries(${target} ${ZLIB_LIBRARY})
  endif()
endfunction()

function(vpvl2_find_zlib)
  if(NOT APPLE)
    get_install_directory(ZLIB_INSTALL_DIR "zlib-src")
    find_path(ZLIB_INCLUDE_DIR zlib.h PATH_SUFFIXES include PATHS ${ZLIB_INSTALL_DIR} NO_DEFAULT_PATH)
    find_library(ZLIB_LIBRARY z zlibstaticd zlibstatic PATH_SUFFIXES lib64 lib32 lib PATHS ${ZLIB_INSTALL_DIR} NO_DEFAULT_PATH)
  else()
    get_source_directory(ZLIB_SOURCE_DIRECTORY "zlib-src")
    get_build_directory(ZLIB_BUILD_DIRECTORY ZLIB_SOURCE_DIRECTORY)
    get_local_library_directory(ZLIB_LIBRARY_LOCAL_DIR ZLIB_SOURCE_DIRECTORY)
    find_library(ZLIB_LIBRARY z PATHS ${ZLIB_LIBRARY_LOCAL_DIR} NO_DEFAULT_PATH)
    find_path(ZLIB_INCLUDE_DIR zlib.h PATHS ${ZLIB_SOURCE_DIRECTORY} NO_DEFAULT_PATH)
    find_path(ZLIB_INCLUDE_CONFIG_DIR zconf.h PATHS ${ZLIB_BUILD_DIRECTORY} NO_DEFAULT_PATH)
  endif()
  include_directories(${ZLIB_INCLUDE_DIR} ${ZLIB_INCLUDE_CONFIG_DIR})
endfunction()

function(vpvl2_link_libxml2 target)
  if(LIBXML2_LIBRARY)
    target_link_libraries(${target} ${LIBXML2_LIBRARY})
  endif()
endfunction()

function(vpvl2_find_libxml2)
  if(VPVL2_ENABLE_EXTENSIONS_PROJECT)
    get_install_directory(LIBXML2_INSTALL_DIR "libxml2-src")
    find_path(LIBXML2_INCLUDE_DIR NAMES libxml/xmlwriter.h PATH_SUFFIXES include/libxml2 PATHS ${LIBXML2_INSTALL_DIR} NO_DEFAULT_PATH)
    find_library(LIBXML2_LIBRARY xml2 libxml2_a libxml2 PATH_SUFFIXES lib64 lib32 lib PATHS ${LIBXML2_INSTALL_DIR} NO_DEFAULT_PATH)
    include_directories(${LIBXML2_INCLUDE_DIR})
  endif()
endfunction()

function(vpvl2_link_alsoft target)
  if(ALSOFT_LIBRARY)
    target_link_libraries(${target} ${ALSOFT_LIBRARY})
  endif()
endfunction()

function(vpvl2_find_alsoft)
  get_install_directory(ALSOFT_INSTALL_DIR "openal-soft-src")
  if(WIN32)
    find_path(ALSOFT_INCLUDE_DIR NAMES al.h PATH_SUFFIXES include/AL PATHS ${ALSOFT_INSTALL_DIR} NO_DEFAULT_PATH)
  else()
    find_path(ALSOFT_INCLUDE_DIR NAMES OpenAL/al.h AL/al.h PATH_SUFFIXES include PATHS ${ALSOFT_INSTALL_DIR} NO_DEFAULT_PATH)
  endif()
  find_library(ALSOFT_LIBRARY OpenAL32 openal PATH_SUFFIXES lib64 lib32 lib PATHS ${ALSOFT_INSTALL_DIR} NO_DEFAULT_PATH)
  include_directories(${ALSOFT_INCLUDE_DIR})
endfunction()

function(vpvl2_link_alure target)
  if(ALURE_LIBRARY)
    target_link_libraries(${target} ${ALURE_LIBRARY})
  endif()
endfunction()

function(vpvl2_find_alure)
  get_install_directory(ALURE_INSTALL_DIR "alure-src")
  find_path(ALURE_INCLUDE_DIR NAMES OpenAL/alure.h AL/alure.h PATH_SUFFIXES include PATHS ${ALURE_INSTALL_DIR} NO_DEFAULT_PATH)
  find_library(ALURE_LIBRARY ALURE32-static alure-static ALURE32 alure PATH_SUFFIXES lib64 lib32 lib PATHS ${ALURE_INSTALL_DIR} NO_DEFAULT_PATH)
  include_directories(${ALURE_INCLUDE_DIR})
endfunction()

function(vpvl2_link_gl_runtime target)
  target_link_libraries(${target} ${OPENGL_gl_LIBRARY})
endfunction()

function(vpvl2_find_gl_runtime)
  if(VPVL2_ENABLE_EXTENSIONS_APPLICATIONCONTEXT)
    if(VPVL2_ENABLE_OSMESA)
      get_source_directory(MESA3D_SOURCE_DIR "mesa-src")
      find_library(MESA3D_MESA_LIBRARY mesa PATH_SUFFIXES "embed-darwin-x86_64/mesa" "darwin-x86_64/mesa" PATHS "${MESA3D_SOURCE_DIR}/build" NO_DEFAULT_PATH)
      find_library(MESA3D_OSMESA_LIBRARY osmesa PATH_SUFFIXES "embed-darwin-x86_64/mesa/drivers/osmesa" "darwin-x86_64/mesa/drivers/osmesa" PATHS "${MESA3D_SOURCE_DIR}/build" NO_DEFAULT_PATH)
      set(OPENGL_gl_LIBRARY "${OPENGL_gl_mesa_LIBRARY} ${OPENGL_gl_osmesa_LIBRARY}")
      find_path(OPENGL_INCLUDE_DIR GL/osmesa.h PATH_SUFFIXES include PATHS ${MESA3D_SOURCE_DIR} NO_DEFAULT_PATH)
    elseif(VPVL2_ENABLE_GLES2)
      find_path(OPENGL_INCLUDE_DIR gl2.h PATH_SUFFIXES include/OpenGLES2 include/GLES2 include)
      if(NOT VPVL2_PLATFORM_EMSCRIPTEN)
        find_library(OPENGL_gl_LIBRARY NAMES ppapi_gles2 GLESv2)
      endif()
    else()
      find_package(OpenGL REQUIRED)
    endif()
    include_directories(${OPENGL_INCLUDE_DIR})
  endif()
endfunction()

function(vpvl2_link_cg_runtime target)
  if(CG_LIBRARY AND CG_GL_LIBRARY)
    target_link_libraries(${target} ${CG_LIBRARY} ${CG_GL_LIBRARY})
  endif()
endfunction()

function(vpvl2_find_cg_runtime)
  if(VPVL2_ENABLE_NVIDIA_CG AND VPVL2_ENABLE_EXTENSIONS_APPLICATIONCONTEXT)
    find_package(Cg REQUIRED)
    include_directories(${CG_INCLUDE_DIR})
  endif()
endfunction()

function(vpvl2_link_cl_runtime target)
  if(OPENCL_LIBRARY)
    target_link_libraries(${target} ${OPENCL_LIBRARY})
  endif()
endfunction()

function(vpvl2_find_cl_runtime)
  if(VPVL2_ENABLE_OPENCL)
    find_library(OPENCL_LIBRARY OpenCL)
    find_path(OPENCL_INCLUDE_DIR cl.h PATH_SUFFIXES include/OpenCL include/CL include)
    include_directories(${OPENCL_INCLUDE_DIR})
  endif()
endfunction()

function(vpvl2_find_gli)
  get_source_directory(GLI_SOURCE_DIRECTORY "gli-src")
  find_path(GLI_INCLUDE_DIR "gli/gli.hpp" PATHS ${GLI_SOURCE_DIRECTORY})
  include_directories(${GLI_INCLUDE_DIR})
endfunction()

function(vpvl2_find_glm)
  get_source_directory(GLM_SOURCE_DIRECTORY "glm-src")
  find_path(GLM_INCLUDE_DIR "glm/glm.hpp" PATHS ${GLM_SOURCE_DIRECTORY})
  include_directories(${GLM_INCLUDE_DIR})
endfunction()

function(vpvl2_link_glog target)
  if(GLOG_LIBRARY)
    target_link_libraries(${target} ${GLOG_LIBRARY})
  endif()
endfunction()

function(vpvl2_find_glog)
  if(VPVL2_LINK_GLOG)
    if(MSVC)
      get_source_directory(GLOG_INSTALL_DIR "glog-src")
      find_path(GLOG_INCLUDE_DIR NAMES glog/logging.h PATH_SUFFIXES src/windows PATHS ${GLOG_INSTALL_DIR} NO_DEFAULT_PATH)
      find_library(GLOG_LIBRARY libglog PATH_SUFFIXES ${CMAKE_BUILD_TYPE} PATHS ${GLOG_INSTALL_DIR} NO_DEFAULT_PATH)
    else()
      get_install_directory(GLOG_INSTALL_DIR "glog-src")
      find_path(GLOG_INCLUDE_DIR NAMES glog/logging.h PATH_SUFFIXES include PATHS ${GLOG_INSTALL_DIR} NO_DEFAULT_PATH)
      find_library(GLOG_LIBRARY glog PATH_SUFFIXES lib64 lib32 lib PATHS ${GLOG_INSTALL_DIR} NO_DEFAULT_PATH)
    endif()
    include_directories(${GLOG_INCLUDE_DIR})
  endif()
endfunction()

function(vpvl2_link_hlslxc target)
  if(HLSLXC_LIBRARY)
    target_link_libraries(${target} ${HLSLXC_LIBRARY})
  endif()
endfunction()

function(vpvl2_find_hlslxc)
  if(VPVL2_ENABLE_EXTENSIONS_EFFECT)
    get_source_directory(HLSLXC_SRC_DIR "hlslxc-src")
    find_path(HLSLXC_INCLUDE_DIR toGLSL.h PATHS ${HLSLXC_SRC_DIR} NO_DEFAULT_PATH)
    find_library(HLSLXC_LIBRARY libHLSLcc PATH_SUFFIXES lib PATHS ${HLSLXC_SRC_DIR} NO_DEFAULT_PATH)
    include_directories(${HLSLXC_INCLUDE_DIR} "${HLSLXC_INCLUDE_DIR}/cbstring")
  endif()
endfunction()

function(vpvl2_link_regal target)
  if(REGAL_LIBRARY)
    target_link_libraries(${target} ${REGAL_LIBRARY})
  endif()
endfunction()

function(vpvl2_find_regal)
  if(VPVL2_LINK_REGAL)
    get_install_directory(REGAL_INSTALL_DIR "regal-src")
    find_path(REGAL_INCLUDE_DIR NAMES GL/Regal.h PATH_SUFFIXES include PATHS ${REGAL_INSTALL_DIR} NO_DEFAULT_PATH)
    find_library(REGAL_LIBRARY Regal PATH_SUFFIXES lib64 lib32 lib PATHS ${REGAL_INSTALL_DIR} NO_DEFAULT_PATH)
    include_directories(${REGAL_INCLUDE_DIR})
  endif()
endfunction()

function(vpvl2_link_tinyxml2 target)
  if(TINYXML2_LIBRARY)
    target_link_libraries(${target} ${TINYXML2_LIBRARY})
  endif()
endfunction()

function(vpvl2_find_tinyxml2)
  if(VPVL2_ENABLE_EXTENSIONS_PROJECT)
    get_install_directory(TINYXML2_INSTALL_DIR "tinyxml2-src")
    find_path(TINYXML2_INCLUDE_DIR NAMES tinyxml2.h PATH_SUFFIXES include PATHS ${TINYXML2_INSTALL_DIR} NO_DEFAULT_PATH)
    find_library(TINYXML2_LIBRARY tinyxml2 PATH_SUFFIXES lib64 lib32 lib PATHS ${TINYXML2_INSTALL_DIR} NO_DEFAULT_PATH)
    include_directories(${TINYXML2_INCLUDE_DIR})
  endif()
endfunction()

function(vpvl2_link_nvfx target)
  if(NVFX_FXLIB_LIBRARY AND NVFX_FXLIBGL_LIBRARY AND NVFX_FXPARSER_LIBRARY)
    target_link_libraries(${target} ${NVFX_FXPARSER_LIBRARY} ${NVFX_FXLIBGL_LIBRARY} ${NVFX_FXLIB_LIBRARY})
  endif()
endfunction()

function(vpvl2_find_nvfx)
  if(VPVL2_LINK_NVFX)
    get_install_directory(NVFX_INSTALL_DIR "nvfx-src")
    find_path(NVFX_INCLUDE_DIR NAMES FxParser.h PATH_SUFFIXES include PATHS ${NVFX_INSTALL_DIR} NO_DEFAULT_PATH)
    find_library(NVFX_FXLIB_LIBRARY FxLib PATH_SUFFIXES lib64 lib32 lib PATHS ${NVFX_INSTALL_DIR} NO_DEFAULT_PATH)
    find_library(NVFX_FXLIBGL_LIBRARY FxLibGL PATH_SUFFIXES lib64 lib32 lib PATHS ${NVFX_INSTALL_DIR} NO_DEFAULT_PATH)
    find_library(NVFX_FXPARSER_LIBRARY FxParser PATH_SUFFIXES lib64 lib32 lib PATHS ${NVFX_INSTALL_DIR} NO_DEFAULT_PATH)
    include_directories(${NVFX_INCLUDE_DIR})
  endif()
endfunction()

function(vpvl2_link_atb target)
  if(ATB_LIBRARY)
    target_link_libraries(${target} ${ATB_LIBRARY})
    if(APPLE)
      find_library(COCOA_FRAMEWORK Cocoa)
      target_link_libraries(${target} ${COCOA_FRAMEWORK})
     endif()
  endif()
endfunction()

function(vpvl2_find_atb)
  if(VPVL2_LINK_ATB)
    get_source_directory(ATB_INSTALL_DIR "AntTweakBar-src")
    find_path(ATB_INCLUDE_DIR NAMES AntTweakBar.h PATH_SUFFIXES include PATHS ${ATB_INSTALL_DIR} NO_DEFAULT_PATH)
    find_library(ATB_LIBRARY AntTweakBar PATH_SUFFIXES lib64 lib32 lib PATHS ${ATB_INSTALL_DIR} NO_DEFAULT_PATH)
    include_directories(${ATB_INCLUDE_DIR})
  endif()
endfunction()

function(vpvl2_link_freeimage target)
  if(FREEIMAGE_LIBRARY)
    target_link_libraries(${target} ${FREEIMAGE_LIBRARY})
  endif()
endfunction()

function(vpvl2_find_freeimage)
  if(VPVL2_LINK_FREEIMAGE)
    find_path(FREEIMAGE_INCLUDE_DIR NAMES FreeImage.h PATH_SUFFIXES include)
    find_library(FREEIMAGE_LIBRARY freeimage PATH_SUFFIXESlib lib64 lib32 )
    include_directories(${FREEIMAGE_INCLUDE_DIR})
  endif()
endfunction()

function(vpvl2_create_executable target)
  if(target)
    add_dependencies(${target} ${VPVL2_PROJECT_NAME})
    target_link_libraries(${target} ${VPVL2_PROJECT_NAME})
    vpvl2_link_all(${target})
  endif()
endfunction()

function(vpvl2_add_qt_helpers)
  if(VPVL2_BUILD_QT_RENDERER OR VPVL2_LINK_QT)
    find_package(Qt5Core QUIET)
    if (Qt5Core_FOUND)
      qt5_add_resources(vpvl2qtcommon_rc_src "${CMAKE_CURRENT_SOURCE_DIR}/src/qt/resources/libvpvl2qtcommon.qrc")
    else()
      find_package(Qt4 4.8 REQUIRED QtCore QtGui QtOpenGL)
      include(${QT_USE_FILE})
      qt4_add_resources(vpvl2qtcommon_rc_src "${CMAKE_CURRENT_SOURCE_DIR}/src/qt/resources/libvpvl2qtcommon.qrc")
    endif()
    file(GLOB vpvl2qtcommon_sources_common "${CMAKE_CURRENT_SOURCE_DIR}/src/qt/common/*.cc")
    file(GLOB vpvl2qtcommon_sources_unzip "${CMAKE_CURRENT_SOURCE_DIR}/src/qt/unzip/*.c")
    file(GLOB vpvl2qtcommon_headers_extensions "${CMAKE_CURRENT_SOURCE_DIR}/include/vpvl2/extensions/details/*.h")
    file(GLOB vpvl2qtcommon_headers "${CMAKE_CURRENT_SOURCE_DIR}/include/vpvl2/qt/*.h")
    source_group("VPVL2 for Qt sources" FILES ${vpvl2qtcommon_sources_common}
                                              ${vpvl2qtcommon_sources_unzip}
                                              ${vpvl2qtcommon_headers_extensions}
                                              ${vpvl2qtcommon_headers})
    set(vpvl2_qt_sources "${CMAKE_CURRENT_SOURCE_DIR}/render/qt/main.cc"
                         "${CMAKE_CURRENT_SOURCE_DIR}/render/qt/UI.cc")
    include_directories("${CMAKE_CURRENT_SOURCE_DIR}/render/qt"
                        "${CMAKE_CURRENT_SOURCE_DIR}/include/vpvl2/qt")
    if(APPLE AND NOT Qt5Core_FOUND)
      find_library(COCOA_LIBRARY Cocoa)
      find_path(COCOA_INCLUDE_DIR Cocoa/Cocoa.h)
      file(GLOB vpvl2qtcommon_sources_osx "${CMAKE_CURRENT_SOURCE_DIR}/src/qt/osx/*.mm")
      include_directories(${COCOA_INCLUDE_DIR})
    endif()
    add_library(vpvl2qtcommon ${VPVL2_LIB_TYPE} ${vpvl2qtcommon_sources_common} ${vpvl2qtcommon_sources_unzip}
                                                ${vpvl2qtcommon_headers} ${vpvl2qtcommon_headers_extensions}
                                                ${vpvl2qtcommon_sources_osx} ${vpvl2qtcommon_rc_src})
    vpvl2_set_library_properties(vpvl2qtcommon ${vpvl2qtcommon_headers})
    target_link_libraries(vpvl2qtcommon ${VPVL2_PROJECT_NAME})
    if (Qt5Core_FOUND)
      qt5_use_modules(vpvl2qtcommon Concurrent Widgets)
    else()
      target_link_libraries(vpvl2qtcommon ${VPVL2_PROJECT_NAME} ${QT_LIBRARIES})
    endif()
    if(APPLE)
      target_link_libraries(vpvl2qtcommon ${COCOA_LIBRARY})
    endif()
    set(VPVL2QTCOMMON_OUTPUT_NAME "vpvl2qtcommon")
    set_target_properties(vpvl2qtcommon PROPERTIES OUTPUT_NAME ${VPVL2QTCOMMON_OUTPUT_NAME}
                                                   VERSION ${VPVL2_VERSION}
                                                   SOVERSION ${VPVL2_VERSION_COMPATIBLE})
    if(VPVL2_BUILD_QT_RENDERER)
      set(VPVL2_EXECUTABLE vpvl2_qt)
      add_executable(${VPVL2_EXECUTABLE} ${vpvl2_qt_sources} ${vpvl2_internal_headers})
      add_dependencies(${VPVL2_EXECUTABLE} vpvl2qtcommon)
      vpvl2_link_alsoft(${VPVL2_EXECUTABLE})
      vpvl2_link_alure(${VPVL2_EXECUTABLE})
      if (Qt5Core_FOUND)
        qt5_use_modules(${VPVL2_EXECUTABLE} OpenGL Concurrent Widgets)
        target_link_libraries(${VPVL2_EXECUTABLE} vpvl2qtcommon)
      else()
        target_link_libraries(${VPVL2_EXECUTABLE} ${VPVL2_PROJECT_NAME} vpvl2qtcommon ${QT_LIBRARIES})
      endif()
      vpvl2_create_executable(${VPVL2_EXECUTABLE})
    endif()
    if(VPVL2_ENABLE_TEST)
      get_source_directory(GTEST_INSTALL_DIR "gtest-src")
      get_source_directory(GMOCK_INSTALL_DIR "gmock-src")
      file(GLOB vpvl2_test_sources "${CMAKE_CURRENT_SOURCE_DIR}/test/*.cc")
      source_group("VPVL2 Test Case Classes" FILES ${vpvl2_test_sources})
      file(GLOB vpvl2_mock_headers "${CMAKE_CURRENT_SOURCE_DIR}/test/mock/*.h")
      source_group("VPVL2 Mock Classes" FILES ${vpvl2_mock_headers})
      file(GLOB gtest_source "${GTEST_INSTALL_DIR}/src/gtest-all.cc")
      file(GLOB gmock_source "${GMOCK_INSTALL_DIR}/src/gmock-all.cc")
      if(Qt5Core_FOUND)
        qt5_add_resources(vpvl2_test_qrc "${CMAKE_CURRENT_SOURCE_DIR}/test/fixtures.qrc")
      else()
        qt4_add_resources(vpvl2_test_qrc "${CMAKE_CURRENT_SOURCE_DIR}/test/fixtures.qrc")
      endif()
      add_executable(vpvl2_test ${vpvl2_test_sources} ${vpvl2_mock_headers} ${vpvl2_test_qrc} ${gtest_source} ${gmock_source})
      if(Qt5Core_FOUND)
        qt5_use_modules(vpvl2_test OpenGL Concurrent)
      endif()
      include_directories(${GTEST_INSTALL_DIR} "${GTEST_INSTALL_DIR}/include")
      include_directories(${GMOCK_INSTALL_DIR} "${GMOCK_INSTALL_DIR}/include")
      target_link_libraries(vpvl2_test vpvl2qtcommon ${VPVL2_PROJECT_NAME} ${QT_LIBRARIES})
      add_dependencies(vpvl2_test ${VPVL2_PROJECT_NAME} vpvl2qtcommon)
      vpvl2_link_all(vpvl2_test)
    endif()
  endif()
endfunction()

function(vpvl2_add_sdl_renderer)
  if(VPVL2_LINK_SDL2)
    get_install_directory(SDL_INSTALL_DIR "SDL2-src")
    if(WIN32)
        find_library(SDL_LIBRARY SDL2 PATH_SUFFIXES lib PATHS ${SDL_INSTALL_DIR} NO_DEFAULT_PATH)
        find_library(SDL_MAIN_LIBRARY SDL2main PATH_SUFFIXES lib PATHS ${SDL_INSTALL_DIR} NO_DEFAULT_PATH)
        find_path(SDL_INCLUDE_DIR SDL.h PATH_SUFFIXES include/SDL2 PATHS ${SDL_INSTALL_DIR} NO_DEFAULT_PATH)
    else()
      #find_library(SDLIMAGE_LIBRARY SDL2_image REQUIRED)
      find_program(SDL2_CONFIG_SCRIPT sdl2-config REQUIRED PATH_SUFFIXES bin PATHS ${SDL_INSTALL_DIR} NO_DEFAULT_PATH)
      exec_program(${SDL2_CONFIG_SCRIPT} ARGS --cflags OUTPUT_VARIABLE SDL2_CFLAGS)
      exec_program(${SDL2_CONFIG_SCRIPT} ARGS --libs OUTPUT_VARIABLE SDL_LIBRARY)
      string(REGEX MATCHALL "-I[^ ]*" SDL_INCLUDE_DIR ${SDL2_CFLAGS})
      string(REGEX MATCHALL "-D[^ ]*" SDL_DEFINITIONS ${SDL2_CFLAGS})
      string(REPLACE "-I" "" SDL_INCLUDE_DIR "${SDL_INCLUDE_DIR}")
    endif()
    add_definitions(${SDL_DEFINITIONS})
    include_directories(${SDL_INCLUDE_DIR} ${SDLIMAGE_INCLUDE_DIR})
    set(vpvl2_sdl_sources "render/sdl/main.cc")
    set(VPVL2_EXECUTABLE vpvl2_sdl)
    add_executable(${VPVL2_EXECUTABLE} ${vpvl2_sdl_sources})
    target_link_libraries(${VPVL2_EXECUTABLE} ${SDL_MAIN_LIBRARY} ${SDL_LIBRARY})# ${SDLIMAGE_LIBRARY})
    vpvl2_create_executable(${VPVL2_EXECUTABLE})
    if(WIN32)
      find_library(WIN32_WINMM_LIBRARY winmm)
      find_library(WIN32_VERSION_LIBRARY version)
      find_library(WIN32_IMM_LIBRARY imm32)
      target_link_libraries(${VPVL2_EXECUTABLE} ${WIN32_WINMM_LIBRARY} ${WIN32_IMM_LIBRARY} ${WIN32_VERSION_LIBRARY})
    endif()
  endif()
endfunction()

function(vpvl2_add_glfw_renderer)
  if(VPVL2_LINK_GLFW)
    get_install_directory(GLFW_INSTALL_DIR "glfw-src")
    find_path(GLFW_INCLUDE_DIR NAMES GLFW/glfw3.h PATH_SUFFIXES include PATHS ${GLFW_INSTALL_DIR} NO_DEFAULT_PATH)
    find_library(GLFW_LIBRARY NAMES glfw3 glfw PATH_SUFFIXES lib64 lib32 lib PATHS ${GLFW_INSTALL_DIR} NO_DEFAULT_PATH)
    include_directories(${GLFW_INCLUDE_DIR})
    set(vpvl2_glfw_sources "render/glfw/main.cc")
    set(VPVL2_EXECUTABLE vpvl2_glfw)
    add_executable(${VPVL2_EXECUTABLE} ${vpvl2_glfw_sources})
    if(APPLE)
      find_library(COCOA_LIBRARY Cocoa)
      find_library(IOKIT_LIBRARY IOKit)
      find_library(COREFOUNDATION_LIBRARY CoreFoundation)
      target_link_libraries(${VPVL2_EXECUTABLE} ${COCOA_LIBRARY} ${IOKIT_LIBRARY} ${COREFOUNDATION_LIBRARY})
    endif()
    target_link_libraries(${VPVL2_EXECUTABLE} ${GLFW_LIBRARY})
    vpvl2_create_executable(${VPVL2_EXECUTABLE})
  endif()
endfunction()

function(vpvl2_add_sfml_renderer)
  if(VPVL2_LINK_SFML)
    vpvl2_find_sfml()
    set(vpvl2_sfml_sources "render/sfml/main.cc")
    set(VPVL2_EXECUTABLE vpvl2_sfml)
    add_executable(${VPVL2_EXECUTABLE} ${vpvl2_sfml_sources})
    target_link_libraries(${VPVL2_EXECUTABLE} ${SFML_GRAPHICS_LIBRARY}
                                              ${SFML_WINDOW_LIBRARY}
                                              ${SFML_SYSTEM_LIBRARY})
    if(APPLE AND NOT VPVL2_LINK_GLEW)
      find_library(COREFOUNDATION_FRAMEWORK CoreFoundation)
      find_path(COREFOUNDATION_INCLUDE_PATH "CoreFoundation/CoreFoundation.h")
      set(VPVL2_EXECUTABLE vpvl2_sfml)
      target_link_libraries(${VPVL2_EXECUTABLE} ${COREFOUNDATION_FRAMEWORK})
      include_directories(${COREFOUNDATION_INCLUDE_PATH})
    endif()
    vpvl2_create_executable(${VPVL2_EXECUTABLE})
  endif()
endfunction()

function(vpvl2_add_egl_renderer)
  if(VPVL2_LINK_EGL)
    find_path(EGL_INCLUDE_DIR EGL/egl.h)
    find_library(EGL_LIBRARY EGL)
    set(vpvl2_egl_sources "render/egl/main.cc")
    set(VPVL2_EXECUTABLE vpvl2_egl)
    add_executable(${VPVL2_EXECUTABLE} ${vpvl2_egl_sources})
    target_link_libraries(${VPVL2_EXECUTABLE} ${EGL_LIBRARY})
    include_directories(${EGL_INCLUDE_DIR})
    if(VPVL2_PLATFORM_RASPBERRY_PI)
      find_path(VCOS_INCLUDE_DIR vcos_platform_types.h)
      find_library(BCM_HOST_LIBRARY bcm_host)
      find_library(VCOS_LIBRARY vcos)
      find_library(VCHIQ_ARM_LIBRARY vchiq_arm)
      include_directories(${VCOS_INCLUDE_DIR})
      target_link_libraries(${VPVL2_EXECUTABLE} ${BCM_HOST_LIBRARY} ${VCOS_LIBRARY} ${VCHIQ_ARM_LIBRARY})
    endif()
    vpvl2_create_executable(${VPVL2_EXECUTABLE})
  endif()
endfunction()

function(vpvl2_find_all)
  vpvl2_find_vpvl()
  vpvl2_find_nvfx()
  vpvl2_find_regal()
  vpvl2_find_atb()
  vpvl2_find_hlslxc()
  vpvl2_find_alsoft()
  vpvl2_find_alure()
  vpvl2_find_freeimage()
  vpvl2_find_tbb()
  vpvl2_find_bullet()
  vpvl2_find_assimp()
  vpvl2_find_icu()
  vpvl2_find_glog()
  vpvl2_find_tinyxml2()
  vpvl2_find_gli()
  vpvl2_find_glm()
  vpvl2_find_zlib()
  vpvl2_find_openmp()
  vpvl2_find_cg_runtime()
  vpvl2_find_cl_runtime()
  vpvl2_find_gl_runtime()
endfunction()

function(vpvl2_link_all target)
  vpvl2_link_vpvl(${target})
  vpvl2_link_nvfx(${target})
  vpvl2_link_regal(${target})
  vpvl2_link_atb(${target})
  vpvl2_link_hlslxc(${target})
  vpvl2_link_freeimage(${target})
  vpvl2_link_tbb(${target})
  vpvl2_link_bullet(${target})
  vpvl2_link_assimp(${target})
  vpvl2_link_icu(${target})
  vpvl2_link_glog(${target})
  vpvl2_link_tinyxml2(${target})
  vpvl2_link_zlib(${target})
  vpvl2_link_cg_runtime(${target})
  vpvl2_link_cl_runtime(${target})
  vpvl2_link_gl_runtime(${target})
endfunction()
# end of functions
