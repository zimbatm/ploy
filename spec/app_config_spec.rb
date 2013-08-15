require 'app/config'

describe App::Config do
  subject { App::Config.new }

  it { respond_to :database }
  it { respond_to :env }
end
