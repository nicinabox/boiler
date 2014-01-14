require 'boiler/manifest'

describe Boiler::Manifest do
  let(:path) { 'spec/support/valid-package' }
  let(:manifest) { Boiler::Manifest.new(path) }

  describe 'defaults' do
    it "returns simple defaults" do
      manifest.simple_defaults.should == {
        name: 'valid-package',
        version: '0.1.0',
        authors: [],
        license: 'MIT',
        dependencies: {},
        post_install: []
      }
    end
  end

  describe '#exists?' do
    it "checks to see if a manifest exists" do
      manifest.exists?.should be_true
    end
  end

  describe '#to_json' do
    it "returns the manifest as json" do
      target_json = JSON.parse(File.read("#{path}/boiler.json"),
                               :symbolize_names => true)
      manifest.to_json.should == target_json
    end
  end

end
