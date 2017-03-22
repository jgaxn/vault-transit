
require "base64"
require "vault"
require "vault/transit/configurable"
require "vault/transit/version"

#require_relative "transit/configurable"

module Vault
  module Transit

    # The default encoding.
    #
    # @return [String]
    DEFAULT_ENCODING = "utf-8".freeze

    # The warning string to print when running in development mode.
    DEV_WARNING = "[vault-transit] Using in-memory cipher - this is not secure " \
      "and should never be used in production-like environments!".freeze

    class << self
      attr_reader :client

      def setup!
        ::Vault.setup!
        @client = ::Vault.client
        @client.class.instance_eval do
          include ::Vault::Transit::Configurable
        end

        self
      end

      # Delegate all methods to the client object, essentially making the module
      # object behave like a {Vault::Client}.
      def method_missing(m, *args, &block)
        if client.respond_to?(m)
          client.public_send(m, *args, &block)
        else
          super
        end
      end

      # Delegating `respond_to` to the {Vault::Client}.
      def respond_to_missing?(m, include_private = false)
        client.respond_to?(m, include_private) || super
      end

      # Decrypt the given ciphertext data using the provided key.
      #
      # @param [String] key
      #   the key to decrypt at
      # @param [String] ciphertext
      #   the ciphertext to decrypt
      # @param [Vault::Client] client
      #   the Vault client to use
      #
      # @return [String]
      #   the decrypted plaintext text
      def decrypt(key, ciphertext, client = self.client)
        if ciphertext.nil? || ciphertext.empty?
          return ciphertext
        end

        key  = key.to_s if !key.is_a?(String)

        with_retries do
          if self.enabled?
            result = self.vault_decrypt(key, ciphertext, client)
          else
            result = self.memory_decrypt(key, ciphertext, client)
          end

          return self.force_encoding(result)
        end
      end

      # Encrypt the given plaintext data using the provided key.
      #
      # @param [String] key
      #   the key to encrypt at
      # @param [String] plaintext
      #   the plaintext to encrypt
      # @param [Vault::Client] client
      #   the Vault client to use
      #
      # @return [String]
      #   the encrypted cipher text
      def encrypt(key, plaintext, client = self.client)
        if plaintext.nil? || plaintext.empty?
          return plaintext
        end

        key  = key.to_s if !key.is_a?(String)

        with_retries do
          if self.enabled?
            result = self.vault_encrypt(key, plaintext, client)
          else
            result = self.memory_encrypt(key, plaintext, client)
          end

          return self.force_encoding(result)
        end
      end

      # Rewrap the given ciphertext data using the provided key.
      #
      # @param [String] key
      #   the key to rewrap at
      # @param [String] ciphertext
      #   the ciphertext to rewrap
      # @param [Vault::Client] client
      #   the Vault client to use
      #
      # @return [String]
      #   the rewrapped ciphertext text
      def rewrap(key, ciphertext, client = self.client)
        if ciphertext.nil? || ciphertext.empty?
          return ciphertext
        end

        key  = key.to_s unless key.is_a?(String)
        route  = File.join("transit", "rewrap", key)

        with_retries do
          if self.enabled?
            secret = client.logical.write(route,
              ciphertext: ciphertext,
            )
            result = secret.data[:ciphertext]
          else
            result = ciphertext
          end
          return self.force_encoding(result)
        end
      end

      # Rotate the key to a new version
      #
      # @param [String] key
      #   the key to rotate
      # @param [Vault::Client] client
      #   the Vault client to use
      #
      def rotate(key, client = self.client)
        key  = key.to_s unless key.is_a?(String)
        route  = File.join("transit", "keys", key, "rotate")

        with_retries do
          if self.enabled?
            client.logical.write(route)
          end
        end
      end

      # Set the minimum decryption version a using the provided key.
      #
      # @param [String] key
      #   the key to configure
      # @param [int] min_decryption_version
      #   the new minimum decryption version
      # @param [Vault::Client] client
      #   the Vault client to use
      #
      def set_min_decryption_version(key, min_decryption_version, client = self.client)
        key  = key.to_s unless key.is_a?(String)

        with_retries do
          if self.enabled?
            route = File.join("transit", "keys", key, "config")
            client.logical.write(route,
              min_decryption_version: min_decryption_version,
            )
          end
        end
      end

    protected

      # Perform in-memory decryption. This is useful for testing and development.
      def memory_decrypt(key, ciphertext, client)
        log_warning(DEV_WARNING)

        return nil if ciphertext.nil?

        cipher = OpenSSL::Cipher::AES.new(128, :CBC)
        cipher.decrypt
        cipher.key = memory_key_for(key)
        ciphertext = ciphertext.gsub("vault:v0:", "")
        return cipher.update(Base64.strict_decode64(ciphertext)) + cipher.final
      end

      # Perform in-memory encryption. This is useful for testing and development.
      def memory_encrypt(key, plaintext, client)
        log_warning(DEV_WARNING)

        return nil if plaintext.nil?

        cipher = OpenSSL::Cipher::AES.new(128, :CBC)
        cipher.encrypt
        cipher.key = memory_key_for(key)
        return "vault:v0:" + Base64.strict_encode64(cipher.update(plaintext) + cipher.final)
      end

      # Perform decryption using Vault. This will raise exceptions if Vault is
      # unavailable.
      def vault_decrypt(key, ciphertext, client)
        return nil if ciphertext.nil?

        route  = File.join("transit", "decrypt", key)
        secret = client.logical.write(route, ciphertext: ciphertext)
        return Base64.strict_decode64(secret.data[:plaintext])
      end

      # Perform encryption using Vault. This will raise exceptions if Vault is
      # unavailable.
      def vault_encrypt(key, plaintext, client)
        return nil if plaintext.nil?

        route  = File.join("transit", "encrypt", key)
        secret = client.logical.write(route,
          plaintext: Base64.strict_encode64(plaintext),
        )
        return secret.data[:ciphertext]
      end

      # The symmetric key for the given params.
      # @return [String]
      def memory_key_for(key)
        return Base64.strict_encode64(key.ljust(32, "x"))
      end

      # Forces the encoding into the default Rails encoding and returns the
      # newly encoded string.
      # @return [String]
      def force_encoding(str)
        encoding = ::Rails.application.config.encoding if defined? ::Rails
        encoding ||= DEFAULT_ENCODING
        str.force_encoding(encoding).encode(encoding)
      end

    private

      def with_retries(client = self.client, &block)
        exceptions = [Vault::HTTPConnectionError, Vault::HTTPServerError]
        options = {
          attempts: self.retry_attempts,
          base:     self.retry_base,
          max_wait: self.retry_max_wait,
        }

        client.with_retries(*exceptions, options) do |i, e|
          if !e.nil?
            log_warning "[vault-transit] (#{i}) An error occurred when trying to " \
              "communicate with Vault: #{e.message}"
          end

          yield
        end
      end

      def log_warning(msg)
        if defined?(::Rails) && ::Rails.logger != nil
          ::Rails.logger.warn { msg }
        end
      end
    end
  end
end

::Vault::Transit.setup!
