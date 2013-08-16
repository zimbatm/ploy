require 'ploy/shared'
require 'tempfile'

describe Ploy::Shared do
  subject { Class.new{ include Ploy::Shared; self}.new }

  describe ".gen_deploy" do
    let(:tmp_file) { Tempfile.open('w') }
    after do
      tmp_file.unlink
    end

    it 'generates a valid deploy' do
      pending("FIXME")
      out = subject.gen_deploy(1337, "http://s3.amazonaws.com/releases/foo.tar.gz", {some: "config"}) 

      tmp_file.write out
      tmp_file.close

      shell_out = `bash "#{tmp_file.path}" test 2>&1`.strip
      exit_status = $?.exitstatus

      expect(shell_out).to eq("")
      expect(exit_status).to eq(0)
    end
  end

  it 'gives access to a bootstrap dir' do
    expect( File.directory?(subject.bootstrap_dir) ).to be_true
  end
end
