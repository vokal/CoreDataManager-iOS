//
//  VIPagingFetchedResultsDataSource.m
//
//  Created by teejay on 1/21/14.
//

#import "VIPagingFetchedResultsDataSource.h"
#import "VIDefaultPagingAccessory.h"

@interface VIPagingFetchedResultsDataSource () <UIScrollViewDelegate>

@property VITableViewPagingManager *pagingManager;

@end


@implementation VIPagingFetchedResultsDataSource

#pragma mark Setup
- (void)setupForTriggerDistance:(CGFloat)overscrollTriggerDistance
                       upAction:(VIPagingResultsAction)upPageActionOrNil
                     headerView:(UIView<VIPagingAccessory> *)headerViewOrNil
                     downAction:(VIPagingResultsAction)downPageActionOrNil
                     footerView:(UIView<VIPagingAccessory> *)footerViewOrNil;
{

    self.pagingManager = [[VITableViewPagingManager alloc] initWithTableView:self.tableView];
    [self.pagingManager setupForTriggerDistance:overscrollTriggerDistance
                                       upAction:upPageActionOrNil
                                     headerView:headerViewOrNil
                                     downAction:downPageActionOrNil
                                     footerView:footerViewOrNil];
    
}


- (void)dealloc
{
    [self.pagingManager cleanUpPagingManager];
    CDLog(@"Page controller dealloc'd %@", self);
}

@end
