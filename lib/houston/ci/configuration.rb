module Houston::Ci
  class Configuration

    def ci_server(adapter, &block)
      raise ArgumentError, "#{adapter.inspect} is not a CIServer: known CIServer adapters are: #{Houston::Adapters::CIServer.adapters.map { |name| ":#{name.downcase}" }.join(", ")}" unless Houston::Adapters::CIServer.adapter?(adapter)
      raise ArgumentError, "ci_server should be invoked with a block" unless block_given?

      configuration = HashDsl.hash_from_block(block)

      @ci_server_configuration ||= {}
      @ci_server_configuration[adapter] = configuration
    end

    def ci_server_configuration(adapter)
      raise ArgumentError, "#{adapter.inspect} is not a CIServer: known CIServer adapters are: #{Houston::Adapters::CIServer.adapters.map { |name| ":#{name.downcase}" }.join(", ")}" unless Houston::Adapters::CIServer.adapter?(adapter)

      @ci_server_configuration ||= {}
      @ci_server_configuration[adapter] || {}
    end

  end
end
