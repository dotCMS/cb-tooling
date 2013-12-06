# configuration in amazon linux:
# sudo apt-get install libxml2-devel gcc ruby19-devel ruby19
# sudo gem install aws-sdk

require 'aws'
require 'socket'
require 'timeout'

STDOUT.sync = true

config_file = File.join(File.dirname(__FILE__), "config.yml")

AWS.config(YAML.load(File.read(config_file)))

ec2 = AWS::EC2.new(:ec2_endpoint => 'ec2.us-east-1.amazonaws.com')

instance = ec2.instances.create(:image_id=>'ami-9cb6d6f5',:instance_type=>'c1.medium',
                                :security_groups=>['mssql open'])

instance.tags.Name='jenkins_mssql'

while instance.status != :running
    puts "instance #{instance.id} not running... will ask again in 20s"
    sleep(20)
end

puts "instance #{instance.id} has address #{instance.ip_address}"

notopen=true

while notopen
    begin
        Timeout::timeout(1) do
            s = TCPSocket.new(instance.ip_address, 1433)
            s.close
            notopen=false
        end
    rescue 
        puts "instance #{instance.id} not listening to #{instance.ip_address}:1433... will try again in 20s"
        sleep(20)
    end
end

jdbcurl="jdbc:jtds:sqlserver://#{instance.ip_address}:1433/#{ARGV[0]}"

puts "setting jdbc url: #{jdbcurl} into test/ROOT.xml"

# update ROOT.xml to point to the new instance
rootpath = File.join(ENV["WORKSPACE"],"test","ROOT.xml")
rootxml = File.read(rootpath)
newroot = rootxml.gsub(/url="[^"]+"/, "url=\"#{jdbcurl}\"")
File.open(rootpath, "w") { |io| io.write(newroot) }

# update test/build.properties to have the correct db.url
propspath = File.join(ENV["WORKSPACE"],"test","build.properties")
props = File.read(propspath)
newprops = props.gsub(/^db\.url=.+$/,"db.url=#{jdbcurl}")+"\ndb.admin.url=\njdbc:jtds:sqlserver://#{instance.ip_address}:1433/master"
File.open(propspath, "w") { |io| io.write(newprops) }

# store in test/instance the identifier of the instance for later termination
ifile = File.join(ENV["WORKSPACE"],"test","instance")
File.open(ifile, "w") { |io| io.write(instance.id) }

puts "Done!"