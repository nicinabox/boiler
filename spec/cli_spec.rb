require 'boiler/cli'

describe Boiler::CLI do
  let(:cli) { Boiler::CLI.new  }

  describe '#list' do
    it 'lists all installed packages' do
      Boiler::Base.any_instance.stub(:installed)
                               .and_return(['spec/support/boiler-hello'])

      out = capture(:stdout) { cli.list }
      out.should == "boiler-hello  0.1.0  A test package\n"
    end
  end

  describe '#info' do
    it 'shows message if no package' do
      out = capture(:stdout) { cli.info 'trolley' }
      out.should include 'No package named trolley'
    end

    it 'shows info for package' do
      Boiler::Base.any_instance.stub(:installed)
                               .and_return(['spec/support/boiler-hello'])

      out = capture(:stdout) { cli.info 'boiler-hello' }
      out.should == <<-output
Name         boiler-hello
Version      0.1.0
Description  A test package
      output
    end
  end
end
