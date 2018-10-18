gnome = import ('gnome')
i18n  = import ('i18n')

icons = ['all.png', 'favicon.png', 'mark.svg', 'rss.png', 'star.png', 'unread.png']

foreach i : icons
    install_data(
        join_paths('icons', i),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', 'scalable', 'apps')
    )
endforeach

install_data (
    meson.project_name () + '.gschema.xml',
    install_dir : join_paths (get_option ('datadir'), 'glib-2.0', 'schemas')
)
meson.add_install_script ('post_install.py')

srv = configure_file (
    input : meson.project_name () + '.service.in',
    output : meson.project_name () + '.service',
    configuration : config
)
install_data(
    srv,
    install_dir : join_paths(get_option('datadir'), 'dbus-1', 'services')
)

i18n.merge_file (
    'desktop',
    input : meson.project_name () + '.desktop.in',
    output : meson.project_name () + '.desktop',
    install : true,
    install_dir : join_paths (get_option ('datadir'), 'applications'),
    po_dir : join_paths (meson.source_root (), 'po'),
    type : 'desktop'
)

i18n.merge_file (
    'appdata',
    input : meson.project_name () + '.appdata.xml.in',
    output : meson.project_name () + '.appdata.xml',
    install : true,
    install_dir : join_paths (get_option ('datadir'), 'metainfo'),
    po_dir : join_paths (meson.source_root (), 'po')
)

test (
    'Validate desktop file',
    find_program ('desktop-file-validate'),
    args : join_paths (meson.current_build_dir (), meson.project_name () + '.desktop')
)

test (
   'Validate appdata file',
    find_program ('appstreamcli'),
    args : ['validate', join_paths (meson.current_build_dir (), meson.project_name () + '.appdata.xml')]
)
