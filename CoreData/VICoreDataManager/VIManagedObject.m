//
//  VIManagedObject.m
//  CoreData
//
//  Created by Anthony Alesia on 7/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VIManagedObject.h"

@implementation VIManagedObject

#pragma mark - No Relationship

+ (id)addWithArray:(NSArray *)array forManagedObjectContext:(NSManagedObjectContext *)context
{
    NSMutableArray*createdObjects = [@[] mutableCopy];
    
    if ([self cleanForArray:array forManagedObjectContext:context]) {
        for (NSDictionary *params in array) {
            id obj = [self addWithParams:params forManagedObjectContext:context];
            if (obj !=nil) {
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
    NSManagedObject *object = [[VICoreDataManager getInstance] addObjectForModel:NSStringFromClass([self class])
                                                                         context:context];
    
    return [self setInformationFromDictionary:params forObject:object];
}

+ (BOOL)existsForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)context
{
    return [self fetchForPredicate:predicate forManagedObjectContext:context] != nil;
}

+ (id)fetchForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)context
{
    NSArray *results = [[VICoreDataManager getInstance] arrayForModel:NSStringFromClass([self class])
                                                        withPredicate:predicate
                                                           forContext:context];
    
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
            if (obj !=nil) {
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
    NSManagedObject *object = [[VICoreDataManager getInstance] addObjectForModel:NSStringFromClass([self class])
                                                                         context:[managedObject managedObjectContext]];
    
    return [self setInformationFromDictionary:params forObject:object];
}

+ (BOOL)existsForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)managedObject
{
    return [self fetchForPredicate:predicate forManagedObject:managedObject] != nil;
}

+ (id)fetchForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)managedObject
{
    NSArray *results = [[VICoreDataManager getInstance] arrayForModel:NSStringFromClass([self class])
                                                        withPredicate:predicate
                                                           forContext:[managedObject managedObjectContext]];
    
    if ([results count] > 0) {
        return [results lastObject];
    }
    
    return nil;
}

#pragma mark - Set Content

+ (id)setInformationFromDictionary:(NSDictionary *)params forObject:(NSManagedObject *)object
{
    return object;
}

+ (id)attribute:(id)attribute forParam:(id)param
{
    if ([[NSNull null] isEqual:param]) {
        return attribute;
    }
    
    return param;
}

@end
