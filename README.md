# WxPay

A simple Wechat pay ruby gem, without unnecessary magic or wrapper.
copied from [alipay](https://github.com/chloerei/alipay) .

Please read official document first: <https://mp.weixin.qq.com/paymch/readtemplate?t=mp/business/course3_tmpl&lang=zh_CN>.

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
WxPay.mch_id = 'YOUR_MCH_ID'
WxPay.debug_mode = true # default is `true`

# cert, see https://pay.weixin.qq.com/wiki/doc/api/app/app.php?chapter=4_3
# using PCKS12
WxPay.set_apiclient_by_pkcs12(File.read(pkcs12_filepath), pass)

# optional - configurations for RestClient timeout, etc.
WxPay.extra_rest_client_options = {timeout: 2, open_timeout: 3}
```

Note: You should create your APIKEY (Link to [微信商户平台](https://pay.weixin.qq.com/index.php/home/login)) first if you haven't, and pay attention that **the length of the APIKEY should be 32**.

### APIs

**Check official document for detailed request params and return fields**

#### unifiedorder

WxPay supports both JSAPI, NATIVE and APP.

```ruby
# required fields
params = {
  body: '测试商品',
  out_trade_no: 'test003',
  total_fee: 1,
  spbill_create_ip: '127.0.0.1',
  notify_url: 'http://making.dev/notify',
  trade_type: 'JSAPI', # could be "JSAPI", "NATIVE" or "APP",
  openid: 'OPENID' # required when trade_type is `JSAPI`
}
```

`WxPay::Service.invoke_unifiedorder params` will create an payment request and return a WxPay::Result instance(subclass of Hash) contains parsed result.

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

#### Notify Process

A simple example of processing notify.

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

### Integretion with QRCode(二维码)

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
WxPay::Service.generate_app_pay_req params, {appid: 'APPID', mch_id: 'MCH_ID', key: 'KEY'}
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
