//
//  VIManagedObject.m
//  CoreData
//

#import "VIManagedObject.h"
#import "VICoreDataManager.h"

@implementation NSManagedObject (VIManagedObjectAdditions)

#pragma mark - No Relationship
+ (id)addWithArray:(NSArray *)array forManagedObjectContext:(NSManagedObjectContext *)context
{
    NSMutableArray*createdObjects = [@[] mutableCopy];

    if ([self cleanForArray:array forManagedObjectContext:context]) {
        for (NSDictionary *params in array) {
            id obj = [self addWithParams:params forManagedObjectContext:context];
            if (obj != nil) {
                [createdObjects addObject:obj];
            }
        }
    }

    return createdObjects;
}

+ (BOOL)cleanForArray:(NSArray *)array forManagedObjectContext:(NSManagedObjectContext *)context
{
    return YES;
}

+ (id)addWithParams:(NSDictionary *)params forManagedObjectContext:(NSManagedObjectContext *)context
{
    return nil;
}

+ (id)editWithParams:(NSDictionary *)params forObject:(NSManagedObject*)object
{
    return [self setInformationFromDictionary:params forObject:object];
}

+ (id)syncWithParams:(NSDictionary *)params forManagedObjectContext:(NSManagedObjectContext *)context
{
    NSManagedObject *object = [[VICoreDataManager getInstance] addObjectForEntityName:NSStringFromClass([self class])
                                                                           forContext:context];

    return [self setInformationFromDictionary:params forObject:object];
}

+ (BOOL)existsForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)context
{
    return [self fetchForPredicate:predicate forManagedObjectContext:context] != nil;
}

+ (NSArray *)fetchAllForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)context
{
    NSArray *results = [[VICoreDataManager getInstance] arrayForEntityName:NSStringFromClass([self class])
                                                             withPredicate:predicate
                                                                forContext:context];
    return results;
}

+ (id)fetchForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)context
{
    NSArray *results = [self fetchAllForPredicate:predicate forManagedObjectContext:context];

    if ([results count] > 0) {
        return [results lastObject];
    }

    return nil;
}

#pragma mark - Relationship
+ (id)addWithArray:(NSArray *)array forManagedObject:(NSManagedObject *)managedObject
{
    NSMutableArray*createdObjects = [@[] mutableCopy];
    if ([self cleanForArray:array forManagedObject:managedObject]) {
        for (NSDictionary *params in array) {

            id obj = [self addWithParams:params forManagedObject:managedObject];
            if (obj != nil) {
                [createdObjects addObject:obj];
            }

        }
    }
    return createdObjects;
}

+ (BOOL)cleanForArray:(NSArray *)array forManagedObject:(NSManagedObject *)managedObject
{
    return YES;
}

+ (id)addWithParams:(NSDictionary *)params forManagedObject:(NSManagedObject *)managedObject
{
    return nil;
}

+ (id)editWithParams:(NSDictionary *)params forObject:(NSManagedObject*)object forManagedObject:(NSManagedObject *)managedObject
{
    return [self setInformationFromDictionary:params forObject:object];
}

+ (id)syncWithParams:(NSDictionary *)params forManagedObject:(NSManagedObject *)managedObject
{
    NSManagedObject *object = [[VICoreDataManager getInstance]
                               addObjectForEntityName:NSStringFromClass([self class])
                               forContext:[managedObject managedObjectContext]];

    return [self setInformationFromDictionary:params forObject:object];
}

+ (BOOL)existsForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)managedObject
{
    return [self fetchForPredicate:predicate forManagedObject:managedObject] != nil;
}

+ (NSArray *)fetchAllForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)managedObject
{
    NSArray *results = [[VICoreDataManager getInstance] arrayForEntityName:NSStringFromClass([self class])
                                                             withPredicate:predicate
                                                                forContext:[managedObject managedObjectContext]];

    return results;
}

+ (id)fetchForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)managedObject
{
    NSArray *results = [self fetchAllForPredicate:predicate forManagedObject:managedObject];

    if ([results count] > 0) {
        return [results lastObject];
    }

    return nil;
}

+ (id)setInformationFromDictionary:(NSDictionary *)params forObject:(NSManagedObject *)object
{
    return object;
}

#pragma mark - Convenience Methods
+ (id)newAttribute:(id)newAttribute forOldAttribute:(id)oldAttribute
{
    return [self newAttribute:newAttribute forOldAttribute:oldAttribute preserveExistingAttributes:NO];
}

+ (id)newAttribute:(id)newAttribute forOldAttribute:(id)oldAttribute preserveExistingAttributes:(BOOL)preserveOld;
{
    if (preserveOld) {
        //This will return the old attribute if the new parameter is nil or [NSNull null]
        if ([[NSNull null] isEqual:newAttribute] || newAttribute == nil) {
            return oldAttribute;
        }else{
            return newAttribute;
        }

    } else {
        //Otherwise a NULL or nil new attribute will be returned to overwrite the old attribute
        if ([[NSNull null] isEqual:newAttribute]) {
            newAttribute = nil;
        }
        return newAttribute;
    }
}

@end
