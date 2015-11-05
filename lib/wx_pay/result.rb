module WxPay
  class Result < ::Hash
    SUCCESS_FLAG = 'SUCCESS'.freeze

    def self.[] result
      hash = self.new

      if result['xml'].class == Hash
        result['xml'].each_pair do |k, v|
          hash[k] = v
        end
      end

      hash
    end

    def success?
      self['return_code'] == SUCCESS_FLAG && self['result_code'] == SUCCESS_FLAG
    end
  end
end
