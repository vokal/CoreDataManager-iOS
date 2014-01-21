//
//  VIPagingFetchedResultsDataSource.m
//
//  Created by teejay on 1/21/14.
//

#import "VIPagingFetchedResultsDataSource.h"
#import "VIDefaultPagingAccessoryView.h"

@interface VIPagingFetchedResultsDataSource () <UIScrollViewDelegate>

@property (copy) VIPagingResultsAction upAction;
@property (copy) VIPagingResultsAction downAction;

@property UIView<VIPagingAccessory> *headerView;
@property UIView<VIPagingAccessory> *footerView;

@property BOOL isLoading;
@property CGFloat triggerDistance;
@end


@implementation VIPagingFetchedResultsDataSource

#pragma mark Setup
- (void)setupForTriggerDistance:(CGFloat)overscrollTriggerDistance
                       upAction:(VIPagingResultsAction)upPageActionOrNil
                     headerView:(UIView<VIPagingAccessory> *)headerViewOrNil
                     downAction:(VIPagingResultsAction)downPageActionOrNil
                     footerView:(UIView<VIPagingAccessory> *)footerViewOrNil;
{
    self.upAction = upPageActionOrNil;
    self.downAction = downPageActionOrNil;
    
    self.headerView = headerViewOrNil;
    self.footerView = footerViewOrNil;
    
    self.isLoading = NO;
    
    self.triggerDistance = overscrollTriggerDistance;
    
    [self setupAccessoryViews];
    
}

- (void)setupAccessoryViews
{
    //Attach given views, or generate default views.
    if (!self.headerView) {
        self.headerView = [[VIDefaultPagingAccessoryView alloc] initWithFrame:(CGRect){0, -65, self.tableView.frame.size.width, 65}];
    }
    
    [self.tableView addSubview:self.headerView];
    
    /*if (!self.footerView) {
        self.footerView = [[VIDefaultPagingAccessoryView alloc] initWithFrame:(CGRect){0, MAX(self.tableView.contentSize.height, self.tableView.bounds.size.height),
            self.tableView.frame.size.width, 65}];
        [(VIDefaultPagingAccessoryView *)self.footerView setIsFooter:YES];
    }
    
    [self.tableView addSubview:self.footerView];
    
    [self.tableView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionPrior context:NULL];*/
}

- (void)cleanUpPageController
{
    [self.tableView removeObserver:self forKeyPath:@"contentSize"];
    
    [self.headerView removeFromSuperview];
    self.headerView = nil;
    
    [self.footerView removeFromSuperview];
    self.footerView = nil;
    
    self.upAction = nil;
    self.downAction = nil;
}

#pragma mark Scrollview Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"contentSize"])
    {
        [self.footerView setFrame:(CGRect){0, MAX(self.tableView.contentSize.height, self.tableView.bounds.size.height), self.footerView.frame.size}];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!self.isLoading) {
        //Calculate scrollable height
        CGFloat contentHeight = scrollView.contentSize.height;
        CGFloat scrollableHeight = contentHeight + scrollView.bounds.size.height;
        
        CGFloat topOffset = scrollView.contentOffset.y - scrollView.contentInset.top;
        if (topOffset > (scrollableHeight + self.triggerDistance) && self.downAction)
        {
            self.isLoading = YES;
            [self.footerView loadingWillBegin];
            
            VICompletionAction completionAction = ^void (void)
            {
                self.isLoading = NO;
                [self.footerView loadingHasFinished];
            };
            
            self.downAction(self.tableView, completionAction);
            
        }
        
        if (topOffset < (-self.triggerDistance) && self.upAction)
        {
            self.isLoading = YES;
            [self.headerView loadingWillBegin];
            
            VICompletionAction completionAction = ^void (void)
            {
                self.isLoading = NO;
                [self.headerView loadingHasFinished];
            };
            
            self.upAction(self.tableView, completionAction);
        }
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    //Calculate scrollable height
    CGFloat contentHeight = scrollView.contentSize.height;
    CGFloat scrollableHeight = contentHeight-scrollView.bounds.size.height;
    
    CGFloat topOffset = scrollView.contentOffset.y + scrollView.contentInset.top;
    
    if (topOffset > scrollableHeight) {
        CGFloat distanceOverscrolled = topOffset - scrollableHeight;
        [self.footerView hasOverScrolled:(distanceOverscrolled/self.triggerDistance)];
    } else {
        [self.footerView hasOverScrolled:0.0];
    }
    
    if (topOffset < 0) {
        [self.headerView hasOverScrolled:(fabsf(topOffset)/self.triggerDistance)];
    } else {
        [self.headerView hasOverScrolled:0.0];
    }
}

- (void)dealloc
{
    NSLog(@"Page controller dealloc'd %@", self);
}

@end
