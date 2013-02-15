//
//  VICoreDataManager.h
//  CoreData
//
//  Created by Anthony Alesia on 7/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define NOTIFICATION_ICLOUD_UPDATED     @"CDICloudUpdated"

@interface VICoreDataManager : NSObject
{
@private
    NSManagedObjectContext *_managedObjectContext;
    NSManagedObjectModel *_managedObjectModel;
    NSPersistentStoreCoordinator *_persistentStoreCoordinator;
    NSString *_resource;
    NSString *_database;
    NSString *_iCloudAppId;
}
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, strong) NSString *resource DEPRECATED_ATTRIBUTE;
@property (nonatomic, strong) NSString *database DEPRECATED_ATTRIBUTE;
@property (nonatomic, strong) NSString *iCloudAppId DEPRECATED_ATTRIBUTE;

+ (VICoreDataManager *)getInstance;

- (void)setResource:(NSString *)resource database:(NSString *)database;

//DEPRECATE: these should all be named <something>ForEntityNamed, not <something>ForModel
- (id)addObjectForModel:(NSString *)model context:(NSManagedObjectContext *)context DEPRECATED_ATTRIBUTE;
- (NSArray *)arrayForModel:(NSString *)model DEPRECATED_ATTRIBUTE;
- (NSArray *)arrayForModel:(NSString *)model forContext:(NSManagedObjectContext *)context DEPRECATED_ATTRIBUTE;
- (NSArray *)arrayForModel:(NSString *)model withPredicate:(NSPredicate *)predicate forContext:(NSManagedObjectContext *)context DEPRECATED_ATTRIBUTE;

- (id)addObjectForEntityNamed:(NSString *)entityName forContext:(NSManagedObjectContext *)context;
- (NSArray *)arrayForEntityNamed:(NSString *)entityName;
- (NSArray *)arrayForEntityNamed:(NSString *)entityName forContext:(NSManagedObjectContext *)context;
- (NSArray *)arrayForEntityNamed:(NSString *)entityName withPredicate:(NSPredicate *)predicate forContext:(NSManagedObjectContext *)context;

- (void)deleteObject:(id)object;

- (void)saveMainContext;

- (void)saveContext:(NSManagedObjectContext *)managedObjectContext;

- (void)dropTableForEntityWithName:(NSString *)name;

- (NSManagedObjectContext *)startTransaction;
- (void)endTransactionForContext:(NSManagedObjectContext *)context;
- (void)resetCoreData;

@end
