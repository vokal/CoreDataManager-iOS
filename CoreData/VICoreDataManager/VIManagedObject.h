//
//  VIManagedObject.h
//  CoreData
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (VIManagedObjectAdditions)

- (void)safeSetValue:(id)value forKey:(NSString *)key;

- (NSDictionary *)dictionaryRepresentation;

//Convenience factory methods to create a new instance of any VIManagedObject subclass.
//If a context isn't specified, the main context will be used.
+ (instancetype)newInstance;
+ (instancetype)newInstanceWithContext:(NSManagedObjectContext *)context;

//If contextOrNil is nil the main context will be used.
//these setters should only be used to set all properties of a class, any mapped attributes not included will be set to nil
//these will overwrite ALL of an NSManagedObject's properties
+ (NSArray *)addWithArray:(NSArray *)inputArray forManagedObjectContext:(NSManagedObjectContext*)contextOrNil;
+ (instancetype)addWithDictionary:(NSDictionary *)inputDict forManagedObjectContext:(NSManagedObjectContext*)contextOrNil;


//These will adhere to the NSManagedObjectContext of the managedObject.
+ (BOOL)existsForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)object;
+ (NSArray *)fetchAllForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)object;
+ (id)fetchForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)object;


//These allow for more flexibility.
+ (BOOL)existsForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)contextOrNil;
+ (NSArray *)fetchAllForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)contextOrNil;
+ (id)fetchForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)contextOrNil;

@end