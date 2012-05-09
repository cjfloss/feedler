cmake_minimum_required (VERSION 2.8)
project (feedler)

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/vala)

#
# Base bits
#
set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/feedler")
set (GETTEXT_PACKAGE "feedler")
set (RELEASE_NAME "Just weakling.")
set (VERSION "0.0.1")
set (VERSION_INFO "Alpha")

#
# Niceties
#
set (ARCHIVE_NAME feedler-${VERSION})
add_custom_target (dist
    COMMAND bzr export --root=${ARCHIVE_NAME} ${CMAKE_BINARY_DIR}/${ARCHIVE_NAME}.tar.bz2
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    )

add_custom_target (distcheck
    COMMAND cd ${CMAKE_BINARY_DIR}
    && rm -rf ${ARCHIVE_NAME}
    && tar xf ${ARCHIVE_NAME}.tar.bz2
    && mkdir ${ARCHIVE_NAME}/build
    && cd ${ARCHIVE_NAME}/build
    && cmake -DCMAKE_INSTALL_PREFIX=../install -DGSETTINGS_LOCALINSTALL=ON .. -DCMAKE_MODULE_PATH=/usr/share/cmake
    && make -j8
    && make -j8 install
    && make check
    )
add_dependencies(distcheck dist)

add_custom_target (uninstall "${CMAKE_COMMAND}" -P
  "${CMAKE_SOURCE_DIR}/cmake/uninstall.cmake")

#
# config.h
#

configure_file (${CMAKE_SOURCE_DIR}/config.h.cmake ${CMAKE_BINARY_DIR}/config.h)
add_definitions(-include config.h)

#
# Data
#
file (GLOB _datafiles "${CMAKE_CURRENT_SOURCE_DIR}/data/style/*")
install (FILES ${_datafiles} DESTINATION ${PKGDATADIR}/style)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/feedler.desktop DESTINATION /usr/share/applications)

#
# i18n
#
find_package (Gettext REQUIRED)

add_custom_command (OUTPUT ${CMAKE_SOURCE_DIR}/po/feedler.pot
        COMMAND xgettext -c --files-from ${CMAKE_SOURCE_DIR}/po/POTFILES.in --keyword=_ -o ${CMAKE_SOURCE_DIR}/po/feedler.pot --no-wrap --no-location
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        )

if (${GETTEXT_FOUND} STREQUAL "TRUE")
        set (HAVE_GETTEXT true)
        file (GLOB _translations ${CMAKE_SOURCE_DIR}/po/*.po)
        GETTEXT_CREATE_TRANSLATIONS (${CMAKE_SOURCE_DIR}/po/${PROJECT_NAME}.pot
                ALL ${_translations})
endif (${GETTEXT_FOUND} STREQUAL "TRUE")

#
# Feedler
#

set (FEEDLER_DEPS "webkitgtk-3.0;gtk+-3.0;sqlheavy-0.1;libsoup-2.4;libxml-2.0;libnotify;granite;")

find_package(PkgConfig)
pkg_check_modules(WEBKIT REQUIRED "webkitgtk-3.0")
pkg_check_modules(GTK+ REQUIRED "gtk+-3.0")
pkg_check_modules(SQLHEAVY REQUIRED "sqlheavy-0.1")
pkg_check_modules(SOUP REQUIRED "libsoup-2.4")
pkg_check_modules(XML REQUIRED "libxml-2.0")
pkg_check_modules(NOTIFY REQUIRED "libnotify")
pkg_check_modules(GRANITE REQUIRED "granite")
pkg_check_modules(DEPS REQUIRED ${FEEDLER_DEPS})

add_definitions(${DEPS_CFLAGS})

link_libraries(${DEPS_LIBRARIES})

link_directories(${DEPS_LIBRARY_DIRS})

find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.12.0" MINIMUM)

include(ValaPrecompile)
vala_precompile(VALA_C
	src/feedler-app.vala
	src/feedler-window.vala
	src/feedler-database.vala
	src/feedler-datatype.vala
	src/feedler-sidebar.vala
	src/feedler-settings.vala
	src/feedler-preferences.vala
	src/feedler-view.vala
	src/feedler-view-list.vala
	src/feedler-view-web.vala
	src/feedler-toolbar.vala
	src/feedler-parser.vala
	src/feedler-opml.vala
	src/feedler-history.vala
	src/feedler-create-subscription.vala
	src/feedler-cardlayout.vala
	src/feedler-view-cell.vala
	src/feedler-sidebar-cell.vala
	src/feedler-statusbar.vala
PACKAGES
	gtk+-3.0
    granite
	libnotify
	libsoup-2.4
	libxml-2.0
	sqlheavy-0.1
CUSTOM_VAPIS
    vapi/config.vapi
	vapi/webkitgtk-3.0.vapi
OPTIONS
    --thread
    -g
)

# Verbose GCC
#add_definitions(${CFLAGS} -Wall -Winit-self -Wwrite-strings -Wunreachable-code -Wstrict-prototypes )
add_executable(feedler ${VALA_C})

install(TARGETS feedler RUNTIME DESTINATION bin)

#
# GSettings Schema
#
include(GSettings)
add_schema("apps.feedler.gschema.xml")

