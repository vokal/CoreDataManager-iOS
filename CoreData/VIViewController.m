//
//  VIViewController.m
//  CoreData
//
//  Created by Anthony Alesia on 7/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "VIViewController.h"
#import "VIPerson.h"

@interface VIViewController ()

@end

@implementation VIViewController
@synthesize tableView = _tableView;
@synthesize dataSource = _dataSource;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self updateCoreData];
    [self setupDataSource];
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)setupDataSource
{
    NSArray *sortDescriptors = [NSArray arrayWithObjects:
                                [NSSortDescriptor sortDescriptorWithKey:@"lastName" ascending:YES],
                                [NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES], nil];
    
    _dataSource = [[VIPersonDataSource alloc] initWithPredicate:nil
                                                      cacheName:nil
                                                      tableView:_tableView
                                             sectionNameKeyPath:nil
                                                sortDescriptors:sortDescriptors
                                             managedObjectClass:[VIPerson class]];
}

- (void)updateCoreData
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *array = [NSArray arrayWithObjects:
                          [NSDictionary dictionaryWithObjectsAndKeys:@"Anthony", PARAM_FIRST_NAME, @"Alesia", PARAM_LAST_NAME, nil],
                          [NSDictionary dictionaryWithObjectsAndKeys:@"Reid", PARAM_FIRST_NAME, @"Lappin", PARAM_LAST_NAME, nil],
                          [NSDictionary dictionaryWithObjectsAndKeys:@"Brandon", PARAM_FIRST_NAME, @"Passley", PARAM_LAST_NAME, nil],
                          [NSDictionary dictionaryWithObjectsAndKeys:@"Andy", PARAM_FIRST_NAME, @"Mack", PARAM_LAST_NAME, nil],
                          [NSDictionary dictionaryWithObjectsAndKeys:@"Nick", PARAM_FIRST_NAME, @"Ross", PARAM_LAST_NAME, nil],
                          [NSDictionary dictionaryWithObjectsAndKeys:@"Scott", PARAM_FIRST_NAME, @"Ferguson", PARAM_LAST_NAME, nil],
                          [NSDictionary dictionaryWithObjectsAndKeys:@"Joe", PARAM_FIRST_NAME, @"Call", PARAM_LAST_NAME, nil],
                          [NSDictionary dictionaryWithObjectsAndKeys:@"John", PARAM_FIRST_NAME, @"Forester", PARAM_LAST_NAME, nil],
                          [NSDictionary dictionaryWithObjectsAndKeys:@"Sean", PARAM_FIRST_NAME, @"Wolter", PARAM_LAST_NAME, nil],
                          [NSDictionary dictionaryWithObjectsAndKeys:@"Bracken", PARAM_FIRST_NAME, @"Spencer", PARAM_LAST_NAME, nil],
                          [NSDictionary dictionaryWithObjectsAndKeys:@"Bill", PARAM_FIRST_NAME, @"Best", PARAM_LAST_NAME, nil],
                          [NSDictionary dictionaryWithObjectsAndKeys:@"David", PARAM_FIRST_NAME, @"Ryan", PARAM_LAST_NAME, nil],
                          [NSDictionary dictionaryWithObjectsAndKeys:@"Alex", PARAM_FIRST_NAME, @"Sikora", PARAM_LAST_NAME, nil],
                          [NSDictionary dictionaryWithObjectsAndKeys:@"Sagar", PARAM_FIRST_NAME, @"Joshi", PARAM_LAST_NAME, nil],
                          [NSDictionary dictionaryWithObjectsAndKeys:@"Brian", PARAM_FIRST_NAME, @"Flavin", PARAM_LAST_NAME, nil],
                          [NSDictionary dictionaryWithObjectsAndKeys:@"Max", PARAM_FIRST_NAME, @"Bare", PARAM_LAST_NAME, nil],
                          [NSDictionary dictionaryWithObjectsAndKeys:@"Austin", PARAM_FIRST_NAME, @"Sheaffer", PARAM_LAST_NAME, nil],
                          [NSDictionary dictionaryWithObjectsAndKeys:@"Jamie", PARAM_FIRST_NAME, @"Calder", PARAM_LAST_NAME, nil], nil];
        
        NSManagedObjectContext *context = [[VICoreDataManager getInstance] startTransaction];
        
        [VIPerson addWithArray:array forManagedObjectContext:context];
        
        [[VICoreDataManager getInstance] endTransactionForContext:context];
    });
}

@end
