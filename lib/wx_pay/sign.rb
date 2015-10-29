require 'digest/md5'

module WxPay
  module Sign
    def self.generate(params)
      key = params.delete(:key)

      query = params.sort.map do |key, value|
        "#{key}=#{value}" if value != "" && !value.nil?
      end.compact.join('&')

      Digest::MD5.hexdigest("#{query}&key=#{key || WxPay.key}").upcase
    end

    def self.verify?(params)
      params = params.dup
      sign = params.delete('sign') || params.delete(:sign)

      generate(params) == sign
    end
  end
end
