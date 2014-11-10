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

```ruby
# required
WxPay.appid = 'YOUR_APPID'
WxPay.key = 'YOUR_KEY'
WxPay.mch_id = 'YOUR_MCH_ID'

# optional
WxPay.extra_rest_client_options = {timeout: 2, open_timeout: 3}
```

### APIs

**Check official document for detailed request params and return fields**

#### unifiedorder
 
```ruby
# required fields 
params = {
body: '测试商品',
out_trade_no: 'test003',
total_fee: 1,
spbill_create_ip: '127.0.0.1',
notify_url: 'http://making.dev',
trade_type: 'JSAPI'
}

# Return a WxPay::Result instance(subclass of Hash) contains parsed result
r = WxPay::Service.invoke_unifiedorder params
# => {"return_code"=>"SUCCESS",
#     "return_msg"=>"OK",
#     "appid"=>"YOUR APPID",
#     "mch_id"=>"YOUR MCH_ID",
#     "nonce_str"=>"8RN7YfTZ3OUgWX5e",
#     "sign"=>"623AE90C9679729DDD7407DC7A1151B2",
#     "result_code"=>"SUCCESS",
#     "prepay_id"=>"wx2014111104255143b7605afb0314593866",
#     "trade_type"=>"JSAPI"}

# Return true if both return_code and result_code equal SUCCESS
r.success? # => true
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
