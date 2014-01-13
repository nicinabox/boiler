require 'boiler/updater'

describe Boiler::Updater do
  before(:each) do
    Boiler::Updater.any_instance.stub(:update_available?).and_return(true)
    @updater = Boiler::Updater.new
  end

  it "#update_available?" do
    @updater.update_available?.should be_true
  end
end
