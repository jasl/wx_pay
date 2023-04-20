require 'digest/md5'

module WxPay
  module Sign

    SIGN_TYPE_MD5 = 'MD5'
    SIGN_TYPE_HMAC_SHA256 = 'HMAC-SHA256'

    def self.generate(params, sign_type = SIGN_TYPE_MD5)
      key = params.delete(:key)

      new_key = params["key"] #after
      key = params.delete("key") if params["key"] #after

      query = params.sort.map do |k, v|
        "#{k}=#{v}" if v.to_s != ''
      end.compact.join('&')

      string_sign_temp = "#{query}&key=#{key || new_key || WxPay.key}" #after

      if sign_type == SIGN_TYPE_MD5
        Digest::MD5.hexdigest(string_sign_temp).upcase
      elsif sign_type == SIGN_TYPE_HMAC_SHA256
        OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), key, string_sign_temp).upcase
      else
        warn("WxPay Warn: unknown sign_type : #{sign_type}")
      end
    end

    def self.verify?(params, options = {})
      params = params.dup
      params["appid"] = options[:appid] if options[:appid]
      params["mch_id"] = options[:mch_id]  if options[:mch_id]
      params["key"] = options[:key] if options[:key]

      sign = params.delete('sign') || params.delete(:sign)

      generate(params, options[:sign_type] || SIGN_TYPE_MD5) == sign
    end
  end
end
