//
//  VIManagedObject.m
//  CoreData
//

#import "VIManagedObject.h"
#import "VICoreDataManager.h"

@implementation NSManagedObject (VIManagedObjectAdditions)

- (void)safeSetValue:(id)value forKey:(NSString *)key
{
    if (value && ![[NSNull null] isEqual:value]) {
        [self setValue:value forKey:key];
    } else {
        [self setNilValueForKey:key];
    }
}

- (NSDictionary *)dictionaryRepresentation
{
    return [[VICoreDataManager sharedInstance] dictionaryRepresentationOfManagedObject:self respectKeyPaths:NO];
}

- (NSDictionary *)dictionaryRepresentationRespectingKeyPaths
{
    return [[VICoreDataManager sharedInstance] dictionaryRepresentationOfManagedObject:self respectKeyPaths:YES];
}

#pragma mark - Create Objects
+ (instancetype)newInstance
{
    return [self newInstanceWithContext:nil];
}

+ (instancetype)newInstanceWithContext:(NSManagedObjectContext *)context
{
    return [[VICoreDataManager sharedInstance] managedObjectOfClass:self inContext:context];
}

#pragma mark - Add Objects
+ (NSArray *)addWithArray:(NSArray *)inputArray forManagedObjectContext:(NSManagedObjectContext*)contextOrNil
{
    return [[VICoreDataManager sharedInstance] importArray:inputArray forClass:[self class] withContext:contextOrNil];
}

+ (instancetype)addWithDictionary:(NSDictionary *)inputDict forManagedObjectContext:(NSManagedObjectContext*)contextOrNil
{
    if (!inputDict || [[NSNull null] isEqual:inputDict]) {
        return nil;
    }

    NSArray *array = [[VICoreDataManager sharedInstance] importArray:@[inputDict] forClass:[self class] withContext:contextOrNil];
    
    if (array.count) {
        return array[0];
    } else {
        return nil;
    }
}

#pragma mark - Fetch with Object's Context
+ (BOOL)existsForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)object
{
    return [self existsForPredicate:predicate forManagedObjectContext:[object managedObjectContext]];
}

+ (NSArray *)fetchAllForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)object
{
    return [self fetchAllForPredicate:predicate forManagedObjectContext:[object managedObjectContext]];
}

+ (id)fetchForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)object
{
    return [self fetchForPredicate:predicate forManagedObjectContext:[object managedObjectContext]];
}

#pragma mark - Fetch with Context
+ (BOOL)existsForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)contextOrNil
{
    return [[VICoreDataManager sharedInstance] countForClass:[self class]
                                               withPredicate:predicate
                                                  forContext:contextOrNil];
}

+ (NSArray *)fetchAllForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)contextOrNil
{
    return [[VICoreDataManager sharedInstance] arrayForClass:[self class]
                                               withPredicate:predicate
                                                  forContext:contextOrNil];
}

+ (id)fetchForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)contextOrNil
{
    NSArray *results = [self fetchAllForPredicate:predicate forManagedObjectContext:contextOrNil];

    NSUInteger count = [results count];
    if (count) {
        NSAssert(count == 1, @"Your predicate is returning more than 1 object, but the coredatamanger returns only one.");
        return [results lastObject];
    }

    return nil;
}

@end
