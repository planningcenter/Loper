Pod::Spec.new do |spec|
  spec.name         = "Loper"
  spec.version      = "1.0.0"
  spec.summary      = "Local Persistent Store is a Key Value store for iOS.  It's written in Swift but fully compatable with Objective-C."
  spec.description  = <<-DESC
  This projects Caches our API calls
                   DESC
  spec.homepage     = "https://github.com/planningcenter/Loper"
  spec.license      = "MIT"
  spec.author       = "Erik Bye"
  spec.platform     = :ios, "11.0"
  spec.source       = { :git => "git@github.com:planningcenter/Loper.git", :tag => "#{spec.version}" }
  spec.dependency 'sqlite3'
  spec.source_files = "Loper", "Loper/**/*.{h,c,swift}"
  spec.swift_version = '5.0'
  spec.exclude_files = "Classes/Exclude"
end

