//
//  VIPlayerDataSource.m
//  CoreData
//

#import "VIPlayerDataSource.h"
#import "VIPlayer.h"

@implementation VIPlayerDataSource

- (UITableViewCell *)cellAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CellIdentifier";
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    VIPlayer *player = [_fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.textLabel.text = [NSString stringWithFormat:@"Username: %@", player.cUsername];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"HighScore: %ld", (long)[player.cHighscore integerValue]];

    return cell;
}

@end