//
//  VICoreDataManager.m
//  CoreData
//

#import "VICoreDataManagerSKZ.h"

@interface VICoreDataManagerSKZ () {
    NSManagedObjectContext *_managedObjectContext;
    NSManagedObjectModel *_managedObjectModel;
    NSPersistentStoreCoordinator *_persistentStoreCoordinator;
}

@property (copy) NSString *resource;
@property (copy) NSString *databaseFilename;
@property NSMutableDictionary *mapperCollection;

//Getters
- (NSManagedObjectContext *)tempManagedObjectContext;
- (NSManagedObjectContext *)managedObjectContext;
- (NSManagedObjectModel *)managedObjectModel;
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;

//Initializers
- (void)initManagedObjectModel;
- (void)initPersistentStoreCoordinator;
- (void)initManagedObjectContext;

//Thread Safety with Main MOC
- (NSManagedObjectContext *)safeContext:(NSManagedObjectContext *)context;

//Context Saving and Merging
- (void)saveContext:(NSManagedObjectContext *)managedObjectContext;
- (void)saveTempContext:(NSManagedObjectContext *)tempContext;
- (void)tempContextSaved:(NSNotification *)notification;

//Convenience Methods
- (NSFetchRequest *)fetchRequestWithClass:(Class)managedObjectClass predicate:(NSPredicate *)predicate;
- (NSURL *)applicationLibraryDirectory;

@end

//private interface to VIManagedObjectMapper
@interface VIManagedObjectMapperSKZ (dictionaryInputOutput)
- (void)setInformationFromDictionary:(NSDictionary *)inputDict forManagedObject:(NSManagedObject *)object;
- (NSDictionary *)dictionaryRepresentationOfManagedObject:(NSManagedObject *)object;
- (NSDictionary *)hierarchicalDictionaryRepresentationOfManagedObject:(NSManagedObject *)object;
@end

@implementation VICoreDataManagerSKZ

+ (void)initialize
{
    //make sure the shared instance is ready
    [self sharedInstance];
}

+ (NSManagedObjectContext *)contextForCurrentThread
{
    if ([NSOperationQueue mainQueue] == [NSOperationQueue currentQueue]) {
        return [[VICoreDataManagerSKZ sharedInstance] managedObjectContext];
    } else {
        return [[VICoreDataManagerSKZ sharedInstance] temporaryContext];
    }
}

NSOperationQueue *VI_WritingQueue;
VICoreDataManagerSKZ *VI_SharedObject;
+ (VICoreDataManagerSKZ *)sharedInstance
{
    static dispatch_once_t pred;
    dispatch_once(&pred,^{
        VI_SharedObject = [[self alloc] init];
        VI_WritingQueue = [[NSOperationQueue alloc] init];
        [VI_WritingQueue setMaxConcurrentOperationCount:1];
    });
    return VI_SharedObject;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _mapperCollection = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setResource:(NSString *)resource database:(NSString *)database
{
    self.resource = resource;
    self.databaseFilename = database;
    
    [self initPersistentStoreCoordinator];
}

#pragma mark - Getters
- (NSManagedObjectContext *)tempManagedObjectContext
{
    NSManagedObjectContext *tempManagedObjectContext;

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];

    if (coordinator) {
        tempManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
        [tempManagedObjectContext setPersistentStoreCoordinator:coordinator];
    } else {
        CDLog(@"Coordinator is nil & context is %@", [tempManagedObjectContext description]);
    }

    return tempManagedObjectContext;
}

- (NSManagedObjectContext *)managedObjectContext
{
    if (!_managedObjectContext) {
        [self initManagedObjectContext];
    }

    return _managedObjectContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (!_managedObjectModel) {
        [self initManagedObjectModel];
    }

    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (!_persistentStoreCoordinator) {
        [self initPersistentStoreCoordinator];
    }

    return _persistentStoreCoordinator;
}

#pragma mark - Initializers
- (void)initManagedObjectModel
{
    NSURL *modelURL = [[NSBundle skillzBundle] URLForResource:self.resource withExtension:@"momd"];
    SKZLog(@"model URL %@", modelURL);
    if (!modelURL) {
        modelURL = [[NSBundle skillzBundle] URLForResource:self.resource withExtension:@"mom"];
        SKZLog(@"model URL %@", modelURL);
        
        if (!modelURL)
        {
            modelURL = [[NSBundle skillzBundle] URLForResource:self.resource withExtension:@"momd" subdirectory:@"SkillzDataModel.momd"];
            SKZLog(@"model URL %@", modelURL);
        }
        if (!modelURL)
        {
            modelURL = [[NSBundle skillzBundle] URLForResource:self.resource withExtension:@"mom" subdirectory:@"SkillzDataModel.momd"];
            SKZLog(@"model URL %@", modelURL);
        }

    }
    NSAssert(modelURL != nil, @"Managed object model not found.");
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
}

