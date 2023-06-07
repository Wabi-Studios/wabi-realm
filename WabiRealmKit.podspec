# coding: utf-8
Pod::Spec.new do |s|
  s.name                      = 'WabiRealmKit'
  version                     = `sh build.sh get-version`
  s.version                   = version
  s.summary                   = 'WabiRealm Swift is a modern data framework & database for iOS, macOS, tvOS & watchOS.'
  s.description               = <<-DESC
                                The WabiRealm Database, for Swift. (If you want to use WabiRealm from Objective-C, see the “Realm” pod.)

                                WabiRealm is a fast, easy-to-use replacement for Core Data & SQLite. Use it with Atlas Device Sync for realtime, automatic data sync. Works on iOS, macOS, tvOS & watchOS. Learn more and get help at https://www.mongodb.com/docs/wabi-realm/sdk/swift/.
                                DESC
  s.homepage                  = "https://realm.io"
  s.source                    = { :git => 'https://github.com/Wabi-Studios/wabi-realm.git', :tag => "v#{s.version}" }
  s.author                    = { 'WabiRealm' => 'realm-help@mongodb.com' }
  s.requires_arc              = true
  s.social_media_url          = 'https://twitter.com/realm'
  s.documentation_url         = "https://docs.mongodb.com/wabi-realm/sdk/swift"
  s.license                   = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.ios.deployment_target     = '11.0'
  s.osx.deployment_target     = '10.13'
  s.watchos.deployment_target = '4.0'
  s.tvos.deployment_target    = '11.0'
  s.preserve_paths            = %w(build.sh)
  s.swift_version             = '5'

  s.weak_frameworks = 'SwiftUI'

  s.dependency 'WabiRealm', "= #{s.version}"
  s.source_files = 'WabiRealmKit/*.swift', 'WabiRealmKit/Impl/*.swift', 'WabiRealm/Swift/*.swift'
  s.exclude_files = 'WabiRealmKit/Nonsync.swift'

  s.pod_target_xcconfig = {
    'APPLICATION_EXTENSION_API_ONLY' => 'YES'
  }
end
