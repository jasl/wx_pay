require 'digest/md5'

module WxPay
  module Sign
    def self.generate(params)
      key = params.delete(:key)

      query = params.sort.map do |k, v|
        "#{k}=#{v}" if v.to_s != ''
      end.compact.join('&')

      Digest::MD5.hexdigest("#{query}&key=#{key || WxPay.key}").upcase
    end

    def self.verify?(params, options = {})
      params = params.dup
      params = params.merge(options)

      sign = params.delete('sign') || params.delete(:sign)

      generate(params) == sign
    end
  end
end
