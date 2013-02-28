#import "VICoreDataManager.h"
#import "VICoreDataManager+Testing.h"

NSString *const NOTIFICATION_ICLOUD_UPDATED = @"CDICloudUpdated";

NSString *const iCloudDataDirectoryName = @"Data.nosync";
NSString *const iCloudLogsDirectoryName = @"Logs";

@interface VICoreDataManager () {
    NSManagedObjectContext *_managedObjectContext;
    NSManagedObjectModel *_managedObjectModel;
    NSPersistentStoreCoordinator *_persistentStoreCoordinator;
}

@property (nonatomic, strong) NSString *resource;
@property (nonatomic, strong) NSString *databaseFilename;
@property (nonatomic, strong) NSString *iCloudAppId;
@property (nonatomic, strong) NSString *bundleIdentifier;

- (NSBundle *)bundle;

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
- (NSManagedObjectContext *)threadSafeContext:(NSManagedObjectContext *)context;

//Context Saving and Merging
- (void)saveContext:(NSManagedObjectContext *)managedObjectContext;
- (void)saveTempContext:(NSManagedObjectContext *)tempContext;
- (void)tempContextSaved:(NSNotification *)notification;

//iCloud Integration - DO NOT USE
- (void)setupiCloudForPersistantStoreCoordinator:(NSPersistentStoreCoordinator *)psc;
- (void)mergeChangesFromiCloud:(NSNotification *)notification;

//Convenience Methods
- (NSURL *)applicationDocumentsDirectory;
- (void)debugPersistentStore;

@end

static VICoreDataManager *_sharedObject = nil;

@implementation VICoreDataManager

+ (void)initialize
{
    //make sure the shared instance is ready
    [self getInstance];
}

+ (VICoreDataManager *)getInstance
{
    static dispatch_once_t pred;
    dispatch_once(&pred,^{
        _sharedObject = [[self alloc] init];
    });

    return _sharedObject;
}

- (void)setResource:(NSString *)resource database:(NSString *)database
{
    [self setResource:resource database:database iCloudAppId:nil];
}

- (void)setResource:(NSString *)resource database:(NSString *)database iCloudAppId:(NSString *)iCloudAppId
{
    [self setResource:resource database:database iCloudAppId:iCloudAppId forBundleIdentifier:nil];
}

- (void)setResource:(NSString *)resource database:(NSString *)database iCloudAppId:(NSString *)iCloudAppId forBundleIdentifier:(NSString *)bundleIdentifier
{
    self.resource = resource;
    self.databaseFilename = database;
    self.iCloudAppId = iCloudAppId;
    self.bundleIdentifier = bundleIdentifier;
}

- (NSBundle *)bundle
{
    // try your manually set bundle
    NSBundle *bundle = [NSBundle bundleWithIdentifier:self.bundleIdentifier];

    //default to main bundle
    if (!bundle) {
        bundle = [NSBundle mainBundle];
    }

    NSAssert(bundle, @"Missing bundle. Check the Bundle identifier on the plist of this target vs the identifiers array in this class.");
           
    return bundle;
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
        NSLog(@"Coordinator is nil & context is %@", [tempManagedObjectContext description]);
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
    NSURL *modelURL = [[self bundle] URLForResource:_resource withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
}

- (void)initPersistentStoreCoordinator
{
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:self.databaseFilename];

    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
                             [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];

    NSError *error;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];

    if ([self.iCloudAppId length]) {
        [self setupiCloudForPersistantStoreCoordinator:_persistentStoreCoordinator];
    } else if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                          configuration:nil
                                                                    URL:storeURL
                                                                options:options
                                                                  error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
}

- (void)initManagedObjectContext
{
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];

    if (coordinator) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];

        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
        id mergePolicy = [[NSMergePolicy alloc] initWithMergeType:NSMergeByPropertyObjectTrumpMergePolicyType];
        [_managedObjectContext setMergePolicy:mergePolicy];


        if ([_iCloudAppId length]) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(mergeChangesFrom_iCloud:)
                                                         name:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                                       object:coordinator];
        }
    }
}

