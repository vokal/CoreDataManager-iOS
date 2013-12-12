//
//  VICollectionDataSource.h
//  MuOptics
//
//  Created by teejay on 5/6/13.
//  Copyright (c) 2013 teejay. All rights reserved.
//

#import "VIFetchResultsDataSourceSKZ.h"

@interface VICollectionDataSourceSKZ : VIFetchResultsDataSourceSKZ <UICollectionViewDataSource, UICollectionViewDelegate>

@property (strong, readonly) NSFetchedResultsController *fetchedResultsController;

@property (weak) UICollectionView *collectionView;

- (id)initWithPredicate:(NSPredicate *)predicate
              cacheName:(NSString *)cacheName
         collectionView:(UICollectionView *)collectionView
     sectionNameKeyPath:(NSString *)sectionNameKeyPath
        sortDescriptors:(NSArray *)sortDescriptors
     managedObjectClass:(Class)managedObjectClass;

- (id)initWithPredicate:(NSPredicate *)predicate
              cacheName:(NSString *)cacheName
         collectionView:(UICollectionView *)collectionView
     sectionNameKeyPath:(NSString *)sectionNameKeyPath
        sortDescriptors:(NSArray *)sortDescriptors
     managedObjectClass:(Class)managedObjectClass
              batchSize:(NSInteger)batchSize;

- (id)initWithPredicate:(NSPredicate *)predicate
              cacheName:(NSString *)cacheName
         collectionView:(UICollectionView *)collectionView
     sectionNameKeyPath:(NSString *)sectionNameKeyPath
        sortDescriptors:(NSArray *)sortDescriptors
     managedObjectClass:(Class)managedObjectClass
               delegate:(id <VIFetchResultsDataSourceDelegateSKZ>)delegate;

- (id)initWithPredicate:(NSPredicate *)predicate
              cacheName:(NSString *)cacheName
         collectionView:(UICollectionView *)collectionView
     sectionNameKeyPath:(NSString *)sectionNameKeyPath
        sortDescriptors:(NSArray *)sortDescriptors
     managedObjectClass:(Class)managedObjectClass
              batchSize:(NSInteger)batchSize
               delegate:(id <VIFetchResultsDataSourceDelegateSKZ>)delegate;

@end
