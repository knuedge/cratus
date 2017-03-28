require 'spec_helper'

describe Cratus::Config do
  let(:basic_config) do
    Cratus::Config.new
  end

  it 'provides a Hash of default options' do
    expect(basic_config.defaults.class).to eq(Hash)
  end
end
