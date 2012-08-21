//
//  VICoreDataManager.m
//  CoreData
//
//  Created by Anthony Alesia on 7/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VICoreDataManager.h"

@interface VICoreDataManager ()

- (NSURL *)applicationDocumentsDirectory;
- (NSManagedObjectContext *)tempManagedObjectContext;
- (void)saveTempContext:(NSManagedObjectContext *)tempContext;
- (void)tempContextSaved:(NSNotification *)notification;
- (NSManagedObject *)clone:(NSManagedObject *)source inContext:(NSManagedObjectContext *)context;

@end

@implementation VICoreDataManager

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize resource = _resource;
@synthesize database = _database;
@synthesize iCloudAppId = _iCloudAppId;

+ (VICoreDataManager *)getInstance
{
    static dispatch_once_t pred = 0;
    __strong static VICoreDataManager  *_sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (void)setResource:(NSString *)resource database:(NSString *)database
{
    _resource = resource;
    _database = database;
}

#pragma mark - CDMethods

- (id)addObjectForModel:(NSString *)model context:(NSManagedObjectContext *)context 
{
    return [NSEntityDescription insertNewObjectForEntityForName:model
                                              inManagedObjectContext:context];
}

- (NSArray *)arrayForModel:(NSString *)model 
{
    return [self arrayForModel:model forContext:_managedObjectContext];
}

- (NSArray *)arrayForModel:(NSString *)model forContext:(NSManagedObjectContext *)context
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:model
                                              inManagedObjectContext:context];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    
    return [context executeFetchRequest:fetchRequest error:nil];
}

- (NSArray *)arrayForModel:(NSString *)model withPredicate:(NSPredicate *)predicate forContext:(NSManagedObjectContext *)context
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:model
                                              inManagedObjectContext:context];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    
    return [context executeFetchRequest:fetchRequest error:nil];
}

- (void)deleteObject:(id)object 
{
    [[(NSManagedObject *)object managedObjectContext] deleteObject:(NSManagedObject *)object];
}

#pragma mark - CD Save Delete

- (void)saveMainContext
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self saveContext:_managedObjectContext];
    });
}   

- (void)saveContext:(NSManagedObjectContext *)managedObjectContex
{
    NSError *error = nil;
    if (managedObjectContex != nil) {
        if ([managedObjectContex hasChanges] && ![managedObjectContex save:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        } 
    }
}

- (void)saveTempContext:(NSManagedObjectContext *)tempContext
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tempContextSaved:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:tempContext];
    
    [self saveContext:tempContext];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextDidSaveNotification
                                                  object:tempContext];
    
}

- (void)tempContextSaved:(NSNotification *)notification 
{
    id mergePolicy = [[NSMergePolicy alloc] initWithMergeType:NSOverwriteMergePolicyType];
    
    [_managedObjectContext setMergePolicy:mergePolicy];
    
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground) {
        [_managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
        });
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DATA_UPDATED
                                                        object:nil];
}

- (void)resetCoreData 
{
    NSArray *stores = [_persistentStoreCoordinator persistentStores];
    
    for(NSPersistentStore *store in stores) {
        [_persistentStoreCoordinator removePersistentStore:store error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:store.URL.path error:nil];
    }
    
    _persistentStoreCoordinator = nil;
}

- (NSManagedObjectContext *)startTransaction
{
    return [self tempManagedObjectContext];
}

- (void)endTransactionForContext:(NSManagedObjectContext *)context
{
    if ([context hasChanges]) {
        [self saveTempContext:context];
    }
}

#pragma mark - Core Data Stack

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        
        [_managedObjectContext performBlockAndWait:^{
            [_managedObjectContext setPersistentStoreCoordinator:coordinator];
            [_managedObjectContext setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
            
            if ([_iCloudAppId length] > 0) {
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(mergeChangesFrom_iCloud:)
                                                             name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                                           object:coordinator];
            }
        }];
    }
    
    return _managedObjectContext;
}

- (NSManagedObjectContext *)tempManagedObjectContext 
{
    NSManagedObjectContext *tempManagedObjectContext = nil;
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    
    if (coordinator != nil) {
        tempManagedObjectContext = [[NSManagedObjectContext alloc] init];
        [tempManagedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    
    return tempManagedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:_resource withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:_database];
    
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
                                       initWithManagedObjectModel:[self managedObjectModel]];
    
    if ([_iCloudAppId length] > 0) {
        [self setupICloudForPersistantStoreCoordinator:_persistentStoreCoordinator];
    } else if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                       configuration:nil 
                                                                 URL:storeURL 
                                                             options:options 
                                                               error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }    
    
    return _persistentStoreCoordinator;
}

