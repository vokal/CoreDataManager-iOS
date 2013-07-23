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
    return [[VICoreDataManager sharedInstance] dictionaryRepresentationOfManagedObject:self];
}

#pragma mark - Create Objects
+ (instancetype)newInstanceWithContext:(NSManagedObjectContext *)context
{
    return (id)[[VICoreDataManager sharedInstance] objectForClass:self inContext:context];
}


+ (instancetype)newInstance
{
    return [self newInstanceWithContext:[[VICoreDataManager sharedInstance] managedObjectContext]];
}

#pragma mark - Add Objects
+ (NSArray *)addWithArray:(NSArray *)inputArray forManagedObjectContext:(NSManagedObjectContext*)contextOrNil
{
    return [[VICoreDataManager sharedInstance] importArray:inputArray forClass:[self class] withContext:contextOrNil];
}

+ (instancetype)addWithDictionary:(NSDictionary *)inputDict forManagedObjectContext:(NSManagedObjectContext*)contextOrNil
{
    NSArray *array = [[VICoreDataManager sharedInstance] importArray:@[inputDict] forClass:[self class] withContext:contextOrNil];
    return array[0];
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

    if ([results count]) {
        return [results lastObject];
    }

    return nil;
}

@end
