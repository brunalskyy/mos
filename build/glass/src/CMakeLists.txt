

set(mosglass_SOURCES
    blur.cpp
    blur.qrc
    main.cpp
)

kconfig_add_kcfg_files(mosglass_SOURCES
    blurconfig.kcfgc
)

add_library(mosglass MODULE ${mosglass_SOURCES})
target_link_libraries(mosglass PRIVATE
    KWin::kwin

    KF6::ConfigGui
)
if (${KDecoration3_FOUND})
    target_link_libraries(mosglass PRIVATE KDecoration3::KDecoration)
else()
    target_link_libraries(mosglass PRIVATE KDecoration2::KDecoration)
endif()

install(TARGETS mosglass DESTINATION ${KDE_INSTALL_PLUGINDIR}/kwin/effects/plugins)
