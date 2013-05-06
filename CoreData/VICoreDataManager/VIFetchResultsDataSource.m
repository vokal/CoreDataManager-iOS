//
//  VIFetchResultsDataSource.m
//  CoreData
//

#import "VIFetchResultsDataSource.h"
#import "VICoreDataManager.h"

@interface VIFetchResultsDataSource ()
@property NSString *sectionNameKeyPath;
@property NSString *cacheName;
@end

@implementation VIFetchResultsDataSource

- (id)initWithPredicate:(NSPredicate *)predicate
              cacheName:(NSString *)cacheName
              tableView:(UITableView *)tableView
     sectionNameKeyPath:(NSString *)sectionNameKeyPath
        sortDescriptors:(NSArray *)sortDescriptors
     managedObjectClass:(Class)managedObjectClass
              batchSize:(NSInteger)batchSize
               delegate:(id <VIFetchResultsDataSourceDelegate>)delegate
{
    self = [super init];

    if (self) {
        _managedObjectContext = [[VICoreDataManager sharedInstance] managedObjectContext];
        _predicate = predicate;
        _sortDescriptors = sortDescriptors;
        _managedObjectClass = managedObjectClass;
        _sectionNameKeyPath = sectionNameKeyPath;
        _cacheName = cacheName;
        _tableView = tableView;
        _tableView.delegate = self;
        _tableView.dataSource = self;
        _batchSize = batchSize;
        _delegate = delegate;

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
               delegate:(id <VIFetchResultsDataSourceDelegate>)delegate
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
    NSLog(@"NSNotification: Underlying data changed ... refreshing!");
    NSError *error = nil;
    if (![_fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

- (void)reloadData
{
    NSError *error = nil;
    if (![_fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    //FOR REVIEW controllerWillChangeContent is not being called in tests - this updates the table explicitly
    [_tableView reloadData];
}

- (NSArray *)fetchedObjects
{
    NSError *error = nil;
    if (![_fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
   return _fetchedResultsController.fetchedObjects;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([_delegate respondsToSelector:@selector(fetchResultsDataSourceSelectedObject:)]) {
        [_delegate fetchResultsDataSourceSelectedObject:[_fetchedResultsController objectAtIndexPath:indexPath]];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[_fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[_fetchedResultsController sections] objectAtIndex:section];

    if ([_delegate respondsToSelector:@selector(fetchResultsDataSourceHasResults:)]) {
        [_delegate fetchResultsDataSourceHasResults:([sectionInfo numberOfObjects] > 0)];
    }

    return [sectionInfo numberOfObjects];
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

    [fetchRequest setSortDescriptors:_sortDescriptors];

    [fetchRequest setPredicate:_predicate];

    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:_managedObjectContext sectionNameKeyPath:_sectionNameKeyPath cacheName:_cacheName];
    aFetchedResultsController.delegate = self;
    
    _fetchedResultsController = aFetchedResultsController;
    
    [self reloadData];

}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [_tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [_tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [_tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeUpdate:
            [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                              withRowAnimation:UITableViewRowAnimationNone];
            break;

        case NSFetchedResultsChangeMove:
            [_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [_tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [_tableView endUpdates];
}

- (UITableViewCell *)cellAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CellIdentifier";

    UITableViewCell *cell = [_tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    return cell;
}

@end