#pragma mark - CDMethods
- (NSManagedObject *)addObjectForEntityName:(NSString *)entityName forContext:(NSManagedObjectContext *)contextOrNil
{
    return [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:contextOrNil];
}

- (NSArray *)arrayForEntityName:(NSString *)entityName
{
    return [self arrayForEntityName:entityName forContext:nil];
}

- (NSArray *)arrayForEntityName:(NSString *)entityName forContext:(NSManagedObjectContext *)contextOrNil
{
    return [self arrayForEntityName:entityName withPredicate:nil forContext:contextOrNil];
}

- (NSArray *)arrayForEntityName:(NSString *)entityName withPredicate:(NSPredicate *)predicate forContext:(NSManagedObjectContext *)contextOrNil
{
    contextOrNil = [self threadSafeContext:contextOrNil];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
    [fetchRequest setPredicate:predicate];

    NSError *error;
    NSArray *results = [contextOrNil executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"Fetch Request Error\n%@",[error localizedDescription]);
    }

    return results;
}

- (void)deleteObject:(NSManagedObject *)object
{
    [[object managedObjectContext] deleteObject:object];
}

- (void)deleteAllObjectsOfEntity:(NSString *)entityName context:(NSManagedObjectContext *)contextOrNil
{
    contextOrNil = [self threadSafeContext:contextOrNil];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
    [fetchRequest setIncludesPropertyValues:NO];

    NSError *error;
    NSArray *results = [[self managedObjectContext] executeFetchRequest:fetchRequest error:&error];

    [results enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [contextOrNil deleteObject:obj];
    }];
}

#pragma mark - Thread Safety with Main MOC
- (NSManagedObjectContext *)threadSafeContext:(NSManagedObjectContext *)context
{
    if (context == nil) {
        context = [self managedObjectContext];
    }

#ifndef DEBUG
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    //For debugging only!
    if (context == [self managedObjectContext]) {
        NSAssert(dispatch_get_current_queue() == dispatch_get_main_queue(), @"XXX ALERT ALERT XXXX\nNOT ON MAIN QUEUE!");
    }
#pragma clang diagnostic pop
#endif
    
    return context;
}

#pragma mark - Context Saving and Merging
- (void)saveMainContext
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self saveContext:[self managedObjectContext]];
    });
}

- (void)saveContext:(NSManagedObjectContext *)context
{
    NSError *error;
    if (![context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error localizedDescription]);
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
        [[self managedObjectContext] mergeChangesFromContextDidSaveNotification:notification];
    });
}

- (NSManagedObjectContext *)startTransaction
{
    return [self tempManagedObjectContext];
}

- (void)endTransactionForContext:(NSManagedObjectContext *)context
{
    [self saveTempContext:context];
}

#pragma mark - iCloud Integration
//THIS IS NOT CORRECT
//TODO - MAKE THIS WORK
- (void)setupiCloudForPersistantStoreCoordinator:(NSPersistentStoreCoordinator *)psc
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *localStore = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:self.databaseFilename];

