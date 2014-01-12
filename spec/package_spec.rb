require 'boiler/package'

describe Boiler::Package do
  before(:all) do
    @package = Boiler::Package.new 'spec/support/boiler-hello'
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
    commands = @package.preserve_config_cmds
    commands.should be_a Array
  end
end
