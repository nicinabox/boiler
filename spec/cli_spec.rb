require 'boiler/cli'

describe Boiler::CLI do
  before do
    FakeFS.activate!
  end

  after do
    FakeFS.deactivate!
    FakeFS::FileSystem.clear
    FileUtils.rm_rf '/tmp/boiler'
  end

  let(:cli) { Boiler::CLI.new }

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

  describe '#install' do
    before do
      FakeFS.deactivate!
      FakeFS::FileSystem.clear

      allow(Boiler::CLI).to receive(:get) {
        JSON.parse('
            {
              "id": 1,
              "name": "trolley",
              "url": "git://github.com/nicinabox/trolley.git",
              "installs": 159
              }
          ')
      }
    end

    it "won't install on non-unraid" do
      output = capture(:stdout) { cli.install('trolley') }
      output.should == <<-out.outdent
        => Downloading trolley
        => Packaging trolley
        => Can't install. Not an unRAID machine.
      out
    end
  end
end
