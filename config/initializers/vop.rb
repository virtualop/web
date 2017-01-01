require 'pathname'

# vop_lib_path = File.join(Pathname.new(File.join(File.dirname(__FILE__), '..', '..', '..')).realpath, 'vop', 'lib')
# puts "vop_lib_path : #{vop_lib_path}"
#
# $: << vop_lib_path
#
# require 'vop.rb'

$vop = Vop::Vop.new()
