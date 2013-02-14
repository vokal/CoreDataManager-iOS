//
//  VITestControllerDelegate.m
//  CoreData
//
//  Created by ckl on 2/13/13.
//
//

#import "VITestControllerDelegate.h"

@interface VITestControllerDelegate ()

@end

@implementation VITestControllerDelegate

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
        
    return cell;
}

#pragma mark - VIFetchResultsDataSourceDelegate methods

- (void)fetchResultsDataSourceSelectedObject:(NSManagedObject *)object
{

}

- (void)fetchResultsDataSourceHasResults:(BOOL)hasResults
{
    _delegateNotifiedHasResults = hasResults;
}


@end
