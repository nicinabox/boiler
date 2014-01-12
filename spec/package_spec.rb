require 'boiler/package'

describe Boiler::Package do
  before(:each) do
    @package = Boiler::Package.new 'spec/support/boiler-hello'
    @package.copy_files_to_tmp
  end

  after(:each) do
    FileUtils.rm_rf '/tmp/boiler'
  end

  it "parses boiler.json" do
    @package.config.should include name: 'boiler-hello'
  end

  it "copies files to a temp directory" do
    @package.copy_files_to_tmp
    files = Dir.glob("#{@package.tmp}/*")
    files.should_not be_empty
  end

  it "maps dependencies" do
    deps = @package.map_dependencies_with_trolley
    deps.should == [
      "trolley install fake1 1.0.0",
      "trolley install http://example.com/fake2.tgz"
    ]
  end

  it "maps symlinks" do
    symlinks = @package.map_symlinks
    symlinks.should == [
      "ln -sf /usr/local/boiler/boiler-hello/hello /usr/local/bin/hello"
    ]
  end

  it "maps commands to preserve existing config files" do
    commands = @package.map_preserve_config_cmds
    commands.should be_a Array
  end

  it "maps unique env variables" do
    env_vars = @package.map_env_vars
    env_vars.should == [
      "BOILER_HELLO_CONFIG_PATH=/boot/plugins/custom/boiler-hello/config"
    ]
  end

  it "sets up post installer" do
    @package.setup_post_install
    doinst = "#{@package.tmp}/install/doinst.sh"
    File.exists?(doinst).should be_true
  end

  it "creates env file" do
    @package.setup_env
    env_file = "#{@package.tmp}/usr/local/boiler/boiler-hello/env"
    File.exists?(env_file).should be_true
  end

  it "prefixes files" do
    @package.prefix_files
    old_bin = "#{@package.tmp}/bin"
    new_bin = "#{@package.tmp}/usr/local/boiler/boiler-hello/bin"
    puts `ls #{@package.tmp}/usr/local/boiler/boiler-hello`

    File.exists?(old_bin).should be_false
    File.exists?(new_bin).should be_true
  end
end
