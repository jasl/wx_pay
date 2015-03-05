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
gem 'wx_pay', :github => 'jasl/wxpay'
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

# optional - configurations for RestClient timeout, etc.
WxPay.extra_rest_client_options = {timeout: 2, open_timeout: 3}
```

Note: You should create your APIKEY (Link to [微信商户平台](https://pay.weixin.qq.com/index.php/home/login)) first if you haven't, and pay attention that **the length of the APIKEY should be 32**.

### APIs

**Check official document for detailed request params and return fields**

#### unifiedorder

WxPay supports both JSAPI and NATIVE.

```ruby
# required fields
params = {
  body: '测试商品',
  out_trade_no: 'test003',
  total_fee: 1,
  spbill_create_ip: '127.0.0.1',
  notify_url: 'http://making.dev/notify',
  trade_type: 'JSAPI' # could be "JSAPI" or "NATIVE",
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
    render :xml => {return_code: "SUCCESS", return_msg: "签名失败"}.to_xml(root: 'xml', dasherize: false)
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
