require 'boiler/cli'

describe Boiler::CLI do
  let(:cli) { Boiler::CLI.new  }

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
Name     boiler-hello
Version  0.1.0
      output
    end
  end
end
