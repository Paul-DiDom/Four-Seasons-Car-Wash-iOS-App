platform :ios, '15.0'

target 'Four Seasons Car Wash' do
  # Comment this line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Four Seasons Car Wash
  pod 'FirebaseCore', '12.17.0'
  pod 'FirebaseMessaging', '12.17.0'
  pod 'FirebaseAuth', '12.17.0'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end
