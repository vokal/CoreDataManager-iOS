//
//  VITestControllerDelegate.h
//  CoreData
//
//  Created by ckl on 2/13/13.
//
//

#import <UIKit/UIKit.h>
#import "VIFetchResultsDataSource.h"

@interface VITestControllerDelegate : UITableViewController<VIFetchResultsDataSourceDelegate>

@property (nonatomic, readonly) BOOL delegateNotifiedHasResults;

@end
