//
//  VICoreDataManager.h
//  CoreData
//
//  Created by Anthony Alesia on 7/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define NOTIFICATION_DATA_UPDATED       @"CDDataUpdated"
#define NOTIFICATION_ICLOUD_UPDATED     @"CDICloudUpdated"

@interface VICoreDataManager : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, strong) NSString *resource;
@property (nonatomic, strong) NSString *database;
@property (nonatomic, strong) NSString *iCloudAppId;

+ (VICoreDataManager *)getInstance;

- (void)setResource:(NSString *)resource database:(NSString *)database;

- (void)saveMainContext;
- (void)saveContext:(NSManagedObjectContext *)managedObjectContex;

- (void)resetCoreData;
- (void)deleteObject:(id)object;
- (void)dropTableForEntityWithName:(NSString*)name;

- (id)addObjectForModel:(NSString *)model context:(NSManagedObjectContext *)context;
- (NSArray *)arrayForModel:(NSString *)model;
- (NSArray *)arrayForModel:(NSString *)model forContext:(NSManagedObjectContext *)context;
- (NSArray *)arrayForModel:(NSString *)model withPredicate:(NSPredicate *)predicate forContext:(NSManagedObjectContext *)context;

- (NSManagedObjectContext *)startTransaction;
- (void)endTransactionForContext:(NSManagedObjectContext *)context;

@end
