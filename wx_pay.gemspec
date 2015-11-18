# -*- encoding: utf-8 -*-
# stub: wx_pay 0.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "wx_pay"
  s.version = "0.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Jasl"]
  s.date = "2015-11-16"
  s.description = "An unofficial simple wechat pay gem"
  s.email = ["jasl9187@hotmail.com"]
  s.files = ["MIT-LICENSE", "Rakefile", "lib/wx_pay", "lib/wx_pay.rb", "lib/wx_pay/result.rb", "lib/wx_pay/service.rb", "lib/wx_pay/sign.rb", "lib/wx_pay/version.rb", "test/test_helper.rb", "test/wx_pay", "test/wx_pay/result_test.rb", "test/wx_pay/service_test.rb", "test/wx_pay/sign_test.rb"]
  s.homepage = "https://github.com/jasl/wx_pay"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.5"
  s.summary = "An unofficial simple wechat pay gem"
  s.test_files = ["test/test_helper.rb", "test/wx_pay", "test/wx_pay/result_test.rb", "test/wx_pay/service_test.rb", "test/wx_pay/sign_test.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rest-client>, [">= 1.7"])
      s.add_runtime_dependency(%q<activesupport>, [">= 3.2"])
      s.add_development_dependency(%q<bundler>, ["~> 1"])
      s.add_development_dependency(%q<rake>, ["~> 10"])
      s.add_development_dependency(%q<fakeweb>, ["~> 1"])
      s.add_development_dependency(%q<minitest>, ["~> 5"])
    else
      s.add_dependency(%q<rest-client>, [">= 1.7"])
      s.add_dependency(%q<activesupport>, [">= 3.2"])
      s.add_dependency(%q<bundler>, ["~> 1"])
      s.add_dependency(%q<rake>, ["~> 10"])
      s.add_dependency(%q<fakeweb>, ["~> 1"])
      s.add_dependency(%q<minitest>, ["~> 5"])
    end
  else
    s.add_dependency(%q<rest-client>, [">= 1.7"])
    s.add_dependency(%q<activesupport>, [">= 3.2"])
    s.add_dependency(%q<bundler>, ["~> 1"])
    s.add_dependency(%q<rake>, ["~> 10"])
    s.add_dependency(%q<fakeweb>, ["~> 1"])
    s.add_dependency(%q<minitest>, ["~> 5"])
  end
end
