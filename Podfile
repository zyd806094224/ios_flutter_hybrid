# platform :ios, '11.0'

# Add this line to integrate your Flutter module.
# Make sure the path is correct.
flutter_application_path = '/Users/zhaoyudong/FlutterProjects/lib_flutter'
load File.join(flutter_application_path, '.ios', 'Flutter', 'podhelper.rb')

target 'ios_flutter_hybrid' do
  # This is a required setting for Flutter integration
  use_frameworks!
  
  install_all_flutter_pods(flutter_application_path)
end

# This block is required by Flutter
post_install do |installer|
  flutter_post_install(installer)
end