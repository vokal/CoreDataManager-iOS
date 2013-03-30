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

@property BOOL deleteAllBeforeImport; //default is YES
@property BOOL overwriteObjectsWithServerChanges; //default is YES

+ (instancetype)mapperWithUniqueKey:(NSString *)comparisonKey
                            andMaps:(NSArray *)mapsArray;

+ (instancetype)defaultMapper;

@end

@interface VIManagedObjectDefaultMapper : VIManagedObjectMapper
@end