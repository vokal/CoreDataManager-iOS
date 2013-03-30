//
//  VIManagedObjectMap.m
//  CoreData
//

#import "VIManagedObjectMap.h"
#import "VICoreDataManager.h"

@implementation VIManagedObjectMap

+ (instancetype)mapWithForeignKey:(NSString *)foreignKey coreDataKey:(NSString *)coreDataKey
{
    return [self mapWithForeignKey:foreignKey coreDataKey:coreDataKey dateFormatter:nil];
}

+ (instancetype)mapWithForeignKey:(NSString *)foreignKey
                      coreDataKey:(NSString *)coreDataKey
                    dateFormatter:(NSDateFormatter *)dateFormatter
{
    VIManagedObjectMap *map = [[self alloc] init];
    [map setInputKey:foreignKey];
    [map setCoreDataKey:coreDataKey];
    [map setDateFormatter:dateFormatter];
    return map;
}

+ (NSArray *)mapsFromDictionary:(NSDictionary *)mapDict
{
    NSMutableArray *mapArray = [NSMutableArray array];

    [mapDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        //key = input key, obj = core data key
        [mapArray addObject:[self mapWithForeignKey:key coreDataKey:obj]];
    }];

    return [mapArray copy];
}

+ (NSDateFormatter *)defaultDateFormatter
{
    static NSDateFormatter *df;

    if (!df) {
        df = [[NSDateFormatter alloc] init];
        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        [df setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
    return df;
}

@end
