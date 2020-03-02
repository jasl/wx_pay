# WxPay

A simple Wechat pay ruby gem, without unnecessary magic or wrapper.
copied from [alipay](https://github.com/chloerei/alipay) .

Please read official document first: https://pay.weixin.qq.com/wiki/doc/api/index.html.

[![Build Status](https://travis-ci.org/jasl/wx_pay.svg?branch=master)](https://travis-ci.org/jasl/wx_pay)

## Installation

Add this line to your Gemfile:

```ruby
gem 'wx_pay'
```

or development version

```ruby
gem 'wx_pay', :github => 'jasl/wx_pay'
```

And then execute:

```sh
$ bundle
```

## Usage

### Config

Create `config/initializers/wx_pay.rb` and put following configurations into it.

```ruby
# required
WxPay.appid = 'YOUR_APPID'
WxPay.key = 'YOUR_KEY'
WxPay.mch_id = 'YOUR_MCH_ID' # required type is String, otherwise there will be cases where JS_PAY can pay but the APP cannot pay
WxPay.debug_mode = true # default is `true`
WxPay.sandbox_mode = false # default is `false`

# cert, see https://pay.weixin.qq.com/wiki/doc/api/app/app.php?chapter=4_3
# using PCKS12
WxPay.set_apiclient_by_pkcs12(File.read(pkcs12_filepath), pass)

# if you want to use `generate_authorize_req` and `authenticate`
WxPay.appsecret = 'YOUR_SECRET' 

# optional - configurations for RestClient timeout, etc.
WxPay.extra_rest_client_options = {timeout: 2, open_timeout: 3}
```

If you need to use sandbox mode.

```ruby
WxPay.appid = 'YOUR_APPID'
WxPay.mch_id = 'YOUR_MCH_ID' # required type is String, otherwise there will be cases where JS_PAY can pay but the APP cannot pay
WxPay.debug_mode = true # default is `true`
WxPay.sandbox_mode = true # default is `false`
result = WxPay::Service.get_sandbox_signkey
WxPay.key = result['sandbox_signkey']

```

Note: You should create your APIKEY (Link to [微信商户平台](https://pay.weixin.qq.com/index.php/home/login)) first if you haven't, and pay attention that **the length of the APIKEY should be 32**.

### APIs

**Check official document for detailed request params and return fields**

#### unifiedorder

WxPay supports MWEB, JSAPI, NATIVE and APP.

```ruby
# required fields
params = {
  body: '测试商品',
  out_trade_no: 'test003',
  total_fee: 1,
  spbill_create_ip: '127.0.0.1',
  notify_url: 'http://making.dev/notify',
  trade_type: 'JSAPI', # could be "MWEB", ""JSAPI", "NATIVE" or "APP",
  openid: 'OPENID' # required when trade_type is `JSAPI`
}
```

`WxPay::Service.invoke_unifiedorder params` will create an payment request and return a WxPay::Result instance(subclass of Hash) contains parsed result.

If your trade type is "MWEB", the result would be like this.

```ruby
r = WxPay::Service.invoke_unifiedorder params
# => {
#      "return_code"=>"SUCCESS",
#      "return_msg"=>"OK",
#      "appid"=>"YOUR APPID",
#      "mch_id"=>"YOUR MCH_ID",
#      "nonce_str"=>"8RN7YfTZ3OUgWX5e",
#      "sign"=>"623AE90C9679729DDD7407DC7A1151B2",
#      "result_code"=>"SUCCESS",
#      "prepay_id"=>"wx2014111104255143b7605afb0314593866",
#      "mweb_url"=>"https://wx.tenpay.com/cgi-bin/mmpayweb-bin/checkmweb?prepay_id=wx2016121516420242444321ca0631331346&package=1405458241",
#      "trade_type"=>"MWEB"
#    }
```

If your trade type is "JSAPI", the result would be like this.

```ruby
r = WxPay::Service.invoke_unifiedorder params
# => {
#      "return_code"=>"SUCCESS",
#      "return_msg"=>"OK",
#      "appid"=>"YOUR APPID",
#      "mch_id"=>"YOUR MCH_ID",
#      "nonce_str"=>"8RN7YfTZ3OUgWX5e",
#      "sign"=>"623AE90C9679729DDD7407DC7A1151B2",
#      "result_code"=>"SUCCESS",
#      "prepay_id"=>"wx2014111104255143b7605afb0314593866",
#      "trade_type"=>"JSAPI"
#    }
```

> "JSAPI" requires openid in params,
in most cases I suggest you using [omniauth](https://github.com/omniauth/omniauth) with [omniauth-wechat-oauth2](https://github.com/skinnyworm/omniauth-wechat-oauth2) to resolve this,
but `wx_pay` provides `generate_authorize_url` and `authenticate` to help you get Wechat authorization in simple case.

If your trade type is "NATIVE", the result would be like this.

```ruby
r = WxPay::Service.invoke_unifiedorder params
# => {
#      "return_code"=>"SUCCESS",
#      "return_msg"=>"OK",
#      "appid"=>"YOUR APPID",
#      "mch_id"=>"YOUR MCH_ID",
#      "nonce_str"=>"8RN7YfTZ3OUgWX5e",
#      "sign"=>"623AE90C9679729DDD7407DC7A1151B2",
#      "result_code"=>"SUCCESS",
#      "prepay_id"=>"wx2014111104255143b7605afb0314593866",
#      "code_url"=>"weixin://"
#      "trade_type"=>"NATIVE"
#    }
```

Return true if both `return_code` and `result_code` equal `SUCCESS`

```ruby
r.success? # => true
```

#### pay request for app

```ruby
# required fields
params = {
  prepayid: '1101000000140415649af9fc314aa427', # fetch by call invoke_unifiedorder with `trade_type` is `APP`
  noncestr: '1101000000140429eb40476f8896f4c9' # must same as given to invoke_unifiedorder
}

# call generate_app_pay_req
r = WxPay::Service.generate_app_pay_req params
# => {
#      appid: 'wxd930ea5d5a258f4f',
#      partnerid: '1900000109',
#      prepayid: '1101000000140415649af9fc314aa427',
#      package: 'Sign=WXPay',
#      noncestr: '1101000000140429eb40476f8896f4c9',
#      timestamp: '1398746574',
#      sign: '7FFECB600D7157C5AA49810D2D8F28BC2811827B'
#    }
```

#### pay request for JSAPI

``` ruby
# required fields
params = {
  prepayid: '1101000000140415649af9fc314aa427', # fetch by call invoke_unifiedorder with `trade_type` is `JSAPI`
  noncestr: SecureRandom.hex(16), 
}

# call generate_js_pay_req
r = WxPay::Service.generate_js_pay_req params
# {
#   "appId": "wx020c5c792c8537de",
#   "package": "prepay_id=wx20160902211806a11ccee7a20956539837",
#   "nonceStr": "2vS5AJUD7uyaa5h9",
#   "timeStamp": "1472822286",
#   "signType": "MD5",
#   "paySign": "A52433CB75CA8D58B67B2BB45A79AA01"
# }
```

#### Notify Process

A simple example of processing notify for Rails Action Controller.

```ruby
# config/routes.rb
post "notify" => "orders#notify"

# app/controllers/orders_controller.rb

def notify
  result = Hash.from_xml(request.body.read)["xml"]

  if WxPay::Sign.verify?(result)

    # find your order and process the post-paid logic.

    render :xml => {return_code: "SUCCESS"}.to_xml(root: 'xml', dasherize: false)
  else
    render :xml => {return_code: "FAIL", return_msg: "签名失败"}.to_xml(root: 'xml', dasherize: false)
  end
end
```

A simple example of processing notify for Grape v1.2.2 .

```ruby
# Gemfile
gem 'multi_xml'

# config/routes.rb
mount WechatPay::Api => '/'

# app/api/wechat_pay/api.rb
module WechatPay
  class Api < Grape::API
    content_type :xml, 'text/xml'
    format :xml
    formatter :xml, lambda { |object, env| object.to_xml(root: 'xml', dasherize: false) }
    
    post "notify" do
      result = params["xml"]
      if WxPay::Sign.verify?(result)
          # find your order and process the post-paid logic.
          
        status 200
        {return_code: "SUCCESS"}
      else
        status 200
        {return_code: "FAIL", return_msg: "签名失败"}
      end
    end
  end
end
```


### Integrate with QRCode(二维码)

Wechat payment integrating with QRCode is a recommended process flow which will bring users comfortable experience. It is recommended to generate QRCode using `rqrcode` and `rqrcode_png`.

**Example Code** (please make sure that `public/uploads/qrcode` was created):

```ruby
r = WxPay::Service.invoke_unifiedorder params
qrcode_png = RQRCode::QRCode.new( r["code_url"], :size => 5, :level => :h ).to_img.resize(200, 200).save("public/uploads/qrcode/#{@order.id.to_s}_#{Time.now.to_i.to_s}.png")
@qrcode_url = "/uploads/qrcode/#{@order.id.to_s}_#{Time.now.to_i.to_s}.png"
```

### More

No documents yet, check `lib/wx_pay/service.rb`

## Multi-account support

All functions have third argument `options`,
you can pass `appid`, `mch_id`, `key`, `apiclient_cert`, `apiclient_key` as a hash.

For example
```ruby
another_account = {appid: 'APPID', mch_id: 'MCH_ID', key: 'KEY'}.freeze
WxPay::Service.generate_app_pay_req params, another_account.dup
```

## Contributing

Bug report or pull request are welcome.

### Make a pull request

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Please write unit test with your code if necessary.

## License

This project rocks and uses MIT-LICENSE.
