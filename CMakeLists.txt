cmake_minimum_required(VERSION 3.16)

project(EvolveUI VERSION 0.1 LANGUAGES CXX)

# ==========================
# C++ 标准
# ==========================
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ==========================
# 查找 Qt6 Quick 模块
# ==========================
find_package(Qt6 REQUIRED COMPONENTS Quick Multimedia Network)

qt_standard_project_setup(REQUIRES 6.8)

# ==========================
# 可执行文件
# ==========================
qt_add_executable(appEvolveUI
    main.cpp
    core/music.h
    core/music.cpp
)

# ==========================
# QML 模块
# ==========================
file(GLOB QML_COMPONENTS CONFIGURE_DEPENDS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "components/*.qml")
file(GLOB QML_PAGES CONFIGURE_DEPENDS RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "pages/*.qml")

qt_add_qml_module(appEvolveUI
    URI EvolveUI
    VERSION 1.0
    QML_FILES
        Main.qml
        ${QML_COMPONENTS}
        ${QML_PAGES}
)


# ==========================
# Qt 资源文件
# ==========================
qt_add_resources(APP_RESOURCES
    src.qrc
)

target_sources(appEvolveUI PRIVATE ${APP_RESOURCES})

# ==========================
# 平台特定设置
# ==========================
# macOS / iOS Bundle 设置
set_target_properties(appEvolveUI PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

# ==========================
# 链接 Qt 库
# ==========================
target_link_libraries(appEvolveUI
    PRIVATE Qt6::Quick Qt6::Multimedia Qt6::Network
)

# ==========================
# 安装规则
# ==========================
include(GNUInstallDirs)
install(TARGETS appEvolveUI
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
