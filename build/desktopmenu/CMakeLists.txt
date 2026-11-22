cmake_minimum_required(VERSION 3.16)
project(mos_desktopmenu)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(ECM REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${ECM_MODULE_PATH})
include(KDEInstallDirs)
include(KDECMakeSettings)
include(KDECompilerSettings NO_POLICY_SCOPE)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets)
find_package(KF6 REQUIRED COMPONENTS CoreAddons Config)
find_package(Plasma REQUIRED)

kcoreaddons_add_plugin(mos_desktopmenu SOURCES mosmenu.cpp mosmenu.h INSTALL_NAMESPACE "plasma/containmentactions")
set_target_properties(mos_desktopmenu PROPERTIES OUTPUT_NAME org.mos.desktopmenu)
target_link_libraries(mos_desktopmenu Plasma::Plasma Qt6::Widgets KF6::CoreAddons KF6::ConfigCore)
