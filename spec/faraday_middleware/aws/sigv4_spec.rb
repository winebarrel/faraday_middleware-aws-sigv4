require "spec_helper"

RSpec.describe FaradayMiddleware::Aws::Sigv4 do
  it "has a version number" do
    expect(FaradayMiddleware::Aws::Sigv4::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(true)
  end
end
