//
//  CoreDataTests.h
//  CoreDataTests
//
//  Created by ckl on 2/13/13.
//
//

#import <SenTestingKit/SenTestingKit.h>
#import "VIAppDelegate.h"

@class VITestControllerDelegate;

@interface CoreDataTests : SenTestCase

@property (nonatomic, strong) VIAppDelegate *appDelegate;
@property (nonatomic, strong) NSArray *sortDescriptors;

@property (nonatomic, retain) NSPredicate *predicate;
@property (nonatomic, strong) VITestControllerDelegate *viewController;
@end
