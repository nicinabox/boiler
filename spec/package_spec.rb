require 'boiler/package'

describe Boiler::Package do
  before(:all) do
    @package = Boiler::Package.new 'spec/support/boiler-test'
  end

  it "parses boiler.json" do
    @package.config.should include name: 'boiler-test'
  end

  it "copies files to a temp directory" do
    @package.copy_files_to_tmp
    files = Dir.glob("#{@package.tmp}/*")
    files.should_not be_empty
  end
end
