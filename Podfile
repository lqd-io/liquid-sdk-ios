def liquid
  pod 'Liquid', path: '.'
end

target 'LiquidDemo' do
  platform :ios, '6.0'
  liquid
end

target 'LiquidTests' do
  platform :ios, '6.0'
  pod 'Kiwi', git: 'https://github.com/kiwi-bdd/Kiwi.git', tag: '2.3.0'
  pod 'OCMock', '~> 2.2.4'
  pod 'OHHTTPStubs', '~> 3.1.2'
  liquid
end

target 'LiquidWatchDemo' do
  platform :watchos, '2.0'
  liquid
end

target 'LiquidWatchDemo Extension' do
  platform :watchos, '2.0'
  liquid
end

