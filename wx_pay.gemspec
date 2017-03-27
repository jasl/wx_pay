$:.push File.expand_path("../lib", __FILE__)

require "wx_pay/version"

Gem::Specification.new do |s|
  s.name          = "wx_pay"
  s.version       = WxPay::VERSION
  s.authors       = ["Jasl"]
  s.email         = ["jasl9187@hotmail.com"]
  s.homepage      = "https://github.com/jasl/wx_pay"
  s.summary       = "An unofficial simple wechat pay gem"
  s.description   = "An unofficial simple wechat pay gem"
  s.license       = "MIT"

  s.require_paths = ["lib"]

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_runtime_dependency "rest-client", '>= 1.7'
  s.add_runtime_dependency "activesupport", '>= 3.2'

  s.add_development_dependency "bundler", '~> 1'
  s.add_development_dependency "rake", '~> 11.2'
  s.add_development_dependency "webmock", '~> 2.3'
  s.add_development_dependency "minitest", '~> 5'
end
