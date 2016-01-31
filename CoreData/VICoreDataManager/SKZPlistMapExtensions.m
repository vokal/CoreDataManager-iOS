//
//  SKZPlistMapExtensions.m
//  SkillzSDK-iOS
//
//  Created by John Graziano on 1/29/16.
//  Copyright © 2016 Skillz. All rights reserved.
//

#import "SKZPlistMapExtensions.h"
#import "VIManagedObject.h"
#import "VICoreDataManagerSKZ.h"
#import "VIManagedObjectMapperSKZ.h"

NSString *SKZArchivedClassName = @"_isa";


@implementation NSObject (SKZPlistMapExtensions)

- (id)createObjectForKey:(NSString *)key owner:(id)owner context:(NSManagedObjectContext *)context
{
    return self;
}

@end

@implementation NSArray (SKZPlistMapExtensions)


- (id)createObjectForKey:(nonnull NSString *)key owner:(id)owner context:(NSManagedObjectContext *)context
{
    NSUInteger count = [self count];
    id members[count];
    NSUInteger i = 0;
    
    for ( id plistObj in self )
    {
        members[i] = [plistObj createObjectForKey:key owner:owner context:context];
        i++;
    }
    
    NSSet *memberSet = [NSSet setWithObjects:members count:count];
    return memberSet;
}

@end

@implementation NSDictionary (SKZPlistMapExtensions)

- (id)createObjectForKey:(NSString *)ownerKey className:(NSString *)className owner:(id)owner context:(NSManagedObjectContext *)context
{
    id managedRootObject = nil;
    
    if ( className == Nil )
    {
        return self;     // No class specifier found, return as raw dict
    }
    
    Class managedObjectClass = NSClassFromString(className);
    
    if ( managedObjectClass == Nil )
    {
        return self;    // No class found, return as raw dict
    }
    
    VICoreDataManagerSKZ *cdm = [VICoreDataManagerSKZ sharedInstance];
    context = [cdm safeContext:context];
    
    VIManagedObjectMapperSKZ *mapper = [cdm mapperForClass:managedObjectClass];
    
    id comparisonValue = [self objectForKey:mapper.foreignUniqueComparisonKey];
    
    // check for existing object with matching key
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:className];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(%K == %@)", mapper.uniqueComparisonKey, comparisonValue];
    
    NSError *error;
    NSArray *matchingObjects = [context executeFetchRequest:fetchRequest error:&error];
    
    if (error)
    {
        CDLog(@"%s Fetch Request Error\n%@",__PRETTY_FUNCTION__ ,[error localizedDescription]);
    }

    NSUInteger matchingObjectsCount = matchingObjects.count;
    
    if ( matchingObjectsCount > 0 )
    {
        NSAssert(matchingObjectsCount < 2, @"UNIQUE IDENTIFIER IS NOT UNIQUE. MORE THAN ONE MATCHING OBJECT FOUND");
        managedRootObject = matchingObjects[0];
    }
    else
    {
        // no match found, so create a new one
        managedRootObject = [cdm managedObjectOfClass:managedObjectClass inContext:context];
    }
    
    // assign properties and subobjects
    for ( NSString * inputKeyPath in self )
    {
        id plistValue = [self objectForKey:inputKeyPath];
        VIManagedObjectMapSKZ *map = [mapper mapForInputKeyPath:inputKeyPath];
        NSString *coreDataKey = map.coreDataKey;
        
        if ( coreDataKey == nil )
        {
            continue;
        }
        
        id managedSubObj = [plistValue createObjectForKey:coreDataKey owner:managedRootObject context:context];
        
        // should we put a checkClass here?
        
        if ( managedSubObj != nil )
        {
            [managedRootObject safeSetValueSKZ:managedSubObj forKey:coreDataKey];
        }
    }
    
    return managedRootObject;
}

- (id)createObjectForKey:(nonnull NSString *)key owner:(id)owner context:(NSManagedObjectContext *)context
{
    NSString *className = [self objectForKey:SKZArchivedClassName];
    
    return [self createObjectForKey:key className:className owner:owner context:context];
}

@end

@implementation NSString (SKZPlistMapExtensions)

- (id)createObjectForKey:(nonnull NSString *)key owner:(id)owner context:(NSManagedObjectContext *)context
{
    if ( [key isEqualToString:SKZArchivedClassName] )
    {
        return nil;
    }
    
    VICoreDataManagerSKZ *cdm = [VICoreDataManagerSKZ sharedInstance];
    VIManagedObjectMapperSKZ *mapper = [cdm mapperForClass:[owner class]];
    VIManagedObjectMapSKZ *map = [mapper mapForCoreDataKey:key];
    
    id convertedObj = nil;
    
    if ( (convertedObj = [map.dateFormatter dateFromString:self]) != nil )
    {
        return convertedObj;
    }
    
    if ( (convertedObj = [map.numberFormatter numberFromString:self]) != nil )
    {
        return convertedObj;
    }
    
    return [super createObjectForKey:key owner:owner context:context];
}
    
                             
@end


