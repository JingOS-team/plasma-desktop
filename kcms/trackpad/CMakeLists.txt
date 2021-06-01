
# KI18N Translation Domain for this library
add_definitions(-DTRANSLATION_DOMAIN=\"kcm_touchpad\")

find_package(X11 REQUIRED)
find_package(X11_XCB REQUIRED)
find_package(XCB REQUIRED COMPONENTS ATOM RECORD)
find_package(PkgConfig REQUIRED)

# if(NOT X11_Xinput_FOUND)
#     message(FATAL_ERROR "Xinput not found")
# endif()

include_directories(
    ${X11_Xinput_INCLUDE_PATH}
                    ${X11_X11_INCLUDE_PATH}
                    ${Synaptics_INCLUDE_DIRS}
                    ${XORGSERVER_INCLUDE_DIRS}
)

# set(TOUCHPAD_KCM_VERSION ${PROJECT_VERSION})

# add_subdirectory(icon)

# configure_file("${CMAKE_CURRENT_SOURCE_DIR}/version.h.cmake"
#                "${CMAKE_CURRENT_BINARY_DIR}/version.h"
# )


include_directories(
    # ${X11_X11_INCLUDE_PATH}
    # ${X11_Xinput_INCLUDE_PATH}
    # ${Evdev_INCLUDE_DIRS}
    # ${XORGLIBINPUT_INCLUDE_DIRS}
    ../touchpad
)


# include(backends/x11.cmake)
# include(backends/kwin_wayland.cmake)

set(backend_SRCS
    ../touchpad/touchpadbackend.cpp
    ../touchpad/logging.cpp
    # ${SRCS}
    # kcm/touchpadconfigcontainer.cpp
    # kcm/touchpadconfigplugin.cpp
    # kcm/libinput/touchpadconfiglibinput.cpp
    # kcm/xlib/customslider.cpp
    # kcm/xlib/sliderpair.cpp
    # kcm/xlib/testarea.cpp
    # kcm/xlib/testbutton.cpp
    # kcm/xlib/touchpadconfigxlib.cpp
    # kcm/xlib/touchpadparametersbase.cpp
    # kcm/xlib/customconfigdialogmanager.cpp

    ../touchpad/backends/libinputcommon.cpp
    ../touchpad/backends/kwin_wayland/kwinwaylandbackend.cpp
    ../touchpad/backends/kwin_wayland/kwinwaylandtouchpad.cpp
    ../touchpad/backends/x11/propertyinfo.cpp
    ../touchpad/backends/x11/xlibbackend.cpp
    ../touchpad/backends/x11/synapticstouchpad.cpp
    ../touchpad/backends/x11/xlibtouchpad.cpp
    ../touchpad/backends/x11/xcbatom.cpp
    ../touchpad/backends/x11/xlibnotifications.cpp
    ../touchpad/backends/x11/xrecordkeyboardmonitor.cpp
    )

if (HAVE_XORGLIBINPUT)
    include_directories(${XORGLIBINPUT_INCLUDE_DIRS})

    SET(backend_SRCS
        ${backend_SRCS}
        ../touchpad/backends/libinputcommon.cpp
        ../touchpad/backends/x11/libinputtouchpad.cpp
    )
endif()

SET(backend_LIBS
    ${backend_LIBS}
    XCB::ATOM
    XCB::RECORD
    ${X11_X11_LIB}
    X11::XCB
    ${X11_Xinput_LIB}
)

# qt5_add_dbus_interfaces(SRCS
#                         ${CMAKE_CURRENT_BINARY_DIR}/org.kde.touchpad.xml
# )

# qt5_add_resources( SRCS kcm/resources.qrc )

# kconfig_add_kcfg_files(SRCS kcm/xlib/touchpadparameters.kcfgc)

# ki18n_wrap_ui(SRCS
#             kcm/xlib/ui/pointermotion.ui
#             kcm/xlib/ui/tap.ui
#             kcm/xlib/ui/scroll.ui
#             kcm/xlib/ui/sensitivity.ui
#             kcm/xlib/ui/kded.ui
#             kcm/xlib/ui/testarea.ui
# )

# qt5_generate_dbus_interface(kded/kded.h org.kde.touchpad.xml)

# SET(SRCS
#     ${SRCS}
#     kded/kded.cpp
#     kded/kdedactions.cpp
# )

# kconfig_add_kcfg_files(SRCS kded/kdedsettings.kcfgc)

# add_library(kded_touchpad MODULE
#             ${SRCS}
#             ${backend_SRCS}
# )
# target_link_libraries(kded_touchpad
#                       ${backend_LIBS}
# 		      KF5::KCMUtils
# 		      KF5::Notifications
# 		      KF5::CoreAddons
# 		      KF5::WindowSystem
# 		      KF5::ConfigWidgets
# 		      KF5::DBusAddons
# 		      KF5::Completion
# 		      KF5::WidgetsAddons
# 		      KF5::I18n
# 		      KF5::Service
# 		      KF5::NotifyConfig
# 		      KF5::XmlGui
# 		      KF5::GlobalAccel
# 		      KF5::Plasma
# 		      KF5::Declarative
                      
# 		      Qt5::X11Extras
# 		      Qt5::QuickWidgets
# )

# add_subdirectory(applet)

# install(FILES kcm/kcm_touchpad.desktop
#         DESTINATION ${KDE_INSTALL_KSERVICES5DIR}
# )

# install(FILES kded/touchpaddaemon.kcfg
#         DESTINATION ${KDE_INSTALL_KCFGDIR}
# )
# install(FILES kded/kded_touchpad.desktop
#         DESTINATION ${KDE_INSTALL_KSERVICES5DIR}/kded
#         RENAME touchpad.desktop
# )
# install(FILES ${CMAKE_CURRENT_BINARY_DIR}/org.kde.touchpad.xml
#         DESTINATION ${KDE_INSTALL_DBUSINTERFACEDIR}
# )
# install(FILES kded/kcm_touchpad.notifyrc
#         DESTINATION ${KDE_INSTALL_KNOTIFY5RCDIR}
# )

# install(TARGETS kded_touchpad
#         DESTINATION ${KDE_INSTALL_PLUGINDIR}
# )

# install(FILES kcm/xlib/touchpad.kcfg
#         DESTINATION ${KDE_INSTALL_KCFGDIR}
# )


set(trackpad_SRCS # Specify source files for the library
    trackpad.cpp
)

add_library(kcm_trackpad MODULE ${trackpad_SRCS} ${backend_SRCS})

target_link_libraries(kcm_trackpad
    Qt5::Core
    KF5::I18n
    KF5::QuickAddons
    KF5::ConfigCore
    KF5::KCMUtils
    KF5::Notifications
    KF5::CoreAddons
    KF5::WindowSystem
    KF5::ConfigWidgets
    KF5::DBusAddons
    KF5::Completion
    KF5::WidgetsAddons
    KF5::Service
    KF5::NotifyConfig
    KF5::XmlGui
    KF5::GlobalAccel
    KF5::Plasma
    KF5::Declarative
    Qt5::X11Extras
    ${backend_LIBS}
)

kcoreaddons_desktop_to_json(kcm_trackpad "trackpad.desktop") # Convert our desktop file to json

install(TARGETS kcm_trackpad DESTINATION ${KDE_INSTALL_PLUGINDIR}/kcms) # Install the library to the kcm trackpad
install(FILES trackpad.desktop DESTINATION ${KDE_INSTALL_KSERVICES5DIR}) # Install the desktop file
kpackage_install_package(package kcm_trackpad kcms) # Finally install our QML kpackage.