- (void)initPersistentStoreCoordinator
{
    NSAssert([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue], @"Must be on the main queue when initializing persistant store coordinator");
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @(YES),
                              NSInferMappingModelAutomaticallyOption: @(YES)};
    
    NSError *error;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

    NSURL *storeURL;
    NSString *storeType = NSInMemoryStoreType;
    if (self.databaseFilename) {
        storeURL = [[self applicationLibraryDirectory] URLByAppendingPathComponent:self.databaseFilename];
        storeType = NSSQLiteStoreType;
    }


    NSDictionary *previousModelVersionHashes = [self fetchModelVersionHashes:storeURL forStoreType:storeType];

    if (![_persistentStoreCoordinator addPersistentStoreWithType:storeType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:options
                                                           error:&error])
    {
        [self resetPersistantStore:storeURL forStoreType:storeType];
    } else if (previousModelVersionHashes.count) {
        NSDictionary *newModelVersionHashes = [self fetchModelVersionHashes:storeURL forStoreType:storeType];
        if (![previousModelVersionHashes isEqual:newModelVersionHashes]) {
            NSPersistentStore *outdatedStore = [_persistentStoreCoordinator persistentStoreForURL:storeURL];
            [_persistentStoreCoordinator removePersistentStore:outdatedStore error:&error];
            [self resetPersistantStore:storeURL forStoreType:storeType];
        }
    }
}

- (void)resetPersistantStore:(NSURL *)storeURL forStoreType:(NSString *)storeType
{
    NSError *error;
    CDLog(@"Full database delete and rebuild");
    [[NSFileManager defaultManager] removeItemAtPath:storeURL.path error:nil];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:storeType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:nil
                                                           error:&error])
    {
        CDLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

- (NSDictionary *)fetchModelVersionHashes:(NSURL *)storeURL forStoreType:(NSString *)storeType
{
    NSError *error;
    NSDictionary *storeMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:storeType URL:storeURL error:&error];
    if (!storeMetadata) {
        return nil;
    } else {
        return storeMetadata[@"NSStoreModelVersionHashes"];
    }
}

- (void)initManagedObjectContext
{
    NSAssert([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue], @"Must be on the main queue when initializing main context");
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];

    if (coordinator) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];

        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
        id mergePolicy = [[NSMergePolicy alloc] initWithMergeType:NSMergeByPropertyObjectTrumpMergePolicyType];
        [_managedObjectContext setMergePolicy:mergePolicy];
    }
}

#pragma mark - Create and configure
- (NSManagedObject *)managedObjectOfClass:(Class)managedObjectClass inContext:(NSManagedObjectContext *)contextOrNil
{
    contextOrNil = [self safeContext:contextOrNil];
    return [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass(managedObjectClass) inManagedObjectContext:contextOrNil];
}

- (BOOL)setObjectMapper:(VIManagedObjectMapperSKZ *)objMapper forClass:(Class)objectClass
{
    if (objMapper && objectClass) {
        (self.mapperCollection)[NSStringFromClass(objectClass)] = objMapper;
        return YES;
    }

    return NO;
}

- (NSArray *)importArray:(NSArray *)inputArray forClass:(Class)objectClass withContext:(NSManagedObjectContext*)contextOrNil;
{
    VIManagedObjectMapperSKZ *mapper = [self mapperForClass:objectClass];

    contextOrNil = [self safeContext:contextOrNil];

    NSArray *existingObjectArray;

    if (mapper.uniqueComparisonKey) {
        NSMutableArray *safeArrayOfUniqueKeys = [NSMutableArray array];
        NSArray *arrayOfUniqueKeys = [inputArray valueForKey:mapper.foreignUniqueComparisonKey];
        NSNull *nullObj = [NSNull null];
        [arrayOfUniqueKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if (![nullObj isEqual:obj]) {
                [safeArrayOfUniqueKeys addObject:obj];
            }
        }];
        arrayOfUniqueKeys = [safeArrayOfUniqueKeys copy];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(%K IN %@)", mapper.uniqueComparisonKey, arrayOfUniqueKeys];
        existingObjectArray = [self arrayForClass:objectClass withPredicate:predicate forContext:contextOrNil];
    }
    
    NSMutableArray *returnArray = [NSMutableArray array];
    [inputArray enumerateObjectsUsingBlock:^(NSDictionary *inputDict, NSUInteger idx, BOOL *stop) {
        if (![inputDict isKindOfClass:[NSDictionary class]]) {
            CDLog(@"ERROR\nExpecting an NSArray full of NSDictionaries");
            return;
        }

        NSManagedObject *returnObject;

        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", mapper.uniqueComparisonKey, [inputDict valueForKey:mapper.foreignUniqueComparisonKey]];
        NSArray *matchingObjects = [existingObjectArray filteredArrayUsingPredicate:predicate];
        NSUInteger matchingObjectsCount = [matchingObjects count];
        if (matchingObjectsCount) {
            NSAssert(matchingObjectsCount < 2, @"UNIQUE IDENTIFIER IS NOT UNIQUE. MORE THAN ONE MATCHING OBJECT FOUND");
            returnObject = matchingObjects[0];
            if (mapper.overwriteObjectsWithServerChanges) {
                [self setInformationFromDictionary:inputDict forManagedObject:returnObject];
            }
        } else {
            returnObject = [self managedObjectOfClass:objectClass inContext:contextOrNil];
            [self setInformationFromDictionary:inputDict forManagedObject:returnObject];
        }
        [returnArray addObject:returnObject];
    }];
    
    return [returnArray copy];
}

