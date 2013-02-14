//
//  VIViewController.m
//  CoreData
//
//  Created by Anthony Alesia on 7/26/12.
//  Copyright (c) 2012 self._MyCompanyName__. All rights reserved.
//

#import "VIViewController.h"
#import "VIPerson+Behavior.h"

@interface VIViewController ()

@end

@implementation VIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupDataSource];
    
    [self initializeCoreData];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                                                           target:self
                                                                                           action:@selector(reloadData)];
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [super viewDidUnload];
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

    self.dataSource = [[VIPersonDataSource alloc] initWithPredicate:nil cacheName:nil tableView:self.tableView
                                                 sectionNameKeyPath:nil sortDescriptors:sortDescriptors
                                                 managedObjectClass:[VIPerson class]];
}

- (void)reloadData {
    [self.dataSource reloadData];
}

- (void)initializeCoreData
{
    [self resetCoreData];
    
    NSManagedObjectContext *context = [[VICoreDataManager getInstance] managedObjectContext];
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

    [VIPerson addWithArray:array forManagedObjectContext:context];
}

- (void)resetCoreData
{
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
