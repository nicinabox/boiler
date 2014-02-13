require 'boiler/manifest'
require 'boiler/convert_plg'

describe Boiler::ConvertPlg do

  before(:each) do
    FakeFS.activate!
    support = 'spec/support'
    plg = File.join support, "transmission_unplugged.plg"
    FakeFS::FileSystem.clone support, "/#{support}"
    @package = Boiler::ConvertPlg.new plg
  end

  after(:each) do
    FakeFS.deactivate!
    FakeFS::FileSystem.clear
  end

  describe 'mapping' do
    it "maps dependencies" do
      deps = @package.map_dependencies
      deps.should == [
        'http://slackware.cs.utah.edu/pub/slackware/slackware-13.37/slackware/n/curl-7.21.4-i486-1.txz',
        'http://repository.slacky.eu/slackware-13.37/libraries/libevent/2.0.11/libevent-2.0.11-i486-1sl.txz',
        'http://slackware.cs.utah.edu/pub/slackware/slackware-13.37/slackware/l/libidn-1.19-i486-1.txz',
        'http://slackware.oregonstate.edu//slackware-13.1/slackware/n/openldap-client-2.4.21-i486-1.txz',
        'https://dl.dropbox.com/u/1574928/Unraid%20Plugins/transmission-2.76-i686-1PTr.txz'
      ]
    end

    it "maps assets to download" do
      assets = @package.map_assets
      assets.should == [
        {:"/spec/support/transmission_unplugged/boot/config/plugins/transmission/transmission.png"=>
         "https://github.com/downloads/Influencer/UNplugged/transmission.png"},
        {:"/spec/support/transmission_unplugged/boot/config/plugins/images/device_status.png"=>
         "https://github.com/downloads/Influencer/UNplugged/device_status.png"},
        {:"/spec/support/transmission_unplugged/boot/config/plugins/images/new_config.png"=>
         "https://github.com/downloads/Influencer/UNplugged/new_config.png"},
        {:"/spec/support/transmission_unplugged/boot/config/plugins/images/information.png"=>
         "https://github.com/downloads/Influencer/UNplugged/information.png"}
      ]
    end

    it "maps files to create" do
      files = @package.map_files
      paths = files.collect { |f| f.keys.first.to_s }.flatten
      paths.should == [
        '/tmp/transmission-cleanup',
        '/boot/config/plugins/transmission/settings.json',
        '/boot/config/plugins/transmission/transmission.cfg',
        '/usr/local/emhttp/plugins/webGui/unplugged.page',
        '/etc/rc.d/rc.transmission',
        '/usr/local/emhttp/plugins/transmission/transmission.page',
        '/usr/local/emhttp/plugins/transmission/transmission.php',
        '/usr/local/emhttp/plugins/transmission/event/disks_mounted',
        '/usr/local/emhttp/plugins/transmission/event/unmounting_disks',
        '/tmp/transmission-install',
        '/var/log/plugins/transmission'
      ]
    end

    it "maps scripts for doinst.sh" do
      scripts = @package.map_scripts
      scripts.should == [
        '/tmp/transmission-cleanup',
        '/tmp/transmission-install'
      ]
    end
  end

  it 'creates a new working directory' do
    capture(:stdout) { @package.copy_files_to_tmp }
    File.exists?('spec/support/transmission_unplugged').should be_true
  end

  it 'creates individual files' do
    capture(:stdout) { @package.copy_files_to_tmp }

    Dir.glob(File.join('spec/support/transmission_unplugged', '**', '*')).select { |file|
      File.file?(file)
    }.count.should == 10
  end

  it 'adds dependencies to config' do
    capture(:stdout) { @package.add_dependencies_to_manifest }
    @package.config[:dependencies].should == {
      :"curl-7.21.4-i486-1"=>"http://slackware.cs.utah.edu/pub/slackware/slackware-13.37/slackware/n/curl-7.21.4-i486-1.txz",
      :"libevent-2.0.11-i486-1sl"=>"http://repository.slacky.eu/slackware-13.37/libraries/libevent/2.0.11/libevent-2.0.11-i486-1sl.txz",
      :"libidn-1.19-i486-1"=>"http://slackware.cs.utah.edu/pub/slackware/slackware-13.37/slackware/l/libidn-1.19-i486-1.txz",
      :"openldap-client-2.4.21-i486-1"=>"http://slackware.oregonstate.edu//slackware-13.1/slackware/n/openldap-client-2.4.21-i486-1.txz",
      :"transmission-2.76-i686-1PTr"=>"https://dl.dropbox.com/u/1574928/Unraid%20Plugins/transmission-2.76-i686-1PTr.txz"
    }
  end

  it 'creates install/doinst.sh' do
    capture(:stdout) {
      @package.copy_files_to_tmp
      @package.update_doinst
    }
    file = File.read 'spec/support/transmission_unplugged/install/doinst.sh'
    file.should == <<-CONTENTS
/tmp/transmission-cleanup
/tmp/transmission-install
    CONTENTS
  end

  it 'creates the manifest' do
    capture(:stdout) { @package.create_manifest }
    File.exists?('spec/support/transmission_unplugged/boiler.json').should be_true
  end
end
