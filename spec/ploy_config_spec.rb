require File.expand_path('../boot', __FILE__)

require 'ploy/config'

module Ploy
  describe Config do
    context 'when loaded' do
      subject{ Ploy.config }

      its(:host) { should_not be_nil }
      its(:token) { should_not be_nil }

      its(:branch) { should == 'master' }
      its(:commit_id) { should match(/^[\da-f]+$/) }

      its(:app_root) { should == File.expand_path('../..', __FILE__) }
      its(:app_name) { should == 'pandastream/ploy' }
    end
  end
end