- (void)setupICloudForPersistantStoreCoordinator:(NSPersistentStoreCoordinator *)psc
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *iCloudEnabledAppID = _iCloudAppId;
        NSString *dataFileName = _database;
        NSString *iCloudDataDirectoryName = @"Data.nosync";
        NSString *iCloudLogsDirectoryName = @"Logs";
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *localStore = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:dataFileName];
        NSURL *iCloud = [fileManager URLForUbiquityContainerIdentifier:nil];
        
        if (iCloud) {
            
            NSLog(@"iCloud is working");
            
            NSURL *iCloudLogsPath = [NSURL fileURLWithPath:[[iCloud path] stringByAppendingPathComponent:iCloudLogsDirectoryName]];
            
            NSLog(@"iCloudEnabledAppID = %@",iCloudEnabledAppID);
            NSLog(@"dataFileName = %@", dataFileName);
            NSLog(@"iCloudDataDirectoryName = %@", iCloudDataDirectoryName);
            NSLog(@"iCloudLogsDirectoryName = %@", iCloudLogsDirectoryName);
            NSLog(@"iCloud = %@", iCloud);
            NSLog(@"iCloudLogsPath = %@", iCloudLogsPath);
            
            if([fileManager fileExistsAtPath:[[iCloud path] stringByAppendingPathComponent:iCloudDataDirectoryName]] == NO) {
                NSError *fileSystemError;
                [fileManager createDirectoryAtPath:[[iCloud path] stringByAppendingPathComponent:iCloudDataDirectoryName]
                       withIntermediateDirectories:YES
                                        attributes:nil
                                             error:&fileSystemError];
                if(fileSystemError != nil) {
                    NSLog(@"Error creating database directory %@", fileSystemError);
                }
            }
            
            NSString *iCloudData = [[[iCloud path]
                                     stringByAppendingPathComponent:iCloudDataDirectoryName]
                                    stringByAppendingPathComponent:dataFileName];
            
            NSLog(@"iCloudData = %@", iCloudData);
            
            NSMutableDictionary *options = [NSMutableDictionary dictionary];
            [options setObject:[NSNumber numberWithBool:YES] forKey:NSMigratePersistentStoresAutomaticallyOption];
            [options setObject:[NSNumber numberWithBool:YES] forKey:NSInferMappingModelAutomaticallyOption];
            [options setObject:iCloudEnabledAppID            forKey:NSPersistentStoreUbiquitousContentNameKey];
            [options setObject:iCloudLogsPath                forKey:NSPersistentStoreUbiquitousContentURLKey];
            
            [psc lock];
            
            [psc addPersistentStoreWithType:NSSQLiteStoreType
                              configuration:nil
                                        URL:[NSURL fileURLWithPath:iCloudData]
                                    options:options
                                      error:nil];
            
            [psc unlock];
        } else {
            NSLog(@"iCloud is NOT working - using a local store");
            NSMutableDictionary *options = [NSMutableDictionary dictionary];
            [options setObject:[NSNumber numberWithBool:YES] forKey:NSMigratePersistentStoresAutomaticallyOption];
            [options setObject:[NSNumber numberWithBool:YES] forKey:NSInferMappingModelAutomaticallyOption];
            
            [psc lock];
            
            [psc addPersistentStoreWithType:NSSQLiteStoreType
                              configuration:nil
                                        URL:localStore
                                    options:options
                                      error:nil];
            [psc unlock];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_ICLOUD_UPDATED
                                                                object:nil
                                                              userInfo:nil];
        });
    });
}

- (void)mergeChangesFrom_iCloud:(NSNotification *)notification {
    
	NSLog(@"Merging in changes from iCloud...");
    
    NSManagedObjectContext* moc = [self managedObjectContext];
    
    [moc performBlock:^{
        
        [moc mergeChangesFromContextDidSaveNotification:notification];
        
        NSNotification* refreshNotification = [NSNotification notificationWithName:NOTIFICATION_ICLOUD_UPDATED
                                                                            object:nil
                                                                          userInfo:[notification userInfo]];
        
        [[NSNotificationCenter defaultCenter] postNotification:refreshNotification];
    }];
}

#pragma mark - Application's Documents directory

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - deep copy

- (NSManagedObject *) clone:(NSManagedObject *)source inContext:(NSManagedObjectContext *)context{
    NSString *entityName = [[source entity] name];
    
    NSManagedObject *cloned = [NSEntityDescription
                               insertNewObjectForEntityForName:entityName
                               inManagedObjectContext:context];
    
    NSDictionary *attributes = [[NSEntityDescription
                                 entityForName:entityName
                                 inManagedObjectContext:context] attributesByName];
    
    for (NSString *attr in attributes) {
        [cloned setValue:[source valueForKey:attr] forKey:attr];
    }
    
    NSDictionary *relationships = [[NSEntityDescription
                                    entityForName:entityName
                                    inManagedObjectContext:context] relationshipsByName];
    for (NSRelationshipDescription *rel in relationships){
        NSString *keyName = [NSString stringWithFormat:@"%@",rel];
        NSMutableSet *sourceSet = [source mutableSetValueForKey:keyName];
        NSMutableSet *clonedSet = [cloned mutableSetValueForKey:keyName];
        NSEnumerator *e = [sourceSet objectEnumerator];
        NSManagedObject *relatedObject;
        while ( relatedObject = [e nextObject]){
            NSManagedObject *clonedRelatedObject = [self clone:relatedObject 
                                                     inContext:context];
            [clonedSet addObject:clonedRelatedObject];
        }
        
    }
    
    return cloned;
}

@end
