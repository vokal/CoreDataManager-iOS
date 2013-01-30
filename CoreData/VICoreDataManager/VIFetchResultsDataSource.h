//
//  VIFetchResultsDataSource.h
//  CoreData
//
//  Created by Anthony Alesia on 7/26/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@protocol VIFetchResultsDataSourceDelegate <NSObject>

@optional - (void)fetchResultsDataSourceSelectedObject:(NSManagedObject *)object;
@optional - (void)fetchResultsDataSourceHasResults:(BOOL)hasResults;

@end

@interface VIFetchResultsDataSource : NSObject

<NSFetchedResultsControllerDelegate, UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSPredicate *predicate;
@property (weak, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSString *cacheName;
@property (strong, nonatomic) NSArray *sortDescriptors;
@property (strong, nonatomic) NSString *sectionNameKeyPath;
@property (assign, nonatomic) Class managedObjectClass;
@property (assign, nonatomic) id <VIFetchResultsDataSourceDelegate> delegate;

@property (assign, nonatomic) NSInteger batchSize;

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

- (UITableViewCell *)cellAtIndexPath:(NSIndexPath *)indexPath;

@end
