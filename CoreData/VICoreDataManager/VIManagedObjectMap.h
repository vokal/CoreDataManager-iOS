//
//  VIManagedObjectMap.h
//  CoreData
//

#import <Foundation/Foundation.h>

@interface VIManagedObjectMap : NSObject

@property NSString *inputKey;
@property NSString *coreDataKey;
@property (nonatomic) NSDateFormatter *dateFormatter;

//easy access to rfc3339, like "1985-04-12T23:20:50.52Z"
+ (NSDateFormatter *)defaultDateFormatter;

//Defaults to NSNumberFormatterDecimalStyle
+ (NSNumberFormatter *)defaultNumberFormatter;

+ (instancetype)mapWithForeignKey:(NSString *)foreignKey
                      coreDataKey:(NSString *)coreDataKey;

+ (instancetype)mapWithForeignKey:(NSString *)foreignKey
                      coreDataKey:(NSString *)coreDataKey
                    dateFormatter:(NSDateFormatter *)dateFormatter;

//Make a dictionary of keys and values and get an array of maps in return
//key = expected input key, value = core data key
+ (NSArray *)mapsFromDictionary:(NSDictionary *)mapDict;

@end