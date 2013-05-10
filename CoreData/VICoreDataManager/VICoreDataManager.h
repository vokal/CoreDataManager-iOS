//
//  VICoreDataManager.h
//  CoreData
//

#ifndef __IPHONE_5_0
#warning "VICoreDataManager uses features only available in iOS SDK 5.0 and later."
#endif

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "VIManagedObjectMapper.h"
#import "VIManagedObject.h"
#import "VIFetchResultsDataSource.h"

@interface VICoreDataManager : NSObject

//this constructor is explicitly a VICoreDataManager because it's not expected to be subclassed
+ (VICoreDataManager *)sharedInstance;

- (NSManagedObjectContext *)managedObjectContext;

//use one of these setup methods before interacting with Core Data
- (void)setResource:(NSString *)resource
           database:(NSString *)database;

//Create and configure new NSManagedObject subclasses
//If contextOrNil is nil the main context will be used.
- (NSManagedObject *)objectForClass:(Class)managedObjectClass
                            inContext:(NSManagedObjectContext *)contextOrNil;

- (BOOL)setObjectMapper:(VIManagedObjectMapper *)objMap
               forClass:(Class)objectClass;

- (NSArray *)importArray:(NSArray *)inputArray
                forClass:(Class)objectClass
             withContext:(NSManagedObjectContext*)contextOrNil;

- (NSManagedObject *)importDictionary:(NSDictionary *)inputDict
                             forClass:(Class)objectClass
                          withContext:(NSManagedObjectContext *)contextOrNil;

- (void)setInformationFromDictionary:(NSDictionary *)inputDict
                    forManagedObject:(NSManagedObject *)object;

//Return the dictionary representation of a managed object
- (NSDictionary *)dictionaryRepresentationOfManagedObject:(NSManagedObject *)object;

//Count, Fetch, and Delete NSManagedObject subclasses
//NOT threadsafe! Always use a temp context if you are NOT on the main thread.
- (NSUInteger)countForClass:(Class)managedObjectClass;
- (NSUInteger)countForClass:(Class)managedObjectClass
                 forContext:(NSManagedObjectContext *)contextOrNil;
- (NSUInteger)countForClass:(Class)managedObjectClass
              withPredicate:(NSPredicate *)predicate
                 forContext:(NSManagedObjectContext *)contextOrNil;

- (NSArray *)arrayForClass:(Class)managedObjectClass;
- (NSArray *)arrayForClass:(Class)managedObjectClass
                forContext:(NSManagedObjectContext *)contextOrNil;
- (NSArray *)arrayForClass:(Class)managedObjectClass
             withPredicate:(NSPredicate *)predicate
                forContext:(NSManagedObjectContext *)contextOrNil;

- (void)deleteObject:(NSManagedObject *)object;
- (BOOL)deleteAllObjectsOfClass:(Class)managedObjectClass
                        context:(NSManagedObjectContext *)contextOrNil;

//This saves the main context asynchronously on the main thread
- (void)saveMainContext;

//wrap your background transactions in these methods
//you are responsible for retaining temp contexts yourself
- (NSManagedObjectContext *)temporaryContext;
- (void)saveAndMergeWithMainContext:(NSManagedObjectContext *)context;

//this deletes the persistent stores and resets the main context and model to nil
- (void)resetCoreData;

@end
