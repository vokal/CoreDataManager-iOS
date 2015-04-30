//
//  VIFetchResultsDataSource.m
//  CoreData
//

#import "VIFetchResultsDataSourceSKZ.h"
#import "VICoreDataManagerSKZ.h"

@interface VIFetchResultsDataSourceSKZ ()

@property NSString *sectionNameKeyPath;
@property NSString *cacheName;
@property (strong, nonatomic, readwrite) NSFetchedResultsController* fetchedResultsController;

@end

@implementation VIFetchResultsDataSourceSKZ

- (id)initWithPredicate:(NSPredicate *)predicate
              cacheName:(NSString *)cacheName
              tableView:(UITableView *)tableView
     sectionNameKeyPath:(NSString *)sectionNameKeyPath
        sortDescriptors:(NSArray *)sortDescriptors
     managedObjectClass:(Class)managedObjectClass
              batchSize:(NSInteger)batchSize
             fetchLimit:(NSInteger)fetchLimit
               delegate:(id <VIFetchResultsDataSourceDelegateSKZ>)delegate
{
    self = [super init];

    if (self) {
        _managedObjectContext = [[VICoreDataManagerSKZ sharedInstance] managedObjectContext];
        _predicate = predicate;
        _sortDescriptors = sortDescriptors;
        _managedObjectClass = managedObjectClass;
        _sectionNameKeyPath = sectionNameKeyPath;
        _cacheName = cacheName;
        _tableView = tableView;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _batchSize = batchSize;
        _fetchLimit = fetchLimit;
        _delegate = delegate;
        
        _clearsTableViewCellSelection = YES;
        
        [self initFetchedResultsController];
    }

    return self;
}

- (id)initWithPredicate:(NSPredicate *)predicate
              cacheName:(NSString *)cacheName
              tableView:(UITableView *)tableView
     sectionNameKeyPath:(NSString *)sectionNameKeyPath
        sortDescriptors:(NSArray *)sortDescriptors
     managedObjectClass:(Class)managedObjectClass
              batchSize:(NSInteger)batchSize
               delegate:(id <VIFetchResultsDataSourceDelegateSKZ>)delegate
{
    
    return [self initWithPredicate:predicate
                         cacheName:cacheName
                         tableView:tableView
                sectionNameKeyPath:sectionNameKeyPath
                   sortDescriptors:sortDescriptors
                managedObjectClass:managedObjectClass
                         batchSize:batchSize
                        fetchLimit:0
                          delegate:delegate];
}


- (id)initWithPredicate:(NSPredicate *)predicate
              cacheName:(NSString *)cacheName
              tableView:(UITableView *)tableView
     sectionNameKeyPath:(NSString *)sectionNameKeyPath
        sortDescriptors:(NSArray *)sortDescriptors
     managedObjectClass:(Class)managedObjectClass
              batchSize:(NSInteger)batchSize
{
    return [self initWithPredicate:predicate
                         cacheName:cacheName
                         tableView:tableView
                sectionNameKeyPath:sectionNameKeyPath
                   sortDescriptors:sortDescriptors
                managedObjectClass:managedObjectClass
                         batchSize:batchSize
                          delegate:nil];
}

- (id)initWithPredicate:(NSPredicate *)predicate
              cacheName:(NSString *)cacheName
              tableView:(UITableView *)tableView
     sectionNameKeyPath:(NSString *)sectionNameKeyPath
        sortDescriptors:(NSArray *)sortDescriptors
     managedObjectClass:(Class)managedObjectClass
               delegate:(id <VIFetchResultsDataSourceDelegateSKZ>)delegate
{
    return [self initWithPredicate:predicate
                         cacheName:cacheName
                         tableView:tableView
                sectionNameKeyPath:sectionNameKeyPath
                   sortDescriptors:sortDescriptors
                managedObjectClass:managedObjectClass
                         batchSize:20
                          delegate:delegate];
}

- (void)setSortDescriptors:(NSArray *)sortDescriptors
{
    if (_sortDescriptors != sortDescriptors) {
        _sortDescriptors = sortDescriptors;
        [self initFetchedResultsController];
    }
}

- (void)setPredicate:(NSPredicate *)predicate
{
    if (_predicate != predicate) {
        _predicate = predicate;
        [self initFetchedResultsController];
    }
}

- (void)setBatchSize:(NSInteger)batchSize
{
    if (_batchSize != batchSize) {
        _batchSize = batchSize;
        [self initFetchedResultsController];
    }
}

