//
//  VIPerson.m
//  CoreData
//
//  Created by Anthony Alesia on 7/27/12.
//
//

#import "VIPerson.h"


@implementation VIPerson

@dynamic lastName;
@dynamic firstName;

+ (id)addWithParams:(NSDictionary *)params forManagedObjectContext:(NSManagedObjectContext *)context
{
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:
                              [NSArray arrayWithObjects:
                               [NSPredicate predicateWithFormat:@"firstName == %@", [params objectForKey:PARAM_FIRST_NAME]],
                               [NSPredicate predicateWithFormat:@"lastName == %@", [params objectForKey:PARAM_LAST_NAME]], nil]];
    
    VIPerson *person = (VIPerson *)[self fetchForPredicate:predicate forManagedObjectContext:context];
    
    if (person != nil) {
        [self editWithParams:params forObject:person];
    } else {
        person = [self syncWithParams:params forManagedObjectContext:context];
    }
    
    return person;
}

+ (id)setInformationFromDictionary:(NSDictionary *)params forObject:(NSManagedObject *)object
{
    VIPerson *person = (VIPerson *)object;
    
    person.firstName = [[params objectForKey:PARAM_FIRST_NAME] isKindOfClass:[NSNull class]] ? person.firstName :
    [params objectForKey:PARAM_FIRST_NAME];
    
    person.lastName = [[params objectForKey:PARAM_LAST_NAME] isKindOfClass:[NSNull class]] ? person.lastName :
    [params objectForKey:PARAM_LAST_NAME];
    
    return person;
}

@end
