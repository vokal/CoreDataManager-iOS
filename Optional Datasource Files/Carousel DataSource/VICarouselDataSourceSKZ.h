//
//  VICollectionDataSource.h
//  Changes
//
//  Created by teejay on 5/6/13.
//  Copyright (c) 2013 teejay. All rights reserved.
//

#import "VIFetchResultsDataSourceSKZ.h"
#import "iCarouselSKZ.h"

@interface VICarouselDataSourceSKZ : VIFetchResultsDataSourceSKZ <iCarouselDataSourceSKZ, iCarouselDelegateSKZ>

@property (strong, readonly) NSFetchedResultsController *fetchedResultsController;

@property (weak) iCarouselSKZ *carousel;

- (id)initWithPredicate:(NSPredicate *)predicate
              cacheName:(NSString *)cacheName
               carousel:(iCarouselSKZ *)carousel
     sectionNameKeyPath:(NSString *)sectionNameKeyPath
        sortDescriptors:(NSArray *)sortDescriptors
     managedObjectClass:(Class)managedObjectClass;

- (id)initWithPredicate:(NSPredicate *)predicate
              cacheName:(NSString *)cacheName
               carousel:(iCarouselSKZ *)carousel
     sectionNameKeyPath:(NSString *)sectionNameKeyPath
        sortDescriptors:(NSArray *)sortDescriptors
     managedObjectClass:(Class)managedObjectClass
              batchSize:(NSInteger)batchSize;

- (id)initWithPredicate:(NSPredicate *)predicate
              cacheName:(NSString *)cacheName
               carousel:(iCarouselSKZ *)carousel
     sectionNameKeyPath:(NSString *)sectionNameKeyPath
        sortDescriptors:(NSArray *)sortDescriptors
     managedObjectClass:(Class)managedObjectClass
               delegate:(id <VIFetchResultsDataSourceDelegate>)delegate;

- (id)initWithPredicate:(NSPredicate *)predicate
              cacheName:(NSString *)cacheName
               carousel:(iCarouselSKZ *)carousel
     sectionNameKeyPath:(NSString *)sectionNameKeyPath
        sortDescriptors:(NSArray *)sortDescriptors
     managedObjectClass:(Class)managedObjectClass
              batchSize:(NSInteger)batchSize
               delegate:(id <VIFetchResultsDataSourceDelegate>)delegate;

@end
