//
//  VIPerson.h
//  CoreData
//
//  Created by Anthony Alesia on 7/27/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "VIManagedObject.h"

#define PARAM_FIRST_NAME    @"firstName"
#define PARAM_LAST_NAME     @"lastName"

@interface VIPerson : VIManagedObject

@property (nonatomic, retain) NSString * lastName;
@property (nonatomic, retain) NSString * firstName;

@end
