#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

FOUNDATION_EXTERN NSString *const NOTIFICATION_ICLOUD_UPDATED;

@interface VICoreDataManager : NSObject

+ (VICoreDataManager *)getInstance;

- (NSManagedObjectContext *)managedObjectContext;

- (void)setResource:(NSString *)resource database:(NSString *)database;
- (void)setResource:(NSString *)resource database:(NSString *)database iCloudAppId:(NSString *)iCloudAppId;

- (NSManagedObject *)addObjectForEntityName:(NSString *)entityName forContext:(NSManagedObjectContext *)contextOrNil;

- (NSArray *)arrayForEntityName:(NSString *)entityName;
- (NSArray *)arrayForEntityName:(NSString *)entityName forContext:(NSManagedObjectContext *)contextOrNil;
- (NSArray *)arrayForEntityName:(NSString *)entityName withPredicate:(NSPredicate *)predicate forContext:(NSManagedObjectContext *)contextOrNil;

- (void)deleteAllObjectsOfEntity:(NSString *)entityName context:(NSManagedObjectContext *)contextOrNil;
- (void)deleteObject:(NSManagedObject *)object;

- (void)saveMainContext;

- (NSManagedObjectContext *)startTransaction;
- (void)endTransactionForContext:(NSManagedObjectContext *)context;

- (void)resetCoreData;

//DEPRECATED:
//this is renamed to deleteAllObjectsOfEntity:
- (void)dropTableForEntityWithName:(NSString *)name DEPRECATED_ATTRIBUTE;

//these should all be named <something>ForEntity not <something>ForModel
- (id)addObjectForModel:(NSString *)model context:(NSManagedObjectContext *)context DEPRECATED_ATTRIBUTE;
- (NSArray *)arrayForModel:(NSString *)model DEPRECATED_ATTRIBUTE;
- (NSArray *)arrayForModel:(NSString *)model forContext:(NSManagedObjectContext *)context DEPRECATED_ATTRIBUTE;
- (NSArray *)arrayForModel:(NSString *)model withPredicate:(NSPredicate *)predicate forContext:(NSManagedObjectContext *)context DEPRECATED_ATTRIBUTE;

@end
