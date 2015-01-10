//
//  VIManagedObject.m
//  CoreData
//

#import "VIManagedObject.h"
#import "VICoreDataManagerSKZ.h"

@implementation NSManagedObject (VIManagedObjectAdditions)

- (void)safeSetValueSKZ:(id)value forKey:(NSString *)key
{
    if (value && ![[NSNull null] isEqual:value]) {
        [self setValue:value forKey:key];
    } else {
        [self setNilValueForKey:key];
    }
}

- (NSDictionary *)dictionaryRepresentationSKZ
{
    return [[VICoreDataManagerSKZ sharedInstance] dictionaryRepresentationOfManagedObject:self respectKeyPaths:NO];
}

- (NSDictionary *)dictionaryRepresentationRespectingKeyPathsSKZ
{
    return [[VICoreDataManagerSKZ sharedInstance] dictionaryRepresentationOfManagedObject:self respectKeyPaths:YES];
}

#pragma mark - Create Objects
+ (instancetype)newInstanceSKZ
{
    return [self newInstanceWithContextSKZ:nil];
}

+ (instancetype)newInstanceWithContextSKZ:(NSManagedObjectContext *)context
{
    return [[VICoreDataManagerSKZ sharedInstance] managedObjectOfClass:self inContext:context];
}

#pragma mark - Add Objects
+ (NSArray *)addWithArraySKZ:(NSArray *)inputArray forManagedObjectContext:(NSManagedObjectContext*)contextOrNil
{
    return [[VICoreDataManagerSKZ sharedInstance] importArray:inputArray forClass:[self class] withContext:contextOrNil];
}

+ (NSArray *)addWithArraySKZ:(NSArray *)inputArray
         deletePendingObject:(BOOL)shouldDeletePendingObjects
     forManagedObjectContext:(NSManagedObjectContext*)contextOrNil
{
    
    NSArray *pendingObjects = [self fetchAllForPredicateSKZ:nil forManagedObject:contextOrNil];
    NSArray *addedObjects = [[VICoreDataManagerSKZ sharedInstance] importArray:inputArray forClass:[self class] withContext:contextOrNil];
    if (shouldDeletePendingObjects) {
        [pendingObjects enumerateObjectsUsingBlock:^(NSManagedObject *oldObj, NSUInteger idx, BOOL *stop) {
            if (![addedObjects containsObject:oldObj]) {
                [contextOrNil deleteObject:oldObj];
            }
        }];
    }
    
    return addedObjects;
}

+ (instancetype)addWithDictionarySKZ:(NSDictionary *)inputDict forManagedObjectContext:(NSManagedObjectContext*)contextOrNil
{
    if (!inputDict || [[NSNull null] isEqual:inputDict]) {
        return nil;
    }

    NSArray *array = [[VICoreDataManagerSKZ sharedInstance] importArray:@[inputDict] forClass:[self class] withContext:contextOrNil];
    
    if (array.count) {
        return array[0];
    } else {
        return nil;
    }
}

#pragma mark - Fetch with Object's Context
+ (BOOL)existsForPredicateSKZ:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)object
{
    return [self existsForPredicateSKZ:predicate forManagedObjectContext:[object managedObjectContext]];
}

+ (NSArray *)fetchAllForPredicateSKZ:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)object
{
    return [self fetchAllForPredicateSKZ:predicate forManagedObjectContext:[object managedObjectContext]];
}

+ (id)fetchForPredicateSKZ:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)object
{
    return [self fetchForPredicateSKZ:predicate forManagedObjectContext:[object managedObjectContext]];
}

#pragma mark - Fetch with Context
+ (BOOL)existsForPredicateSKZ:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)contextOrNil
{
    return [[VICoreDataManagerSKZ sharedInstance] countForClass:[self class]
                                               withPredicate:predicate
                                                  forContext:contextOrNil];
}

+ (NSArray *)fetchAllForPredicateSKZ:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)contextOrNil
{
    return [[VICoreDataManagerSKZ sharedInstance] arrayForClass:[self class]
                                               withPredicate:predicate
                                                  forContext:contextOrNil];
}

+ (id)fetchForPredicateSKZ:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)contextOrNil
{
    NSArray *results = [self fetchAllForPredicateSKZ:predicate forManagedObjectContext:contextOrNil];

    NSUInteger count = [results count];
    if (count) {
        if (count > 1) {
            SKZLog(@"Your predicate is returning more than 1 object, but the coredatamanger returns only one.");
        }
        return [results lastObject];
    }

    return nil;
}

@end
