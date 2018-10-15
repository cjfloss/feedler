project('com.github.cjfloss.feedler', 'vala', 'c',
  version : '0.2.0',
  default_options : ['warning_level=3'])

add_global_arguments('-DGETTEXT_PACKAGE="' + meson.project_name() + '"',language : 'c')


exe = executable (
    meson.project_name (),
    'src/desktop-launcher.vala',
    'src/database.vala',
    'src/dock.vala',
    'src/feedler.vala',
    'src/icons.vala',
    'src/indicator.vala',
    'src/history.vala',
    'src/manager.vala',
    'src/settings.vala',
    'src/window.vala',
    'src/ui/contractor.vala',
    'src/ui/folder.vala',
    'src/ui/infobar.vala',
    'src/ui/layout.vala',
    'src/ui/menu.vala',
    'src/ui/preferences.vala',
    'src/ui/sidebar.vala',
    'src/ui/sidebar-cell.vala',
    'src/ui/statusbar.vala',
    'src/ui/subscription.vala',
    'src/ui/toolbar.vala',
    'src/ui/view.vala',
    'src/ui/view-cell.vala',
    'src/ui/view-list.vala',
    'src/ui/view-web.vala',
    'src/service/interface.vala',
    'src/service/model.vala',
    'src/service/serializer.vala',
    dependencies : [
        dependency('glib-2.0', version :'>=2.29'),
        dependency('gtk+-3.0', version :'>=3.14'),
        dependency('webkit2gtk-4.0'),
        dependency('granite', version :'>=0.3.0'),
        dependency('sqlheavy-0.2'),
        dependency('libsoup-2.4'),
        dependency('libxml-2.0'),
        dependency('libnotify'),
        dependency('unity'),
        meson.get_compiler('vala').find_library('posix'),
        meson.get_compiler('c').find_library('m', required : false)
    ],
    install : true)

subdir ('po')

test('basic', exe)