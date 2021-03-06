require 'ploy/config'

module Ploy
  describe Config do
    context 'when loaded' do
      subject{ Ploy.config }

      its(:ploy_host) { should_not be_nil }
      its(:ploy_token) { should_not be_nil }

      its(:app_branch) { should == 'master' }
      its(:app_commit) { should match(/^[\da-f]+$/) }

      its(:app_root) { should == File.expand_path('../..', __FILE__) }
      its(:app_name) { should == 'zimbatm/ploy' }
    end
  end
end
