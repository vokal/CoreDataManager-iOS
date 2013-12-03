//
//  VIManagedObjectMap.m
//  CoreData
//

#import "VIManagedObjectMapSKZ.h"
#import "VICoreDataManagerSKZ.h"

@implementation VIManagedObjectMapSKZ

+ (instancetype)mapWithForeignKeyPath:(NSString *)inputKeyPath coreDataKey:(NSString *)coreDataKey
{
    return [self mapWithForeignKeyPath:inputKeyPath coreDataKey:coreDataKey dateFormatter:nil];
}

+ (instancetype)mapWithForeignKeyPath:(NSString *)inputKeyPath
                          coreDataKey:(NSString *)coreDataKey
                        dateFormatter:(NSDateFormatter *)dateFormatter
{
    VIManagedObjectMapSKZ *map = [[self alloc] init];
    [map setInputKeyPath:inputKeyPath];
    [map setCoreDataKey:coreDataKey];
    [map setDateFormatter:dateFormatter];
    return map;
}

+ (instancetype)mapWithForeignKeyPath:(NSString *)inputKeyPath
                          coreDataKey:(NSString *)coreDataKey
                      numberFormatter:(NSNumberFormatter *)numberFormatter
{
    VIManagedObjectMapSKZ *map = [[self alloc] init];
    [map setInputKeyPath:inputKeyPath];
    [map setCoreDataKey:coreDataKey];
    [map setNumberFormatter:numberFormatter];
    return map;
}

+ (NSArray *)mapsFromDictionary:(NSDictionary *)mapDict
{
    NSMutableArray *mapArray = [NSMutableArray array];

    [mapDict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        //key = input key, obj = core data key
        [mapArray addObject:[self mapWithForeignKeyPath:key coreDataKey:obj]];
    }];

    return [mapArray copy];
}

+ (NSDateFormatter *)defaultDateFormatter
{
    static dispatch_once_t pred = 0;
    static NSDateFormatter *DefaultDateFormatter;
    dispatch_once(&pred, ^{
        DefaultDateFormatter = [NSDateFormatter new];
        [DefaultDateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
        [DefaultDateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    });

    return DefaultDateFormatter;
}

+ (NSNumberFormatter *)defaultNumberFormatter
{
    static dispatch_once_t pred = 0;
    static NSNumberFormatter *DefaultNumberFormatter;
    dispatch_once(&pred, ^{
        DefaultNumberFormatter = [NSNumberFormatter new];
        [DefaultNumberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
    });
    return DefaultNumberFormatter;
}

#pragma mark - Description
- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p>\nCore Data Key : %@\nForeign Key : %@",NSStringFromClass([self class]), self, self.coreDataKey, self.inputKeyPath];
}

@end