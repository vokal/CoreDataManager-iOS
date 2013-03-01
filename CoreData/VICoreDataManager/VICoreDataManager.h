//
//  VICoreDataManager.h
//  CoreData
//

#ifndef __IPHONE_5_0
#warning "VICoreDataManager uses features only available in iOS SDK 5.0 and later."
#endif

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "VIManagedObject.h"
#import "VIFetchResultsDataSource.h"

FOUNDATION_EXTERN NSString *const VICOREDATA_NOTIFICATION_ICLOUD_UPDATED;

@interface VICoreDataManager : NSObject

+ (VICoreDataManager *)getInstance;

- (NSManagedObjectContext *)managedObjectContext;

//be sure to use one of these setup methods before interacting with Core Data
- (void)setResource:(NSString *)resource database:(NSString *)database;
- (void)setResource:(NSString *)resource database:(NSString *)database iCloudAppId:(NSString *)iCloudAppId;

//This creates a new managedObject of any type
//If contextOrNil is nil the main context will be used.
- (NSManagedObject *)addObjectForEntityName:(NSString *)entityName forContext:(NSManagedObjectContext *)contextOrNil;

//Fetch and delete are NOT threadsafe.
//Be sure to use a temp context if you are NOT on the main thread.
- (NSArray *)arrayForEntityName:(NSString *)entityName;
- (NSArray *)arrayForEntityName:(NSString *)entityName forContext:(NSManagedObjectContext *)contextOrNil;
- (NSArray *)arrayForEntityName:(NSString *)entityName withPredicate:(NSPredicate *)predicate forContext:(NSManagedObjectContext *)contextOrNil;

- (void)deleteObject:(NSManagedObject *)object;
- (BOOL)deleteAllObjectsOfEntity:(NSString *)entityName context:(NSManagedObjectContext *)contextOrNil;

//This saves the main context asynchronously on the main thread
- (void)saveMainContext;

//wrap your background transactions in these methods
- (NSManagedObjectContext *)startTransaction;
- (void)endTransactionForContext:(NSManagedObjectContext *)context;

//this deletes the persistent stores and resets the main context and model to nil
- (void)resetCoreData;

@end

@interface VICoreDataManager (Deprecated)
//this is renamed to deleteAllObjectsOfEntity:
- (void)dropTableForEntityWithName:(NSString *)name DEPRECATED_ATTRIBUTE;

//these should all be name <something>ForEntity not <something>ForModel
- (id)addObjectForModel:(NSString *)model context:(NSManagedObjectContext *)context DEPRECATED_ATTRIBUTE;
- (NSArray *)arrayForModel:(NSString *)model DEPRECATED_ATTRIBUTE;
- (NSArray *)arrayForModel:(NSString *)model forContext:(NSManagedObjectContext *)context DEPRECATED_ATTRIBUTE;
- (NSArray *)arrayForModel:(NSString *)model withPredicate:(NSPredicate *)predicate forContext:(NSManagedObjectContext *)context DEPRECATED_ATTRIBUTE;
@end