cmake_minimum_required(VERSION 3.16)

project(EvolveUI VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appEvolveUI
    main.cpp
)

qt_add_qml_module(appEvolveUI
    URI EvolveUI
    VERSION 1.0
    QML_FILES
        Main.qml

        components/Button.qml
        components/Input.qml
        components/List.qml
        QML_FILES components/HoverCard.qml
        QML_FILES
        QML_FILES
        QML_FILES components/Theme.qml
        QML_FILES components/SwitchButton.qml
        QML_FILES components/CheckBox.qml
        QML_FILES components/RadioButton.qml
        QML_FILES components/Dropdown.qml
        QML_FILES components/Slider.qml
)



qt_add_resources(APP_RESOURCES
        src.qrc
    )

target_sources(appEvolveUI PRIVATE ${APP_RESOURCES})


# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appEvolveUI PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appEvolveUI
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appEvolveUI
    PRIVATE Qt6::Quick
)

include(GNUInstallDirs)
install(TARGETS appEvolveUI
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
