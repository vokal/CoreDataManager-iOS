//
//  VIManagedObject.h
//  CoreData
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (VIManagedObjectRequiredContentSetter)
//you MUST override this method
+ (id)setInformationFromDictionary:(NSDictionary *)params forObject:(NSManagedObject *)object;
@end

@interface NSManagedObject (VIManagedObjectAdditions)

//Override If No Relationship Is Being Made
+ (id)addWithArray:(NSArray *)array forManagedObjectContext:(NSManagedObjectContext *)context;
+ (BOOL)cleanForArray:(NSArray *)array forManagedObjectContext:(NSManagedObjectContext *)context;
+ (id)addWithParams:(NSDictionary *)params forManagedObjectContext:(NSManagedObjectContext *)context;
+ (id)editWithParams:(NSDictionary *)params forObject:(NSManagedObject*)object;
+ (id)syncWithParams:(NSDictionary *)params forManagedObjectContext:(NSManagedObjectContext *)context;
+ (BOOL)existsForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)context;
+ (NSArray *)fetchAllForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)context;
+ (id)fetchForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)context;

//Override If A Relationship Is Being Made
+ (id)addWithArray:(NSArray *)array forManagedObject:(NSManagedObject *)managedObject;
+ (BOOL)cleanForArray:(NSArray *)array forManagedObject:(NSManagedObject *)managedObject;
+ (id)addWithParams:(NSDictionary *)params forManagedObject:(NSManagedObject *)managedObject;
+ (id)editWithParams:(NSDictionary *)params forObject:(NSManagedObject*)object forManagedObject:(NSManagedObject *)managedObject;
+ (id)syncWithParams:(NSDictionary *)params forManagedObject:(NSManagedObject *)managedObject;
+ (BOOL)existsForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)managedObject;
+ (NSArray *)fetchAllForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)managedObject;
+ (id)fetchForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)managedObject;

//Convenience Methods
+ (id)newAttribute:(id)newAttribute forOldAttribute:(id)oldAttribute;
+ (id)newAttribute:(id)newAttribute forOldAttribute:(id)oldAttribute preserveExistingAttributes:(BOOL)preserveOld;
@end