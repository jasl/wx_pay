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
WxPay.appid = 'YOUR_APPID'
WxPay.key = 'YOUR_KEY'
WxPay.mch_id = 'YOUR_MCH_ID'
```

### APIs

**PLACEHOLDER**

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
