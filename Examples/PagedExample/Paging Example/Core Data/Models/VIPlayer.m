//
//  VIPlayer.m
//  PagedCoreData
//
//  Created by teejay on 1/21/14.
//
//

#import "VIPlayer.h"
#import "VICoreDataManager.h"

@implementation VIPlayer

@dynamic cUsername;
@dynamic cHighscore;


+ (void)setupMaps
{
    NSArray *maps = @[[VIManagedObjectMap mapWithForeignKeyPath:@"username" coreDataKey:@"cUsername"],
                      [VIManagedObjectMap mapWithForeignKeyPath:@"highscore" coreDataKey:@"cHighscore"]];
    
    VIManagedObjectMapper *mapper = [VIManagedObjectMapper mapperWithUniqueKey:@"cUsername" andMaps:maps];
    [[VICoreDataManager sharedInstance] setObjectMapper:mapper forClass:[VIPlayer class]];
}

@end
