//
//  VIPerson.h
//  CoreData
//
//  Created by Anthony Alesia on 7/27/12.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "VIPerson.h"

#define PARAM_FIRST_NAME    @"firstName"
#define PARAM_LAST_NAME     @"lastName"

@interface VIPerson (Behavior)

+ (id)addWithParams:(NSDictionary *)params forManagedObjectContext:(NSManagedObjectContext *)context;

+ (id)setInformationFromDictionary:(NSDictionary *)params forObject:(NSManagedObject *)object;

@end
