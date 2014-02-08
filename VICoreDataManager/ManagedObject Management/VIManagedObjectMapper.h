//
//  VIManagedObjectMap.h
//  CoreData
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "VIManagedObjectMap.h"

@interface VIManagedObjectMapper : NSObject

/// Used to identify and update NSManagedObjects. Like a "primary key" in databases.
@property (readonly) NSString *uniqueComparisonKey;
/// Used internally to filter input data. Updates automatically to match the uniqueComparisonKey.
@property (readonly) NSString *foreignUniqueComparisonKey;
/// If set to NO changes are discarded if a local object exists with the same unique comparison key. Defaults to YES.
@property BOOL overwriteObjectsWithServerChanges;

/**
 Creates a new map.
 @param comparisonKey
 An NSString to uniquely identify local entities. Can be nil to enable duplicates.
 @param mapsArray
 An NSArray of VIManagedObjectMaps to corrdinate input data and the core data model.
 @return 
 A new mapper with the given unique key and maps.
 */
+ (instancetype)mapperWithUniqueKey:(NSString *)comparisonKey
                            andMaps:(NSArray *)mapsArray;
/**
 Convenience constructor for default mapper.
 @return
 A default mapper wherein the local keys and foreign keys are identical.
 */
+ (instancetype)defaultMapper;

@end