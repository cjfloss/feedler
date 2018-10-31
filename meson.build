project(
  'com.github.cjfloss.feedler', 'vala', 'c',
  version : '0.1.0',
  license : 'LGPL2+'
)

add_global_arguments (
  '-DGETTEXT_PACKAGE="' + meson.project_name () + '"',
  language: 'c'
)


release_name = 'beta'
prefix = get_option ('prefix')
datadir = join_paths (prefix, get_option ('datadir'))
pkg_datadir = join_paths (datadir, meson.project_name ())

if find_program ('git', required: false).found ()
  GIT_BRANCH = run_command ('git', 'rev-parse', '--abbrev-ref', 'HEAD')
  GIT_COMMIT_HASH = run_command ('git','log', '-1', '--format=%h')
  git_branch = GIT_BRANCH.stdout ().strip ()
  git_commit_hash = GIT_COMMIT_HASH.stdout ().strip ()
  version_info = 'git-' + git_branch + '-' + git_commit_hash
else
  git_branch = 'no-git'
  git_commit_hash = 'no-git'
  version_info = release_name
endif

config = configuration_data ()
config.set ('app_name', meson.project_name ())
config.set ('prefix', prefix)
config.set ('datadir', datadir)
config.set ('pkg_datadir', pkg_datadir)
config.set ('gettext_package', meson.project_name ())
config.set ('release_name', release_name)
config.set ('version', meson.project_version ())
config.set ('version_info', version_info)
config.set ('git_branch', git_branch)
config.set ('git_commit_hash', git_commit_hash)

build_config = configure_file (
  input: 'src/Build.vala.in',
  output: 'Build.vala',
  configuration: config
)

vala_lint = find_program ('io.elementary.vala-lint', required: false)
if vala_lint.found()
  test (
    'Vala lint',
    vala_lint,
    args: ['-d', join_paths (meson.source_root (), 'src')]
  )
endif

service = executable (
  meson.project_name () + '-service',
  'src/Service/Abstract.vala',
  'src/Service/Backend-xml.vala',

  'src/Objects/Channel.vala',
  'src/Objects/Folder.vala',
  'src/Objects/Item.vala',
  'src/Objects/State.vala',

  'src/Service/Serializer.vala',
  'src/Service/Service.vala',
  'src/Service/Settings.vala',
  dependencies : [
    dependency ('libnotify'),
    dependency ('granite', version :'>=0.3.0'),
    dependency ('libsoup-2.4'),
    dependency ('libxml-2.0'),
    meson.get_compiler ('vala').find_library ('posix'),
    meson.get_compiler ('c').find_library ('m', required: false)
  ],
  install : true
)

main = executable (
  meson.project_name (),
  'src/Data/DB.vala',
  'src/Data/Queries.vala',
  'src/Data/Database.vala',

  'src/Objects/Channel.vala',
  'src/Objects/Folder.vala',
  'src/Objects/Item.vala',
  'src/Objects/State.vala',

  'src/Dock.vala',
  'src/Feedler.vala',
  'src/Icons.vala',
  'src/History.vala',
  'src/Manager.vala',
  'src/Settings.vala',
  'src/Window.vala',

  'src/Widget/Folder.vala',
  'src/Widget/Infobar.vala',
  'src/Widget/Layout.vala',
  'src/Widget/Menu.vala',
  'src/Widget/Preferences.vala',
  'src/Widget/Sidebar.vala',
  'src/Widget/SidebarCell.vala',
  'src/Widget/Statusbar.vala',
  'src/Widget/Subscription.vala',
  'src/Widget/Toolbar.vala',
  'src/Widget/View.vala',
  'src/Widget/ViewCell.vala',
  'src/Widget/ViewList.vala',
  'src/Widget/ViewWeb.vala',

  'src/Service/Interface.vala',
  'src/Service/Serializer.vala',
  build_config,
  dependencies : [
    dependency('glib-2.0', version :'>=2.29'),
    dependency('gtk+-3.0', version :'>=3.22'),
    dependency('granite', version :'>=0.3.0'),
    dependency('webkit2gtk-4.0'),
    dependency('sqlite3'),
    dependency('unity'),
    meson.get_compiler('vala').find_library('posix'),
    meson.get_compiler('c').find_library('m', required : false)
  ],
  install : true
)

subdir ('po')
subdir ('data')

test('basic', main)
