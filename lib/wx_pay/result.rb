module WxPay
  class Result < ::Hash
    SUCCESS_FLAG = 'SUCCESS'.freeze

    def initialize(result)
      super nil # Or it will call `super result`

      result_hash = Hash.from_xml(result)
      self[:raw] = result_hash
      self[:raw_xml] = result
      if result_hash['xml'].class == Hash
        result_hash['xml'].each_pair do |k, v|
          self[k] = v
        end
      end
    end

    def success?
      self['return_code'] == SUCCESS_FLAG && self['result_code'] == SUCCESS_FLAG
    end
  end
end