//http://developer.apple.com/library/ios/#documentation/Cocoa/Reference/Foundation/Classes/NSFileManager_Class/Reference/Reference.html#//apple_ref/occ/instm/NSFileManager/URLForUbiquityContainerIdentifier:
    NSURL *iCloud = [fileManager URLForUbiquityContainerIdentifier:nil];

    if (iCloud) {

        NSLog(@"iCloud is working");

        NSURL *iCloudLogsPath = [NSURL fileURLWithPath:[[iCloud path] stringByAppendingPathComponent:iCloudLogsDirectoryName]];

        NSLog(@"iCloudEnabledAppID = %@", self.iCloudAppId);
        NSLog(@"dataFileName = %@", self.databaseFilename);
        NSLog(@"iCloudDataDirectoryName = %@", iCloudDataDirectoryName);
        NSLog(@"iCloudLogsDirectoryName = %@", iCloudLogsDirectoryName);
        NSLog(@"iCloud = %@", iCloud);
        NSLog(@"iCloudLogsPath = %@", iCloudLogsPath);

        if ([fileManager fileExistsAtPath:[[iCloud path] stringByAppendingPathComponent:iCloudDataDirectoryName]] == NO) {
            NSError *fileSystemError;
            [fileManager createDirectoryAtPath:[[iCloud path] stringByAppendingPathComponent:iCloudDataDirectoryName]
                   withIntermediateDirectories:YES attributes:nil error:&fileSystemError];
            if (fileSystemError != nil) {
                NSLog(@"Error creating database directory %@", fileSystemError);
            }
        }

        NSString *iCloudData = [[[iCloud path]
                stringByAppendingPathComponent:iCloudDataDirectoryName]
                stringByAppendingPathComponent:self.databaseFilename];

        NSLog(@"iCloudData = %@", iCloudData);

        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        [options setObject:[NSNumber numberWithBool:YES] forKey:NSMigratePersistentStoresAutomaticallyOption];
        [options setObject:[NSNumber numberWithBool:YES] forKey:NSInferMappingModelAutomaticallyOption];
        [options setObject:self.iCloudAppId forKey:NSPersistentStoreUbiquitousContentNameKey];
        [options setObject:iCloudLogsPath forKey:NSPersistentStoreUbiquitousContentURLKey];

        [psc lock];

        [psc addPersistentStoreWithType:NSSQLiteStoreType
                          configuration:nil URL:[NSURL fileURLWithPath:iCloudData]
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
                          configuration:nil URL:localStore
                                options:options
                                  error:nil];
        [psc unlock];
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_ICLOUD_UPDATED object:nil userInfo:nil];
}

- (void)mergeChangesFromiCloud:(NSNotification *)notification
{

    NSLog(@"Merging in changes from iCloud...");

    NSManagedObjectContext *moc = [self managedObjectContext];

    [moc performBlock:^{

        [moc mergeChangesFromContextDidSaveNotification:notification];

        NSNotification *refreshNotification = [NSNotification notificationWithName:NOTIFICATION_ICLOUD_UPDATED object:nil userInfo:[notification userInfo]];

        [[NSNotificationCenter defaultCenter] postNotification:refreshNotification];
    }];
}

#pragma mark - Convenience Methods
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (void)resetCoreData
{
    NSArray *stores = [[self persistentStoreCoordinator] persistentStores];
    
    for(NSPersistentStore *store in stores) {
        [[self persistentStoreCoordinator] removePersistentStore:store error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:store.URL.path error:nil];
    }
    
    _persistentStoreCoordinator = nil;
    _managedObjectContext = nil;
    _managedObjectModel = nil;
}

- (void)debugPersistentStore
{
    NSLog(@"%@", [[_persistentStoreCoordinator managedObjectModel] entitiesByName]);
}

#pragma mark - Deprecated
- (void)dropTableForEntityWithName:(NSString *)name
{
    [self deleteAllObjectsOfEntity:name context:nil];
}

- (NSArray *)arrayForModel:(NSString *)model
{
    return [self arrayForEntityName:model];
}

- (id)addObjectForModel:(NSString *)model context:(NSManagedObjectContext *)context
{
    return [self addObjectForEntityName:model forContext:context];
}

- (NSArray *)arrayForModel:(NSString *)model forContext:(NSManagedObjectContext *)context
{
    return [self arrayForEntityName:model forContext:context];
}

- (NSArray *)arrayForModel:(NSString *)model withPredicate:(NSPredicate *)predicate forContext:(NSManagedObjectContext *)context
{
    return [self arrayForEntityName:model withPredicate:predicate forContext:context];
}

@end
