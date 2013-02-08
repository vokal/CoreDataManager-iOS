//
//  VIPersonDataSource.m
//  CoreData
//
//  Created by Anthony Alesia on 7/26/12.
//
//

#import "VIPersonDataSource.h"
#import "VIPerson.h"

@implementation VIPersonDataSource

- (UITableViewCell *)cellAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CellIdentifier";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    VIPerson *person = [_fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@, %@", person.lastName, person.firstName];
    
    return cell;
}

@end
