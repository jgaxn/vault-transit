require "spec_helper"

RSpec.describe Vault::Transit do
  it "has a version number" do
    expect(Vault::Transit::VERSION).not_to be nil
  end

  before(:all) do
    ::Vault::Transit.sys.mount("transit", :transit) unless ::Vault::Transit.sys.mounts.has_key? :transit
    ::Vault::Transit.logical.write("transit/keys/test_key")
    ::Vault::Transit.enabled = true
  end

  it "encrypts" do
    ciphertext = ::Vault::Transit.encrypt("test_key", "plaintext")
    expect(ciphertext.start_with?("vault:v")).to be true
  end

  it "decrypts" do
    ciphertext = ::Vault::Transit.encrypt("test_key", "plaintext")
    decrypted_ciphertext = ::Vault::Transit.decrypt("test_key", ciphertext)
    expect(decrypted_ciphertext).to eq("plaintext")
  end

  it "rotates and rewraps" do
    original_ciphertext = ::Vault::Transit.encrypt("test_key", "plaintext")
    ::Vault::Transit.rotate("test_key")
    /vault:v(?<original_key_version>[[:digit:]]+).+/ =~ original_ciphertext
    rewrapped_ciphertext = ::Vault::Transit.rewrap("test_key", original_ciphertext)
    /vault:v(?<rewrapped_key_version>[[:digit:]]+).+/ =~ rewrapped_ciphertext
    expect(rewrapped_ciphertext).to_not eq(original_ciphertext)
    expect(rewrapped_key_version.to_i).to eq(original_key_version.to_i + 1)
  end
end
