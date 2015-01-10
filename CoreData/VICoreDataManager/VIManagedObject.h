//
//  VIManagedObject.h
//  CoreData
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (VIManagedObjectAdditions)

/**
 Checks for NSNull before seting a value.
 @param value
 The input object.
 @param key
 The key to set.
 */
- (void)safeSetValueSKZ:(id)value forKey:(NSString *)key;

/**
 Creates a dictionary based on the set mapping. This should round-trip data from dictionaries to core data and back.
 This method does not respect keyPaths. The dictionary is flat.
 @return
 An NSDictioary matching the original input dictionary.
 */
- (NSDictionary *)dictionaryRepresentationSKZ;

/**
 Creates a dictionary based on the set mapping. This should round-trip data from dictionaries to core data and back.
 This method respects keyPaths.
 @return
 An NSDictioary matching the original input dictionary.
 */
- (NSDictionary *)dictionaryRepresentationRespectingKeyPathsSKZ;

/**
 A convenience methods to create a new instance of a VIManagedObject subclass.
 @return
 A new managed object subclass in the main context.
 */
+ (instancetype)newInstanceSKZ;

/**
 A convenience methods to create a new instance of a VIManagedObject subclass.
 @param contextOrNil
 The managed object context to insert the new object.  If nil, the main context will be used.
 @return
 A new managed object subclass in the main context.
 */
+ (instancetype)newInstanceWithContextSKZ:(NSManagedObjectContext *)contextOrNil;

/*
 Create or update many NSManagedObjects, respecting overwriteObjectsWithServerChanges.
 This should only be used to set all properties of an entity, any mapped attributes not included in the input dictionaries will be set to nil.
 This will overwrite ALL of an NSManagedObject's properties.
 @param inputArray
 An array of dictionaries with foreign data to inport.
 @param contextOfNil
 The managed object context to update and/or insert the objects. If nil, the main context will be used.
 @return 
 An array of this subclass of NSManagedObject.
 **/
+ (NSArray *)addWithArraySKZ:(NSArray *)inputArray forManagedObjectContext:(NSManagedObjectContext*)contextOrNil;


/*
 Create or update many NSManagedObjects, respecting overwriteObjectsWithServerChanges.
 This should only be used to set all properties of an entity, any mapped attributes not included in the input dictionaries will be set to nil.
 This will overwrite ALL of an NSManagedObject's properties.
 @param inputArray
 An array of dictionaries with foreign data to inport.
 @param shouldDeletePendingObjects
 Any objects not updated or created by an entry in inputArray will be deleted if this is set to YES.
 @param contextOfNil
 The managed object context to update and/or insert the objects. If nil, the main context will be used.
 @return
 An array of this subclass of NSManagedObject.
 **/
+ (NSArray *)addWithArraySKZ:(NSArray *)inputArray
         deletePendingObject:(BOOL)shouldDeletePendingObjects
     forManagedObjectContext:(NSManagedObjectContext*)contextOrNil;

/*
 Create or update a single NSManagedObject, respecting overwriteObjectsWithServerChanges.
 This should only be used to set all properties of an entity, any mapped attributes not included in the input dictionaries will be set to nil.
 This will overwrite ALL of an NSManagedObject's properties.
 @param inputDict
 A dictionary with foreign data to inport.
 @param contextOfNil
 The managed object context to update and/or insert the object. If nil, the main context will be used.
 @return
 An instance of this subclass of NSManagedObject.
 **/
+ (instancetype)addWithDictionarySKZ:(NSDictionary *)inputDict forManagedObjectContext:(NSManagedObjectContext*)contextOrNil;


//These will adhere to the NSManagedObjectContext of the managedObject.
+ (BOOL)existsForPredicateSKZ:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)object;
+ (NSArray *)fetchAllForPredicateSKZ:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)object;
+ (id)fetchForPredicateSKZ:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)object;


//These allow for more flexibility.
+ (BOOL)existsForPredicateSKZ:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)contextOrNil;
+ (NSArray *)fetchAllForPredicateSKZ:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)contextOrNil;
+ (id)fetchForPredicateSKZ:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)contextOrNil;

@end