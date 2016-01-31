//
//  SKZPlistMapExtensions.h
//  SkillzSDK-iOS
//
//  Created by John Graziano on 1/29/16.
//  Copyright © 2016 Skillz. All rights reserved.
//

#import <Foundation/Foundation.h>


CF_EXPORT NSString *SKZArchivedClassNameKey;

@interface NSObject (SKZPlistMapExtensions)

- (id)createObjectForKey:(nonnull NSString *)key owner:(id)owner context:(NSManagedObjectContext *)context;

@end

@interface NSArray (SKZPlistMapExtensions)

- (id)createObjectForKey:(nonnull NSString *)key owner:(id)owner context:(NSManagedObjectContext *)context;

@end

@interface NSDictionary (SKZPlistMapExtensions)

- (id)createObjectForKey:(nonnull NSString *)key owner:(id)owner context:(NSManagedObjectContext *)context;

@end

@interface NSString (SKZPlistMapExtensions)

- (id)createObjectForKey:(nonnull NSString *)key owner:(id)owner context:(NSManagedObjectContext *)context;

@end

@interface NSNumber (SKZPlistMapExtensions)

- (id)createObjectForKey:(nonnull NSString *)key owner:(id)owner context:(NSManagedObjectContext *)context;

@end


