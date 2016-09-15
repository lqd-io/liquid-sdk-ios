Pod::Spec.new do |s|
  s.name              = "Liquid"
  s.version           = "2.3.4"
  s.summary           = "Liquid is a platform that enables publishers to dynamically serve their applications based on user profiling, activity and context."
  s.homepage          = "https://onliquid.com/"
  s.license           = 'Apache, Version 2.0'
  s.author            = { "Liquid Data Intelligence S.A." => "support@onliquid.com" }
  s.source            = { :git => "https://github.com/lqd-io/liquid-sdk-ios.git", :tag => "v#{s.version}" }
  s.social_media_url  = 'https://twitter.com/onliquid'
  s.documentation_url = "https://docs.onliquid.com/"

  s.platform     = :ios, :watchos, :tvos
  s.ios.deployment_target = '6.0'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target = '9.0'
  s.requires_arc = true
  s.preserve_paths = %w(Liquid.xcodeproj)

  s.ios.frameworks = %w(CFNetwork Security Foundation SystemConfiguration CoreTelephony CoreLocation CoreGraphics UIKit)
  s.tvos.frameworks = %w(Foundation SystemConfiguration CoreLocation CoreGraphics UIKit)
  s.watchos.frameworks = []

  s.ios.libraries = %w(icucore)
  s.ios.dependencies = {
    'SocketRocket' => '~> 0.5',
    'Aspects' => '~> 1.4'
  }

  s.ios.xcconfig = {
    'OTHER_LDFLAGS' => '$(inherited) -ObjC -all_load -licucore',
  }
  s.watchos.xcconfig = {
    'OTHER_LDFLAGS' => '$(inherited) -ObjC -all_load',
  }
  s.source_files = 'Liquid/**/*.{m,h}'
  s.public_header_files = 'Liquid/**/*.h'
  s.ios.resources = 'Liquid/**/*.xib'
  s.watchos.resources = []
  s.tvos.resources = []
  s.exclude_files = 'Liquid/Lib/Aspects/**/*',
                    'Liquid/Lib/SocketRocket/**/*'
  excluded_files = 'Liquid/Model/LQCallToAction.[mh]',
                   'Liquid/Model/LQInAppMessage*.[mh]',
                   'Liquid/LQNetworkingURLConnection.[mh]',
                   'Liquid/Views/*.{m,h,xib}',
                   'Liquid/ViewControllers/*.[mh]',
                   'Liquid/LQUIElement*.[mh]',
                   'Liquid/Model/LQWeakValue.[mh]',
                   'Liquid/Model/LQLightweightSet.[mh]',
                   'Liquid/Model/LQUIElement.[mh]',
                   'Liquid/Model/LQWireframeLayer.[mh]',
                   'Liquid/Categories/*+LQChangeable.[mh]'
  s.ios.exclude_files =     'Liquid/**/*[wW]atchOS*.[mh]'
                            'Liquid/**/*[tT]vOS*.[mh]'
  s.watchos.exclude_files = ['Liquid/**/*[iI]OS*.[mh]',
                            'Liquid/**/*[tV]vOS*.[mh]'] + excluded_files
  s.tvos.exclude_files =    ['Liquid/**/*[iI]OS*.[mh]',
                            'Liquid/**/*[wW]atchOS*.[mh]'] + excluded_files
end
