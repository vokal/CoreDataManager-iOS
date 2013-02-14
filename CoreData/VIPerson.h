//
//  VIPerson.h
//  CoreData
//
//  Created by ckl on 2/12/13.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "VIManagedObject.h"

@interface VIPerson : VIManagedObject

@property (nonatomic, retain) NSString *firstName;
@property (nonatomic, retain) NSString *lastName;

@end
