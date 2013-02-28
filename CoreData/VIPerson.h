//
//  VIPerson.h
//  CoreData
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#import "VICoreDataManager.h"

static NSString *const PARAM_FIRST_NAME = @"firstName";
static NSString *const PARAM_LAST_NAME = @"lastName";

@interface VIPerson : NSManagedObject

@property (nonatomic, retain) NSString *firstName;
@property (nonatomic, retain) NSString *lastName;

@end