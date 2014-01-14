require 'boiler/package'

describe Boiler::Package do
  let(:path) { 'spec/support/valid-package' }

  before(:each) do
    @package = Boiler::Package.new path
    @package.copy_files_to_tmp
  end

  after(:each) do
    FileUtils.rm_rf '/tmp/boiler'
  end

  it "parses boiler.json" do
    @package.config.should include name: 'valid-package'
  end

  it "copies files to a temp directory" do
    @package.copy_files_to_tmp
    files = Dir.glob("#{@package.tmp}/*")
    files.should_not be_empty
    files.should_not include "#{@package.tmp}/ignore_me"
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
      "ln -sf /usr/local/boiler/valid-package/bin/hello /usr/local/bin/hello"
    ]
  end

  it "maps commands to preserve existing config files" do
    commands = @package.map_preserve_config_cmds
    commands.should be_a Array
  end

  it "maps unique env variables" do
    env_vars = @package.map_env_vars
    env_vars.should == [
      "VALID_PACKAGE_CONFIG_PATH=/boot/plugins/custom/valid-package/config",
      "VALID_PACKAGE_MANIFEST_PATH=/var/log/boiler/valid-package",
      "VALID_PACKAGE_MANIFEST=/var/log/boiler/valid-package/boiler.json",
      "VALID_PACKAGE_DOCS_PATH=/usr/docs/valid-package"
    ]
  end

  it "sets up post installer" do
    @package.setup_post_install
    doinst = "#{@package.tmp}/install/doinst.sh"
    File.exists?(doinst).should be_true
  end

  it "creates env file" do
    @package.setup_env
    env_file = "#{@package.tmp}/usr/local/boiler/valid-package/env"
    File.exists?(env_file).should be_true
  end

  it "runs tasks" do
    @package.run_tasks.should == [
      'test'
    ]
  end

  it "prefixes files" do
    @package.prefix_files
    old_bin = "#{@package.tmp}/bin"
    new_bin = "#{@package.tmp}/usr/local/boiler/valid-package/bin"

    File.exists?(old_bin).should be_false
    File.exists?(new_bin).should be_true
  end

  it "archives the tmp directory" do
    @package.archive
    @package.move_package_to_cwd
    pkg = 'valid-package-0.1.0-noarch-unraid.tgz'
    File.exists?(pkg).should be_true
    FileUtils.rm pkg
  end
end
