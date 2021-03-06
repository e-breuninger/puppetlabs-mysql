# See README.me for usage.
class mysql::backup::mysqldump (
  $backupconfig       = '/etc/mysql/mysqlbackup.cnf',
  $backupuser         = '',
  $backuppassword     = '',
  $backupdir          = '',
  $backupdirmode      = '0700',
  $backupdirowner     = 'root',
  $backupdirgroup     = $mysql::params::root_group,
  $backupcompress     = true,
  $backuprotate       = 30,
  $ignore_events      = true,
  $delete_before_dump = false,
  $backupdatabases    = [],
  $nobackupdatabases  = [],
  $file_per_database  = false,
  $include_triggers   = false,
  $include_routines   = false,
  $add_mysqldump_opts = '',
  $ensure             = 'present',
  $time               = ['23', '5'],
  $prescript          = false,
  $postscript         = false,
  $execpath           = '/usr/bin:/usr/sbin:/bin:/sbin',
  $template           = 'mysql/mysqlbackup.sh.erb',
  $template_params    = {},
) inherits mysql::params {

  ensure_packages(['bzip2'])

  # we do not use a default value in the class variable to have the possibility to use mysql::server::backup as a facade
  if $template {
    $template_set = $template
  }else{
    $template_set = 'mysql/mysqlbackup.sh.erb'
  }

  # we do not use a default value in the class variable to have the possibility to use mysql::server::backup as a facade
  if $template {
    $template_set = $template
  }else{
    $template_set = 'mysql/mysqlbackup.sh.erb'
  }

  mysql_user { "${backupuser}@localhost":
    ensure        => $ensure,
    password_hash => mysql_password($backuppassword),
    require       => Class['mysql::server::root_password'],
  }

  if $include_triggers  {
    $privs = [ 'SELECT', 'RELOAD', 'LOCK TABLES', 'SHOW VIEW', 'PROCESS', 'TRIGGER' ]
  } else {
    $privs = [ 'SELECT', 'RELOAD', 'LOCK TABLES', 'SHOW VIEW', 'PROCESS' ]
  }

  mysql_grant { "${backupuser}@localhost/*.*":
    ensure     => $ensure,
    user       => "${backupuser}@localhost",
    table      => '*.*',
    privileges => $privs,
    require    => Mysql_user["${backupuser}@localhost"],
  }

  cron { 'mysql-backup':
    ensure  => $ensure,
    command => '/usr/local/sbin/mysqlbackup.sh 2>&1 | logger -t mysqlbackup # ',
    user    => 'root',
    hour    => $time[0],
    minute  => $time[1],
    require => [File['mysqlbackup.sh'], Package['bzip2']],
  }

  file { 'mysqlbackup.sh':
    ensure  => $ensure,
    path    => '/usr/local/sbin/mysqlbackup.sh',
    mode    => '0700',
    owner   => 'root',
    group   => $mysql::params::root_group,
    content => template($template_set),
  }

  file { 'mysqlbackup.cnf':
    ensure  => $ensure,
    path    => '/etc/mysql/mysqlbackup.cnf',
    mode    => '0700',
    owner   => 'root',
    group   => $mysql::params::root_group,
    content => "
[client]
password=${backuppassword}
user=${backupuser}
    "
  }

  file { 'mysqlbackup.cnf':
    ensure  => $ensure,
    path    => '/etc/mysql/mysqlbackup.cnf',
    mode    => '0700',
    owner   => 'root',
    group   => $mysql::params::root_group,
    content => "
[client]
password=${backuppassword}
user=${backupuser}
    "
  }

  file { 'mysqlbackupdir':
    ensure => 'directory',
    path   => $backupdir,
    mode   => $backupdirmode,
    owner  => $backupdirowner,
    group  => $backupdirgroup,
  }

}
