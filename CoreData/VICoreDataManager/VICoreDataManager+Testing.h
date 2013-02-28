#import "VICoreDataManager.h"

//use this interface for publicizing private methods for testing
@interface VICoreDataManager(privateTests)
- (void)setResource:(NSString *)resource database:(NSString *)database iCloudAppId:(NSString *)iCloudAppId forBundleIdentifier:(NSString *)bundleIdentifier;
@end
