define unicorn::app (
  $approot,
  $pidfile,
  $socket,
  $backlog         = '2048',
  $workers         = $::processorcount,
  $user            = 'root',
  $group           = 'root',
  $config_file     = '',
  $config_template = 'unicorn/config_unicorn.config.rb.erb',
  $initscript      = "unicorn/init-unicorn.erb",
  $logdir          = "${approot}/log",
  $rack_env        = 'production',
  $preload_app     = false,
  $source          = 'system',
  $use_binstubs    = false,
) {

  # get the common stuff, like the unicorn package(s)
  require unicorn
  include unicorn::params

  if $use_binstubs {
    $bin_dir = "${approot}/bin"
  } else {
    $bin_dir = unicorn::params::bin_dir
  }

  # If we have been given a config path, use it, if not, make one up.
  # This _may_ not be the most secure, as it should live outside of
  # the approot unless it's almost going to be non $unicorn_user
  # writable.
  if $config_file == '' {
    $config = "${approot}/config/unicorn.config.rb"
  } else {
    $config = $config_file
  }

  $unicorn_opts = "-D -E ${rack_env} -c ${config}"
  # XXX Debian Wheezy specific
  case $source {
    'system': {
      $daemon = "${bin_dir}/unicorn"
      $daemon_opts = $unicorn_opts
    }
    'bundler': {
      $daemon = "${bin_dir}/bundle"
      $daemon_opts = "exec unicorn ${unicorn_opts}"
    }
    default: {
      fail("unicorn::app can't handle daemon source '${source}'")
    }
  }

  service { "unicorn_${name}":
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    start      => "/etc/init.d/unicorn_${name} start",
    stop       => "/etc/init.d/unicorn_${name} stop",
    restart    => "/etc/init.d/unicorn_${name} reload",
    require    => [
      File["/etc/init.d/unicorn_${name}"],
      File["/etc/default/unicorn_${name}"],
    ],
  }

  file {
    "/etc/default/unicorn_${name}":
      owner   => root,
      group   => root,
      mode    => 644,
      content => template("unicorn/default-unicorn.erb"),
      notify  => Service["unicorn_${name}"];
    "/etc/init.d/unicorn_${name}":
      owner   => root,
      group   => root,
      mode    => 755,
      content => template($initscript),
      notify  => Service["unicorn_${name}"];
    $config:
      owner   => root,
      group   => root,
      mode    => 644,
      content => template($config_template),
      notify  => Service["unicorn_${name}"];
  }
}
