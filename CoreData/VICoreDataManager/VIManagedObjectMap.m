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

+ (instancetype)mapWithForeignKey:(NSString *)foreignKey
                      coreDataKey:(NSString *)coreDataKey
                  numberFormatter:(NSNumberFormatter *)numberFormatter
{
    VIManagedObjectMap *map = [[self alloc] init];
    [map setInputKey:foreignKey];
    [map setCoreDataKey:coreDataKey];
    [map setNumberFormatter:numberFormatter];
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
    static dispatch_once_t pred = 0;
    static NSDateFormatter *df;
    dispatch_once(&pred, ^{
        df = [NSDateFormatter new];
        [df setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        [df setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    });

    return df;
}

+ (NSNumberFormatter *)defaultNumberFormatter
{
    static dispatch_once_t pred = 0;
    static NSNumberFormatter *nf;
    dispatch_once(&pred, ^{
        nf = [NSNumberFormatter new];
        [nf setNumberStyle:NSNumberFormatterDecimalStyle];
    });
    return nf;
}

@end