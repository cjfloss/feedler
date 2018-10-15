project('com.github.cjfloss.feedler', 'vala', 'c',
  version : '0.1.0',
  license : 'LGPL2+',
  default_options : ['warning_level=3'])

add_global_arguments('-DGETTEXT_PACKAGE="' + meson.project_name() + '"',language : 'c')


release_name = 'beta'

prefix = get_option('prefix')
datadir = join_paths(prefix, get_option('datadir'))
pkg_datadir = join_paths(datadir, meson.project_name())
if find_program('git', required : false).found()
    GIT_BRANCH = run_command('git', 'rev-parse', '--abbrev-ref', 'HEAD')
    GIT_COMMIT_HASH = run_command('git','log', '-1', '--format=%h')
    git_branch = GIT_BRANCH.stdout().strip()
    git_commit_hash = GIT_COMMIT_HASH.stdout().strip()
    version_info = 'git-' + git_branch + '-' + git_commit_hash
else
    git_branch = 'no-git'
    git_commit_hash = 'no-git'
    version_info = release_name
endif

config = configuration_data()
config.set('app_name', meson.project_name ())
config.set('datadir', datadir)
config.set('pkg_datadir', pkg_datadir)
config.set('gettext_package', meson.project_name ())
config.set('release_name', release_name)
config.set('version', meson.project_version ())
config.set('version_info', version_info)
config.set('git_branch', git_branch)
config.set('git_commit_hash', git_commit_hash)

exe = executable (
    meson.project_name (),
    'src/desktop-launcher.vala',
    'src/database.vala',
    'src/dock.vala',
    'src/feedler.vala',
    'src/icons.vala',
    'src/history.vala',
    'src/manager.vala',
    'src/settings.vala',
    'src/window.vala',
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
