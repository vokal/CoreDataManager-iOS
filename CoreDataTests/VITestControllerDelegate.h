//
//  VITestControllerDelegate.h
//  CoreData
//
//  Created by ckl on 2/13/13.
//
//

#import <UIKit/UIKit.h>
#import "VIFetchResultsDataSource.h"

@class VIPersonDataSource;

@interface VITestControllerDelegate : UITableViewController<VIFetchResultsDataSourceDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