- (id)initWithPredicate:(NSPredicate *)predicate
              cacheName:(NSString *)cacheName
              tableView:(UITableView *)tableView
     sectionNameKeyPath:(NSString *)sectionNameKeyPath
        sortDescriptors:(NSArray *)sortDescriptors
     managedObjectClass:(Class)managedObjectClass
{
    return [self initWithPredicate:predicate
                         cacheName:cacheName
                         tableView:tableView
                sectionNameKeyPath:sectionNameKeyPath
                   sortDescriptors:sortDescriptors
                managedObjectClass:managedObjectClass
                         batchSize:20];
}

#pragma mark - Instance Methods

- (void)reloadFetchedResults:(NSNotification *)note
{
    CDLog(@"NSNotification: Underlying data changed ... refreshing!");
    
    [self.fetchedResultsController.managedObjectContext performBlockAndWait:^{
        NSError *error = nil;

        if (![self.fetchedResultsController performFetch:&error]) {
            CDLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }];
}

- (void)reloadData
{
    [self.fetchedResultsController.managedObjectContext performBlockAndWait:^{
        NSError *error = nil;

        if (![self.fetchedResultsController performFetch:&error]) {
            CDLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }];
    [self.tableView reloadData];
}

- (NSArray *)fetchedObjects
{
    [self.fetchedResultsController.managedObjectContext performBlockAndWait:^{
        NSError *error = nil;

        if (![self.fetchedResultsController performFetch:&error]) {
            CDLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }}];
    return self.fetchedResultsController.fetchedObjects;
}

- (id)objectAtIndexPath:(NSIndexPath *)path
{
    id result = nil;
    
    @try {
        result = [self.fetchedResultsController objectAtIndexPath:path];
    }
    @catch (NSException *exception) {
        return nil;
    }
    return result;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([_delegate respondsToSelector:@selector(fetchResultsDataSourceSelectedObject:)]) {
        [_delegate fetchResultsDataSourceSelectedObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
    }

    if (self.clearsTableViewCellSelection) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger sectionCount = [[self.fetchedResultsController sections] count];
    if (!sectionCount && [_delegate respondsToSelector:@selector(fetchResultsDataSourceHasResults:)]) {
        [_delegate fetchResultsDataSourceHasResults:NO];
    }
    
    return sectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];

    if ([_delegate respondsToSelector:@selector(fetchResultsDataSourceHasResults:)]) {
        [_delegate fetchResultsDataSourceHasResults:([sectionInfo numberOfObjects] > 0)];
    }

    NSInteger num = [[self.fetchedResultsController fetchedObjects] count];
    
    return num;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self cellAtIndexPath:indexPath];
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (!_fetchedResultsController) {
        [self initFetchedResultsController];
    }

    return _fetchedResultsController;
}

- (void)initFetchedResultsController
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass(_managedObjectClass)
                                              inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setFetchBatchSize:_batchSize];
    
    [fetchRequest setFetchLimit:_fetchLimit];

    [fetchRequest setSortDescriptors:_sortDescriptors];

    [fetchRequest setPredicate:_predicate];
    
    [fetchRequest setReturnsObjectsAsFaults:NO];

    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                managedObjectContext:_managedObjectContext
                                                                                                  sectionNameKeyPath:_sectionNameKeyPath
                                                                                                           cacheName:_cacheName];
    aFetchedResultsController.delegate = self;
    
    _fetchedResultsController = aFetchedResultsController;
    
    [self reloadData];

}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    @try {
        [self.tableView beginUpdates];
    }
    @catch (NSException *exception) {}
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    @try {
        switch (type) {
            case NSFetchedResultsChangeUpdate:
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;

            case NSFetchedResultsChangeInsert:
                [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;

            case NSFetchedResultsChangeDelete:
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
                break;
                
            default:
                break;
        }
    }
    @catch (NSException *exception) {}
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    @try {
        switch (type) {
            case NSFetchedResultsChangeInsert:
                [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;

            case NSFetchedResultsChangeDelete:
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;

            case NSFetchedResultsChangeUpdate:
                [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                                      withRowAnimation:UITableViewRowAnimationNone];
                break;

            case NSFetchedResultsChangeMove:
                [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
                break;
        }
    }
    @catch (NSException *exception) {}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    @try {
        [self.tableView endUpdates];
    }
    @catch (NSException *exception) {}
}

- (UITableViewCell *)cellAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CellIdentifier";

    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    return cell;
}

- (void)dealloc
{
    if (self.tableView.delegate == self) {
        self.tableView.delegate = nil;
    }
    
    if (self.tableView.dataSource == self) {
         self.tableView.dataSource = nil;
    }
    
}

@end
