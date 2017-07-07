Pod::Spec.new do |s|
  s.name             = 'RxFlux'
  s.version          = '0.1.0'
  s.summary          = 'Flux using ReactiveX'


  s.description      = <<-DESC
  Flux is a Flux-like implementation of the unidirectional data flow architecture in Swift.
  It embraces a unidirectional data flow that only allows state mutations through declarative actions.
                       DESC

  s.homepage         = 'https://github.com/hungdv136/rx.flux'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Hung Dinh' => 'hungdv136@gmail.com' }
  s.source           = { :git => 'https://github.com/hungdv136/rx.flux.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/hungdv136'

  s.ios.deployment_target = '9.0'

  s.source_files = '**/*.swift'

  s.dependency 'RxSwift', '~> 3.5.0'
  s.dependency 'RxCocoa', '~> 3.5.0'
end
