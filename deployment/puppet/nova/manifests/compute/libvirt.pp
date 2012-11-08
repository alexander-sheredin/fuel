class nova::compute::libvirt (
  $libvirt_type = 'kvm',
  $vncserver_listen = '127.0.0.1'
) {

  include nova::params

  if $::osfamily == 'RedHat' {

#    yumrepo {'CentOS-Base':
#      name     => 'updates',
#      priority => 10,
#      before   => [Package['libvirt']]
#    }->
    

#    package { 'qemu':
#      ensure => present,
#    }
 
    exec { 'symlink-qemu-kvm': 
      command => "/bin/ln -sf /usr/libexec/qemu-kvm /usr/bin/qemu-system-x86_64",
    } 
                   

    package {'dnsmasq-utils':
      ensure => present
    }

    package { 'avahi':
      ensure => present;
    } ->

    service { 'messagebus':
      ensure => running,
      require => Package['avahi'];
    } ->

    service { 'avahi-daemon':
      ensure  => running,
      require => Package['avahi'];
    }

    Service['avahi-daemon'] -> Service['libvirt']

  }

  Service['libvirt'] -> Service['nova-compute']

  if (($::nova::params::compute_package_name) and ($::nova::params::old_style_nova_compute_conf)) {
    package { "nova-compute-${libvirt_type}":
      ensure => present,
      before => Package['nova-compute'],
    }
  }

  package { 'libvirt':
    name   => $::nova::params::libvirt_package_name,
    ensure => present,
  }

  service { 'libvirt' :
    name     => $::nova::params::libvirt_service_name,
    ensure   => running,
    provider => $::nova::params::special_service_provider,
    require  => Package['libvirt'],
  }

  nova_config { 'libvirt_type': value => $libvirt_type }
  nova_config { 'connection_type': value => 'libvirt' }
  nova_config { 'vncserver_listen': value => $vncserver_listen }
}
