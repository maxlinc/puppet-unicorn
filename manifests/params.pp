class unicorn::params {

  case $lsbmajdistrelease {
    '6': {
      $bin_dir = "/var/lib/gems/1.8/bin"
    }
    default: {
      $bin_dir = "/usr/local/bin"
    }
  }
}
