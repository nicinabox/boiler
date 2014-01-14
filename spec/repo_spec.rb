require 'boiler/repo'

describe Boiler::Repo do
  let(:repo) {
    Boiler::Repo.new('git://github.com/nicinabox/trolley.git', 'trolley', '0.1.0')
  }
  let(:repo_latest) {
    Boiler::Repo.new('git://github.com/nicinabox/trolley.git', 'trolley')
  }
  let(:repo_no_name) {
    Boiler::Repo.new('git://github.com/nicinabox/trolley.git')
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

  it "creates a repo from just a url" do
    repo_no_name.clone
    repo_no_name.name.should == 'trolley'
  end

  describe '#validate' do
    let(:invalid_repo) { Boiler::Repo.new('http://github.com/nope/nope.git') }

    it "must use git:// protocol" do
      invalid_repo.validate.should == 'Url must use git:// protocol'
    end

    it "must be a public repo" do
      Boiler::Repo.any_instance.stub(:convert_to_git_protocol).and_return(true)
      Boiler::Repo.any_instance.stub(:public_repo?).and_return(false)

      invalid_repo.validate.should == 'Package must be a public repo'
    end

    it "must include a manifest" do
      Boiler::Repo.any_instance.stub(:convert_to_git_protocol).and_return(true)
      Boiler::Repo.any_instance.stub(:public_repo?).and_return(true)
      Boiler::Repo.any_instance.stub(:clone)
      invalid_repo.path = '/tmp'

      invalid_repo.validate.should == 'Package is missing boiler.json'
    end

    it "must include required keys in manifest" do
      Boiler::Repo.any_instance.stub(:public_repo?).and_return(true)
      Boiler::Repo.any_instance.stub(:convert_to_git_protocol).and_return(true)
      Boiler::Repo.any_instance.stub(:clone)
      Boiler::Manifest.any_instance.stub(:exists?).and_return(true)

      invalid_repo.path = 'spec/support/invalid-package'
      invalid_repo.manifest.path = invalid_repo.path

      invalid_repo.validate.should == 'boiler.json requires name'
    end
  end
end