- (void)setInformationFromDictionary:(NSDictionary *)inputDict forManagedObject:(NSManagedObject *)object
{
    VIManagedObjectMapperSKZ *mapper = [self mapperForClass:[object class]];
    [mapper setInformationFromDictionary:inputDict forManagedObject:object];
}

#pragma mark - Convenient Output
- (NSDictionary *)dictionaryRepresentationOfManagedObject:(NSManagedObject *)object respectKeyPaths:(BOOL)keyPathsEnabled
{
    VIManagedObjectMapperSKZ *mapper = [self mapperForClass:[object class]];
    if (keyPathsEnabled) {
        return [mapper hierarchicalDictionaryRepresentationOfManagedObject:object];
    } else {
        return [mapper dictionaryRepresentationOfManagedObject:object];
    }
}

#pragma mark - Count, Fetch, and Delete
- (NSUInteger)countForClass:(Class)managedObjectClass
{
    return [self countForClass:managedObjectClass forContext:nil];
}

- (NSUInteger)countForClass:(Class)managedObjectClass forContext:(NSManagedObjectContext *)contextOrNil
{
    return [self countForClass:managedObjectClass withPredicate:nil forContext:contextOrNil];
}

- (NSUInteger)countForClass:(Class)managedObjectClass withPredicate:(NSPredicate *)predicate forContext:(NSManagedObjectContext *)contextOrNil
{
    contextOrNil = [self safeContext:contextOrNil];
    NSFetchRequest *fetchRequest = [self fetchRequestWithClass:managedObjectClass predicate:predicate];

    NSError *error;
    NSUInteger count = [contextOrNil countForFetchRequest:fetchRequest error:&error];
    if (error) {
        CDLog(@"%s Fetch Request Error\n%@",__PRETTY_FUNCTION__ ,[error localizedDescription]);
    }

    return count;
}

- (NSArray *)arrayForClass:(Class)managedObjectClass
{
    return [self arrayForClass:managedObjectClass forContext:nil];
}

- (NSArray *)arrayForClass:(Class)managedObjectClass forContext:(NSManagedObjectContext *)contextOrNil
{
    return [self arrayForClass:managedObjectClass withPredicate:nil forContext:contextOrNil];
}

- (NSArray *)arrayForClass:(Class)managedObjectClass withPredicate:(NSPredicate *)predicate forContext:(NSManagedObjectContext *)contextOrNil
{
    contextOrNil = [self safeContext:contextOrNil];
    NSFetchRequest *fetchRequest = [self fetchRequestWithClass:managedObjectClass predicate:predicate];

    NSError *error;
    NSArray *results = [contextOrNil executeFetchRequest:fetchRequest error:&error];
    if (error) {
        CDLog(@"%s Fetch Request Error\n%@",__PRETTY_FUNCTION__ ,[error localizedDescription]);
    }

    return results;
}

- (void)deleteObject:(NSManagedObject *)object
{
    [[object managedObjectContext] deleteObject:object];
}

- (BOOL)deleteAllObjectsOfClass:(Class)managedObjectClass context:(NSManagedObjectContext *)contextOrNil
{
    contextOrNil = [self safeContext:contextOrNil];
    NSFetchRequest *fetchRequest = [self fetchRequestWithClass:managedObjectClass predicate:nil];
    [fetchRequest setIncludesPropertyValues:NO];
    [fetchRequest setReturnsObjectsAsFaults:YES];

    NSError *error;
    NSArray *results = [contextOrNil executeFetchRequest:fetchRequest error:&error];
    if (error) {
        CDLog(@"%s Fetch Request Error\n%@",__PRETTY_FUNCTION__ ,[error localizedDescription]);
        return NO;
    }

    [results enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [contextOrNil deleteObject:obj];
    }];

    return YES;
}

