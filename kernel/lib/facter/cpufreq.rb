# $Id: cpufreq.rb 4464 2011-07-07 08:43:51Z uwaechte $
require 'facter'

# show information about cpus
file1="/sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors"
if File.exists?(file1)
  Facter.add("cpufreq_available_governors") do
    confine :kernel => :linux
    setcode do
      File.read(file1).chomp.rstrip
    end
  end
end

file2="/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
if File.exists?(file2)
  Facter.add("cpufreq_governor") do
    confine :kernel => :linux
    setcode do
      File.read(file2).chomp.strip
    end
  end
end