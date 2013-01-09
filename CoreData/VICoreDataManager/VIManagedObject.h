//
//  VIManagedObject.h
//  CoreData
//
//  Created by Anthony Alesia on 7/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "VICoreDataManager.h"

@interface VIManagedObject : NSManagedObject

//Use If No Relationship Is Being Made

+ (id)addWithArray:(NSArray *)array forManagedObjectContext:(NSManagedObjectContext *)context;
+ (BOOL)cleanForArray:(NSArray *)array forManagedObjectContext:(NSManagedObjectContext *)context;
+ (id)addWithParams:(NSDictionary *)params forManagedObjectContext:(NSManagedObjectContext *)context;
+ (id)editWithParams:(NSDictionary *)params forObject:(NSManagedObject*)object;
+ (id)syncWithParams:(NSDictionary *)params forManagedObjectContext:(NSManagedObjectContext *)context;
+ (BOOL)existsForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)context;
+ (id)fetchForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)context;

//Use If A Relationship Is Being Made

+ (id)addWithArray:(NSArray *)array forManagedObject:(NSManagedObject *)managedObject;
+ (BOOL)cleanForArray:(NSArray *)array forManagedObject:(NSManagedObject *)managedObject;
+ (id)addWithParams:(NSDictionary *)params forManagedObject:(NSManagedObject *)managedObject;
+ (id)editWithParams:(NSDictionary *)params forObject:(NSManagedObject*)object forManagedObject:(NSManagedObject *)managedObject;
+ (id)syncWithParams:(NSDictionary *)params forManagedObject:(NSManagedObject *)managedObject;
+ (BOOL)existsForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)managedObject;
+ (id)fetchForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)managedObject;

//Set Content (should always be overwritten)

+ (id)setInformationFromDictionary:(NSDictionary *)params forObject:(NSManagedObject *)object;
+ (id)attribute:(id)attribute forParam:(id)param;

@end
