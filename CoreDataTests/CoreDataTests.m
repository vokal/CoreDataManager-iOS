//
//  CoreDataTests.m
//  CoreDataTests
//
//  Created by ckl on 2/12/13.
//
//

#import "CoreDataTests.h"
#import <CoreData/CoreData.h>
#import "VITestControllerDelegate.h"
#import "VICoreDataManager.h"
#import "VIFetchResultsDataSource.h"
#import "VIPersonDataSource.h"
#import "VIPerson+Behavior.h"

@implementation CoreDataTests

- (void)setUp
{
    [super setUp];
    
    [[VICoreDataManager getInstance] setResource:@"VICoreDataModel" database:@"VICoreDataModel.sqlite" forBundleIdentifier:@"vokal.CoreDataTests"];
    [self resetCoreData];
    self.predicate = [NSPredicate predicateWithFormat:@"lastName == %@", @"Passley"];
    self.sortDescriptors = [NSArray arrayWithObjects:
                        [NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES],
                        [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES], nil];
    self.viewController = [[VITestControllerDelegate alloc] initWithNibName:@"VITestControllerDelegate" bundle:[NSBundle bundleWithIdentifier:@"vokal.CoreDataTests"]];
}

- (void)tearDown
{
    self.predicate = nil;
    self.sortDescriptors = nil;
    self.viewController = nil;
    [super tearDown];
}

- (void)testCreateVIFetchResultsDataSource
{
    VIFetchResultsDataSource* dataSource = [[VIFetchResultsDataSource alloc] initWithPredicate:nil
                                                                         cacheName:nil
                                                                         tableView:nil
                                                                sectionNameKeyPath:nil
                                                                   sortDescriptors:self.sortDescriptors
                                                                managedObjectClass:[VIPerson class]];
    self.viewController.tableView.dataSource = dataSource;
    STAssertTrue(dataSource != nil, @"dataSource should be initialized");
}

- (void)testVIPersonDataSourceNoDelegate
{
    VIPersonDataSource* dataSource = [[VIPersonDataSource alloc] initWithPredicate:self.predicate
                                                                         cacheName:nil
                                                                         tableView:self.viewController.tableView
                                                                sectionNameKeyPath:nil
                                                                   sortDescriptors:self.sortDescriptors
                                                                managedObjectClass:[VIPerson class]];
    STAssertTrue(dataSource != nil, @"dataSource should be initialized");
    STAssertTrue(dataSource.delegate == nil, @"dataSource delegate should be nil");
    STAssertTrue([self.viewController.tableView numberOfRowsInSection:0] == 0,
                 [NSString stringWithFormat:@"no core data initialized yet, but rows count is %ld", (long)[self.viewController.tableView numberOfRowsInSection:0]]);
    STAssertTrue(dataSource.fetchedObjects.count == 0,
                 [NSString stringWithFormat:@"no core data initialized yet, but fetchedObjects.count is %ld", (unsigned long)dataSource.fetchedObjects.count]);

    [self updateVIPersonCoreData];
    [dataSource reloadData];
    
    STAssertTrue(dataSource.fetchedObjects.count == 1,
                 [NSString stringWithFormat:@"populated core data, but fetchedObjects.count is %ld", (unsigned long)dataSource.fetchedObjects.count]);

    STAssertTrue([self.viewController.tableView numberOfRowsInSection:0] == 1,
                 [NSString stringWithFormat:@"populated core data, but tableView rows count is %ld", (long)[self.viewController.tableView numberOfRowsInSection:0]]);
}

- (void)testVIPersonDataSourceWithDelegate
{
    VIPersonDataSource* dataSource = [[VIPersonDataSource alloc] initWithPredicate:self.predicate
                                                                         cacheName:nil
                                                                         tableView:self.viewController.tableView
                                                                sectionNameKeyPath:nil
                                                                   sortDescriptors:self.sortDescriptors
                                                                managedObjectClass:[VIPerson class]
                                                                          delegate:self.viewController];
    STAssertTrue(dataSource != nil, @"dataSource should be initialized");
    STAssertTrue(dataSource.delegate != nil, @"dataSource delegate should NOT be nil");
    
    [self updateVIPersonCoreData];
    
    //FOR REVIEW:
    //CD changes don't seem to propagate to VIFetchResultsDataSource without this 'pull'
    //  what is the intended pattern?
    // I'd thought wrapping with these would push changes to VIFetchResultsDataSource,
    //      NSManagedObjectContext *context = [[VICoreDataManager getInstance] startTransaction];
    //      [[VICoreDataManager getInstance] endTransactionForContext:context];
    //  but looks like you'd need a listener or delegate to invoke [dataSource reloadData] (might be on another thread, tho?)
    
    [dataSource reloadData];
    STAssertTrue(self.viewController.delegateNotifiedHasResults, @"delegate was not called with fetched results on reloadData");

}

- (void)updateVIPersonCoreData
{
    
    NSManagedObjectContext *context = [[VICoreDataManager getInstance] managedObjectContext];
    //FOR REVIEW (see above):
    //NSManagedObjectContext *context = [[VICoreDataManager getInstance] startTransaction];
    NSArray *array = [NSArray arrayWithObjects:
                      [NSDictionary dictionaryWithObjectsAndKeys:@"Anthony", PARAM_FIRST_NAME, @"Alesia", PARAM_LAST_NAME, nil],
                      [NSDictionary dictionaryWithObjectsAndKeys:@"Reid", PARAM_FIRST_NAME, @"Lappin", PARAM_LAST_NAME, nil],
                      [NSDictionary dictionaryWithObjectsAndKeys:@"Brandon", PARAM_FIRST_NAME, @"Passley", PARAM_LAST_NAME, nil],
                      [NSDictionary dictionaryWithObjectsAndKeys:@"Jamie", PARAM_FIRST_NAME, @"Calder", PARAM_LAST_NAME, nil], nil];
    
    [VIPerson addWithArray:array forManagedObjectContext:context];
    //[[VICoreDataManager getInstance] endTransactionForContext:context];
}

- (void)resetCoreData
{
    //NSManagedObjectContext *context = [[VICoreDataManager getInstance] managedObjectContext];
    //FOR REVIEW these tests don't pass unless I use transaction as follows:
    NSManagedObjectContext *context = [[VICoreDataManager getInstance] startTransaction];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([VIPerson class]) inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    NSError *error = nil;
    NSArray *fetchedObjects = [context executeFetchRequest:fetchRequest error:&error];

    for (NSManagedObject *nsManagedObject in fetchedObjects) {
        [[VICoreDataManager getInstance] deleteObject:nsManagedObject];
    }
    [[VICoreDataManager getInstance] endTransactionForContext:context];
 
}

@end
