require 'boiler/cli'

describe Boiler::CLI do
  before do
   FakeFS.activate!
  end

  after do
   FakeFS.deactivate!
   FakeFS::FileSystem.clear
  end

  let(:cli) { Boiler::CLI.new  }

  describe '#pack' do
    it 'packages a directory' do
      dir = '/home/test/valid-package'
      path = ''
      FileUtils.mkdir_p dir
      FakeFS::FileSystem.clone("spec/support/valid-package", dir)
      Boiler::Package.any_instance.stub(:archive)

      out = capture(:stdout) { path = cli.pack(dir) }
      path.should == 'valid-package-0.1.0-noarch-unraid.tgz'
    end
  end

  describe '#list' do
    it 'lists all installed packages' do
      FileUtils.mkdir_p '/var/log/boiler/valid-package'
      FakeFS::FileSystem.clone("spec/support/valid-package/boiler.json",
                               "/var/log/boiler/valid-package/boiler.json")

      out = capture(:stdout) { cli.list }
      out.should == "valid-package  0.1.0  A test package\n"
    end
  end

  describe '#info' do
    it 'shows message if no package' do
      out = capture(:stdout) { cli.info 'trolley' }
      out.should include 'No package named trolley'
    end

    it 'shows info for package' do
      FileUtils.mkdir_p '/var/log/boiler/valid-package'
      FakeFS::FileSystem.clone("spec/support/valid-package/boiler.json",
                               "/var/log/boiler/valid-package/boiler.json")

      out = capture(:stdout) { cli.info 'valid-package' }
      out.should == <<-output
Name         valid-package
Version      0.1.0
Description  A test package
      output
    end
  end
end
