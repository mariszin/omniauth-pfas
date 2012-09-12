# OmniAuth PFAS Auth

This gem is based on https://github.com/ebeigarts/omniauth-latvija
It is modified to support user attributes returned by PFAS Auth.

## Installation

```ruby
gem 'omniauth-pfas', :git => 'https://github.com/mariszin/omniauth-pfas.git'
```

## Usage

`OmniAuth::Strategies::Pfas` is simply a Rack middleware. Read the OmniAuth 1.x docs for detailed instructions: https://github.com/intridea/omniauth.

Here's a quick example, adding the middleware to a Rails app in `config/initializers/omniauth.rb`:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :pfas, {
    :endpoint => "https://epaktv.vraa.gov.lv/IVIS.Pfas.STS/Default.aspx",
    :certificate => File.read("/path/to/cert"),
    :realm => "http://www.example.com"
  }
end
```

## References

* https://github.com/ebeigarts/omniauth-latvija
* https://github.com/onelogin/ruby-saml
