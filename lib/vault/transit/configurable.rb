module Vault
  module Transit
    module Configurable
      include Vault::Configurable

      # Whether the connection to Vault is enabled. The default value is `false`,
      # which means vault-rails will perform in-memory encryption/decryption and
      # not attempt to talk to a real Vault server. This is useful for
      # development and testing.
      #
      # @return [true, false]
      def enabled?
        if !defined?(@enabled) || @enabled.nil?
          return false
        end
        return @enabled
      end

      # Sets whether Vault is enabled. Users can set this in an initializer
      # depending on their Rails environment.
      #
      # @example
      #   Vault.configure do |vault|
      #     vault.enabled = Rails.env.production?
      #   end
      #
      # @return [true, false]
      def enabled=(val)
        @enabled = !!val
      end

      # Gets the number of retry attempts.
      #
      # @return [Fixnum]
      def retry_attempts
        @retry_attempts ||= 0
      end

      # Sets the number of retry attempts. Please see the Vault documentation
      # for more information.
      #
      # @param [Fixnum] val
      def retry_attempts=(val)
        @retry_attempts = val
      end

      # Gets the number of retry attempts.
      #
      # @return [Fixnum]
      def retry_base
        @retry_base ||= Vault::Defaults::RETRY_BASE
      end

      # Sets the retry interval. Please see the Vault documentation for more
      # information.
      #
      # @param [Fixnum] val
      def retry_base=(val)
        @retry_base = val
      end

      # Gets the retry maximum wait.
      #
      # @return [Fixnum]
      def retry_max_wait
        @retry_max_wait ||= Vault::Defaults::RETRY_MAX_WAIT
      end

      # Sets the naximum amount of time for a single retry. Please see the Vault
      # documentation for more information.
      #
      # @param [Fixnum] val
      def retry_max_wait=(val)
        @retry_max_wait = val
      end
    end
  end
end
