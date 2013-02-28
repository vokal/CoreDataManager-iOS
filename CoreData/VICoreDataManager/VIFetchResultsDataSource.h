//
//  VIFetchResultsDataSource.h
//  CoreData
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@protocol VIFetchResultsDataSourceDelegate <NSObject>

@optional
- (void)fetchResultsDataSourceSelectedObject:(NSManagedObject *)object;
- (void)fetchResultsDataSourceHasResults:(BOOL)hasResults;

@end

@interface VIFetchResultsDataSource : NSObject <NSFetchedResultsControllerDelegate, UITableViewDelegate, UITableViewDataSource>
{
@protected
    NSFetchedResultsController *_fetchedResultsController;
    NSManagedObjectContext *_managedObjectContext;
    NSString *_cacheName;
    NSString *_sectionNameKeyPath;
    Class _managedObjectClass;
}

@property (assign, readonly) Class managedObjectClass;
@property (weak, readonly) UITableView *tableView;
@property (strong, readonly) NSManagedObjectContext *managedObjectContext;

@property (weak, nonatomic) id <VIFetchResultsDataSourceDelegate> delegate;

//these are exposed to handle reconfiguration of the protected _fetchedResultsController, when they change
@property (assign, nonatomic) NSInteger batchSize;
@property (strong, nonatomic) NSPredicate *predicate;
@property (strong, nonatomic) NSArray *sortDescriptors;

//you can ignore deprecation warnings in subclasses
@property (strong, readonly) NSFetchedResultsController *fetchedResultsController DEPRECATED_ATTRIBUTE;

- (NSArray *)fetchedObjects;

- (void)reloadData;

- (id)initWithPredicate:(NSPredicate *)predicate
              cacheName:(NSString *)cacheName
              tableView:(UITableView *)tableView
     sectionNameKeyPath:(NSString *)sectionNameKeyPath
        sortDescriptors:(NSArray *)sortDescriptors
     managedObjectClass:(Class)managedObjectClass;

- (id)initWithPredicate:(NSPredicate *)predicate
              cacheName:(NSString *)cacheName
              tableView:(UITableView *)tableView
     sectionNameKeyPath:(NSString *)sectionNameKeyPath
        sortDescriptors:(NSArray *)sortDescriptors
     managedObjectClass:(Class)managedObjectClass
              batchSize:(NSInteger)batchSize;

- (id)initWithPredicate:(NSPredicate *)predicate
              cacheName:(NSString *)cacheName
              tableView:(UITableView *)tableView
     sectionNameKeyPath:(NSString *)sectionNameKeyPath
        sortDescriptors:(NSArray *)sortDescriptors
     managedObjectClass:(Class)managedObjectClass
               delegate:(id <VIFetchResultsDataSourceDelegate>)delegate;

- (id)initWithPredicate:(NSPredicate *)predicate
              cacheName:(NSString *)cacheName
              tableView:(UITableView *)tableView
     sectionNameKeyPath:(NSString *)sectionNameKeyPath
        sortDescriptors:(NSArray *)sortDescriptors
     managedObjectClass:(Class)managedObjectClass
              batchSize:(NSInteger)batchSize
               delegate:(id <VIFetchResultsDataSourceDelegate>)delegate;

- (UITableViewCell *)cellAtIndexPath:(NSIndexPath *)indexPath;

@end