#pragma mark - Thread Safety with Main MOC
- (NSManagedObjectContext *)safeContext:(NSManagedObjectContext *)context
{
    if (!context) {
        context = [self managedObjectContext];
    }

    if (context == [self managedObjectContext]) {
        NSAssert([NSOperationQueue currentQueue] == [NSOperationQueue mainQueue], @"XXX ALERT ALERT XXXX\nNOT ON MAIN QUEUE!");
    }

    return context;
}

#pragma mark - Context Saving and Merging
- (void)saveMainContext
{
    if ([NSOperationQueue mainQueue] == [NSOperationQueue currentQueue]) {
        [self saveContext:[self managedObjectContext]];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self saveContext:[self managedObjectContext]];
        });
    }
}

- (void)saveMainContextAndWait
{
    if ([NSOperationQueue mainQueue] == [NSOperationQueue currentQueue]) {
        [self saveContext:[self managedObjectContext]];
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self saveContext:[self managedObjectContext]];
        });
    }
}

- (void)saveContext:(NSManagedObjectContext *)context
{
    NSError *error;
    if (![context save:&error]) {
        CDLog(@"Unresolved error %@, %@", error, [error localizedDescription]);
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
    dispatch_async(dispatch_get_main_queue(), ^{
        @try {
            [[self managedObjectContext] mergeChangesFromContextDidSaveNotification:notification];
            [[self managedObjectContext] processPendingChanges];
        }
        @catch (NSException *exception) {}
    });
}

- (NSManagedObjectContext *)temporaryContext
{
    return [self tempManagedObjectContext];
}

- (void)saveAndMergeWithMainContext:(NSManagedObjectContext *)context
{
    NSAssert(context != [self managedObjectContext], @"This is NOT for saving the main context.");
    [self saveTempContext:context];
}

#pragma mark - Convenience Methods
NSInteger blockNumber = 0;

+ (void)writeToTemporaryContext:(void (^)(NSManagedObjectContext *tempContext))writeBlock
                     completion:(void (^)(void))completion
{
#if WRITE_QUEUE_LOGGING
    blockNumber++;
    NSInteger blockId = blockNumber;
#endif
    
    [[VICoreDataManagerSKZ sharedInstance] managedObjectContext];
    NSAssert(writeBlock, @"Write block must not be nil");

    WriteQueueLog(@"%ld Add Block", (long)blockId);
    
    [VI_WritingQueue addOperationWithBlock:^{
        WriteQueueLog(@"%ld Begin write",  (long)blockId);
        NSManagedObjectContext *tempContext = [[VICoreDataManagerSKZ sharedInstance] temporaryContext];
        writeBlock(tempContext);
#if WRITE_QUEUE_LOGGING
        Class insertedClass = [[[tempContext insertedObjects] anyObject] class];
        Class updatedClass = [[[tempContext updatedObjects] anyObject] class];
#endif
        [[VICoreDataManagerSKZ sharedInstance] saveAndMergeWithMainContext:tempContext];
        
#if WRITE_QUEUE_LOGGING
        WriteQueueLog(@"%ld Finish write took %.2f secs",  (long)blockId, [[NSDate date] timeIntervalSinceDate:startDate]);
        if (insertedClass) {
            WriteQueueLog(@"%@ inserted", NSStringFromClass(insertedClass));
        }
        
        if (updatedClass) {
            WriteQueueLog(@"%@ updated", NSStringFromClass(updatedClass));
        }
#endif
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    }];
}

- (NSFetchRequest *)fetchRequestWithClass:(Class)managedObjectClass predicate:(NSPredicate *)predicate
{
    NSString *entityName = NSStringFromClass(managedObjectClass);
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setReturnsObjectsAsFaults:NO];
    return fetchRequest;
}

- (VIManagedObjectMapperSKZ *)mapperForClass:(Class)objectClass
{
    NSString *className = NSStringFromClass(objectClass);
    VIManagedObjectMapperSKZ * mapper = self.mapperCollection[className];
    
    while (!mapper && objectClass)
    {
        objectClass = [objectClass superclass];
        mapper = self.mapperCollection[className];
        
        if (objectClass == [NSManagedObject class] && !mapper)
        {
            mapper = [VIManagedObjectMapperSKZ defaultMapper];
        }
    }
    
    return mapper;
}

- (NSURL *)applicationLibraryDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)resetCoreData
{
    NSArray *stores = [[self persistentStoreCoordinator] persistentStores];

    for(NSPersistentStore *store in stores) {
        [[self persistentStoreCoordinator] removePersistentStore:store error:nil];
        if (self.databaseFilename) {
            [[NSFileManager defaultManager] removeItemAtPath:store.URL.path error:nil];            
        }
    }
    
    _persistentStoreCoordinator = nil;
    _managedObjectContext = nil;
    _managedObjectModel = nil;
    [_mapperCollection removeAllObjects];
}

@end