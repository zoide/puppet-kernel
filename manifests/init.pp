# $Id: init.pp 4646 2011-09-01 09:01:59Z uwaechte $
# manage linux kernel modules
# made a module from:
# http://reductivelabs.com/trac/puppet/wiki/Recipes/KernelModules


define kernel::module::blacklist (
  $module="",
    $ensure="present"
  )
  {
    $module_real = $module ? {
        ""=> "${name}",
        default => "${module}",
      } 
    line{"modprobe.d-blacklist":
      file => "/etc/modprobe.d/blacklist-puppet.conf",
      line => "blacklist ${module_real}",
      ensure => "${ensure}",
        notify => Exec["update-initramfs::${kernelrelease}"],
    }
    exec{"update-initramfs::${kernelrelease}":
      command => "update-initramfs -k ${kernelrelease} -u",
        refreshonly => true,
    }
  }
  
  
define kernel::module (
    $module="",
    $ensure="present"
    ) {

  $module_real = $module ? {
    ""=> "${name}",
    default => "${module}",
  }

  $modulesfile = $operatingsystem ? { 
    "Debian" => "/etc/modules", 
    "Ubuntu" => "/etc/modules", 
    "Redhat" => "/etc/rc.modules" 
  }
  case $operatingsystem {
    "Redhat": { 
      file { "/etc/rc.modules": 
	ensure => file,
	mode => 755 
      } 
    }
  }
  case $ensure {
    "present": {
      exec { "insert_module_${module_real}":
	command => $operatingsystem ? {
	  "Debian" => "/bin/echo '${module_real}' >> '${modulesfile}'",
	    "Ubuntu" => "/bin/echo '${module_real}' >> '${modulesfile}'",
	    "Redhat" => "/bin/echo '/sbin/modprobe ${module_real}' >> '${modulesfile}' "
	},
		unless => "/bin/grep -qFx '${module_real}' '${modulesfile}'"
      }
      exec { "/sbin/modprobe -a ${module_real}": 
	unless => "/bin/grep -q '^${module_real} ' '/proc/modules'" 
      }
    }
    "absent": {
      exec { "/sbin/modprobe -r ${module_real}": 
	onlyif => "/bin/grep -q '^${module_real} ' '/proc/modules'" 
      }
      exec { "remove_module_${module_real}":
	command => $operatingsystem ? {
	  "Debian" => "/usr/bin/perl -ni -e 'print unless /^\\Q${module_real}\\E\$/' '${modulesfile}'",
	    "Ubuntu" => "/usr/bin/perl -ni -e 'print unless /^\\Q${module_real}\\E\$/' '${modulesfile}'",
	    "Redhat" => "/usr/bin/perl -ni -e 'print unless /^\\Q/sbin/modprobe ${module_real}\\E\$/' '${modulesfile}'"
	},
		onlyif => $operatingsystem ? {
		  "Debian" => "/bin/grep -qFx '${module_real}' '${modulesfile}'",
		  "Ubuntu" => "/bin/grep -qFx '${module_real}' '${modulesfile}'",
		  "Redhat" => "/bin/grep -q '^/sbin/modprobe ${module_real}' '${modulesfile}'"
		},
      }
    }
    default: { err ( "unknown ensure value ${ensure}" ) }
  }
}
