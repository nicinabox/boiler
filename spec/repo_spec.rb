require 'boiler/repo'

describe Boiler::Repo do
  let(:repo) {
    Boiler::Repo.new('git://github.com/nicinabox/trolley.git', 'trolley', '0.1.0')
  }
  let(:repo_latest) {
    Boiler::Repo.new('git://github.com/nicinabox/trolley.git', 'trolley')
  }

  it "clones a repo to a temp directory" do
    repo.clone
    File.exists?('/tmp/boiler/trolley').should be_true
  end

  it "checks out the latest tag" do
    repo_latest.clone
    repo_latest.version = '0.1.12'

    version = repo_latest.release
    version.should == '0.1.12'
  end

  it "checks out the specified tag" do
    repo.clone
    version = repo.release
    version.should == '0.1.0'
  end
end
