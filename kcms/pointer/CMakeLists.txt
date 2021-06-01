if(NOT X11_Xinput_FOUND)
    message(FATAL_ERROR "Xinput not found")
endif()

add_definitions(-DTRANSLATION_DOMAIN=\"kcmmouse\")

set(common_SRCS
    ../mouse/inputbackend.cpp
)

include(ECMQtDeclareLoggingCategory)
ecm_qt_declare_logging_category(common_SRCS
    HEADER
        logging.h
    IDENTIFIER
        KCM_MOUSE
    CATEGORY_NAME
        kcm_mouse
    DEFAULT_SEVERITY
        Critical
)

include_directories(
    ${X11_X11_INCLUDE_PATH}
    ${X11_Xinput_INCLUDE_PATH}
    ${Evdev_INCLUDE_DIRS}
    ${XORGLIBINPUT_INCLUDE_DIRS}
    ../mouse
)

set(backend_SRCS
    ${backend_SRCS}
    ../mouse/backends/x11/x11_backend.cpp
    ../mouse/backends/x11/x11_evdev_backend.cpp
    ../mouse/backends/x11/evdev_settings.cpp
    ../mouse/backends/x11/x11_libinput_backend.cpp
    ../mouse/backends/x11/x11_libinput_dummydevice.cpp
    ../mouse/backends/x11/libinput_settings.cpp
)

set(backend_LIBS
    ${backend_LIBS}
    KF5::WindowSystem
    Qt5::X11Extras
    ${X11_X11_LIB}
    ${X11_Xinput_LIB}
)

if (X11_Xcursor_FOUND)
    set(backend_LIBS
        ${X11_Xcursor_LIB}
        ${backend_LIBS}
    )
    include_directories(${X11_Xcursor_INCLUDE_PATH})
endif ()

set(common_SRCS
    ${common_SRCS}
)

SET(backend_SRCS
    ${backend_SRCS}
    ../mouse/backends/kwin_wl/kwin_wl_backend.cpp
    ../mouse/backends/kwin_wl/kwin_wl_device.cpp
)

set(pointer_SRCS # Specify source files for the library
    pointer.cpp
)

add_library(kcm_pointer MODULE ${pointer_SRCS} ${common_SRCS} ${backend_SRCS})

target_link_libraries(kcm_pointer
    Qt5::Core
    KF5::CoreAddons
    KF5::I18n
    KF5::QuickAddons
    KF5::ConfigCore
    ${backend_LIBS}
    KF5::KCMUtils
    KF5::KIOCore
    KF5::KIOWidgets
    KF5::Declarative
    PW::KWorkspace

    Qt5::DBus
    Qt5::QuickWidgets
)

kcoreaddons_desktop_to_json(kcm_pointer "pointer.desktop") # Convert our desktop file to json

install(TARGETS kcm_pointer DESTINATION ${KDE_INSTALL_PLUGINDIR}/kcms) # Install the library to the kcm pointer
install(FILES pointer.desktop DESTINATION ${KDE_INSTALL_KSERVICES5DIR}) # Install the desktop file
kpackage_install_package(package kcm_pointer kcms) # Finally install our QML kpackage.

