#import "MediaAndCreateDatePickerPlugin.h"
#if __has_include(<media_and_create_date_picker/media_and_create_date_picker-Swift.h>)
#import <media_and_create_date_picker/media_and_create_date_picker-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "media_and_create_date_picker-Swift.h"
#endif

@implementation MediaAndCreateDatePickerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftMediaAndCreateDatePickerPlugin registerWithRegistrar:registrar];
}
@end
