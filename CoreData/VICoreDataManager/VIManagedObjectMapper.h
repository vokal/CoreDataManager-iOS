//
//  VIManagedObjectMap.h
//  CoreData
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "VIManagedObjectMap.h"

@interface VIManagedObjectMapper : NSObject

@property (readonly) NSString *uniqueComparisonKey;
@property (readonly) NSString *foreignUniqueComparisonKey;

@property BOOL overwriteObjectsWithServerChanges; //default is YES

//Unique key is a unique local key for checking for core data duplicates
+ (instancetype)mapperWithUniqueKey:(NSString *)comparisonKey
                            andMaps:(NSArray *)mapsArray;

+ (instancetype)defaultMapper;

@end

@interface VIManagedObjectDefaultMapper : VIManagedObjectMapper
@end