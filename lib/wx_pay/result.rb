module WxPay
  class Result < ::Hash
    SUCCESS_FLAG = 'SUCCESS'.freeze

    def initialize(result)
      super

      if result['xml'].class == Hash
        result['xml'].each_pair do |k, v|
          self[k] = v
        end
      end
    end

    def success?
      self['return_code'] == SUCCESS_FLAG && self['result_code'] == SUCCESS_FLAG
    end
  end
end
