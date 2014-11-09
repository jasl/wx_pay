module WxPay
  module Utils
    def self.stringify_keys(hash)
      new_hash = {}
      hash.each do |key, value|
        new_hash[(key.to_s rescue key) || key] = value
      end
      new_hash
    end

    def self.make_payload(params)
      "<xml>#{params.map {|k, v| "<#{k}>#{v}</#{k}>"}.join}<sign>#{WxPay::Sign.generate(params)}</sign></xml>"
    end

    def self.invoke_remote(url, payload)
      Hash.from_xml(
        RestClient::Request.execute(
          {
            method: :post,
            url: url,
            payload: payload,
            headers: {content_type: 'application/xml'}
          }.merge(WxPay.extra_rest_client_options))
      )
    end
  end
end
