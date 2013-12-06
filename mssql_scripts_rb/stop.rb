require 'aws'
require 'socket'
require 'timeout'

STDOUT.sync = true

config_file = File.join(File.dirname(__FILE__), "config.yml")

AWS.config(YAML.load(File.read(config_file)))

ec2 = AWS::EC2.new(:ec2_endpoint => 'ec2.us-east-1.amazonaws.com')

ifile = File.join(ENV["WORKSPACE"],"test","instance")
id = File.read(ifile).strip

puts "terminating instance #{id}"

instance = ec2.instances[id]

if instance.exists? and instance.status==:running
	instance.terminate
else
	puts "well, really don't need to terminate it"
end
