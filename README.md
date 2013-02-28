CoreDataManager-iOS
===================

##VICoreDataManager
* This unifies core data initialization in one place and simplifies access
* getInstance

            + (VICoreDataManager *)getInstance

* setResource:database:
    * This needs to be called before you do anything. This sets the resource "[resource].xcdatamodeld" and the database "[database.sqlite]"

            - (void)setResource:(NSString *)resource database:(NSString *)database

    * example

            [[VICoreDataManager getInstance] setResource:@"CoreDataModel" database:@"coreDataModel.sqlite"];

* saveMainContext
    * This method saves the NSManagedObjectContext instance within the core data manager

            - (void)saveMainContext

* resetCoreData
    * This method clears all the persistant stores and releases the main context and model

            - (void)resetCoreData

* addObjectForModel:context:
    * This method creates a new NSManagedObject in the given context and returns it. If contextOrNil is nil the main context is used.

			- (NSManagedObject *)addObjectForEntityName:(NSString *)entityName forContext:(NSManagedObjectContext *)contextOrNil

* deleteObject
	* This method deletes the desired object from the database

            - (void)deleteObject:(NSManagedObject *)object
            
* dropTableForEntityWithName:
	* This method deletes every instance of an entity from the database

            - (void)deleteAllObjectsOfEntity:(NSString *)entityName context:(NSManagedObjectContext *)contextOrNil

* arrayForModel:
    * This method just grabs all of a model from the database and returns it in no specific order from the main context

            - (NSArray *)arrayForEntityName:(NSString *)entityName

* arrayForModel:forContext:
	* This method does the same as above for a given context

            - (NSArray *)arrayForEntityName:(NSString *)entityName forContext:(NSManagedObjectContext *)contextOrNil

* arrayForModel:withPredicate:forContext:
    * This method gets the array using the predicate for the given context

            - (NSArray *)arrayForEntityName:(NSString *)entityName withPredicate:(NSPredicate *)predicate forContext:(NSManagedObjectContext *)contextOrNil

* startTransaction
   * This method creates a temporary instance of NSManagedObjectContext that does not effect the main context. This is to be used when adding, deleting, or editing any model while on a background thread (managed object contexts are not thread safe)

            - (NSManagedObjectContext *)startTransaction

* endTransactionForContext:
    * This method save the temporary context. The main context will merge changes. If you want to discard your temp context simple release it or let it go out of scope. VICoreDataManager does not retain temporary contexts.

            - (void)endTransactionForContext:(NSManagedObjectContext *)context

##VIManagedObject
* This is a subclass of NSManagedObject. This subclass contains the object creation methods used in every model. Once this model is subclassed, you only need to write the methods you need to alter for that specific class. There are two sets, a set that will create a relationship and a set that will not.
* Relationship
    * addWithArray:forManagedObject:
        * This method simply created a for loop the cycles through the dictionarys passed in with the array and calls addWithParams:forManagedObject:. This class does not need to be overwritten.

                + (void)addWithArray:(NSArray *)array forManagedObject:(NSManagedObject *)managedObject
                {
                    if ([self cleanForArray:array forManagedObject:managedObject]) {
                        for (NSDictionary *params in array) {
                            [self addWithParams:params forManagedObject:managedObject];
                        }
                    }
                }

    * cleanForArray:forManagedObject:
        * This method is here to use to remove any objects that weren't returned in the array that's about to be synced. This method returns a boolean, it should return YES unless there's a reason to stop syncing. It defaults to return YES and can be ignored.

                + (BOOL)cleanForArray:(NSArray *)array forManagedObject:(NSManagedObject *)managedObject
                {
                    NSArray *resultsArray = [[VICoreDataManager getInstance] arrayForModel:NSStringFromClass([self class])
                                                                                forContext:[managedObject managedObjectContext]];
                
                    for (int i = 0; i < [resultsArray count]; i++) {
                        VIPerson *person = [resultsArray objectAtIndex:i];
                        
                        NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:
                                                     [NSArray arrayWithObjects:
                                                         [NSPredicate predicateWithFormat:@"(firstName == %@)", person.firstName],
                                                         [NSPredicate predicateWithFormat:@"(lastName == %@)", person.lastName], nil]];
                        NSArray *matchingDicts = [array filteredArrayUsingPredicate:predicate];
                        
                        if ([matchingDicts count] == 0) {
                            [[VICoreDataManager getInstance] deleteObject:person];
                        }
                    }
    
                    return YES;
                }

    * addWithParams:forManagedObject:
        * This method is where you will find if the object exists and needs to be edited or if a new instance in needed. This methods needs to be overwritten (See the example below).

                + (void)addWithParams:(NSDictionary *)params forManagedObject:(NSManagedObject *)managedObject
                {
                    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:
                                                 [NSArray arrayWithObjects:
                                                     [NSPredicate predicateWithFormat:@"firstName == %@", [params objectForKey:PARAM_FIRST_NAME]],
                                                     [NSPredicate predicateWithFormat:@"lastName == %@", [params objectForKey:PARAM_LAST_NAME]], nil]];
                    
                    VIPerson *person = (VIPerson *)[self fetchForPredicate:predicate forManagedObject:managedObject];
                    
                    if (person != nil) {
                        [self editWithParams:params forObject:person];
                    } else {
                        [self syncWithParams:params forManagedObject:managedObject];
                    }
                }

    * editWithParams:forObject:forManagedObject:
        * This method is meant for editing an existing model (if overwriting call super of this method). It returns the object it edits. If making a relationship, this method should be overwritten (See example below).

                + (id)editWithParams:(NSDictionary *)params forObject:(NSManagedObject*)object forManagedObject:(NSManagedObject *)managedObject
                {
                    VIPerson *person = [super editWithParams:params forObject:object forManagedObject:managedObject];
    
                        if (person != nil) {
                            person.group = (VIGroup *)managedObject;
                        }
    
                        return person;
                    }
                }

    * syncWithParams:forManagedObject:
        * This method creates a new instance of a model (if overwriting call super of this method). It returns the object it creates. If making a relationship, this method should be overwritten (See example below).

                + (id)syncWithParams:(NSDictionary *)params forManagedObject:(NSManagedObject *)managedObject
                {
                    VIPerson *person = [super syncWithParams:params forManagedObject:managedObject];
    
                        if (person != nil) {
                            person.group = (VIGroup *)managedObject;
                        }
    
                        return person;
                    }
                }

    * existsForPredicate:forManagedObject:
        * This method checks to see if an instance of the model matching the predicate exists. This method does not need to be overwritten.

                + (BOOL)existsForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)managedObject

    * fetchForPredicate:forManagedObject:
        * This method queries for an object that matches the predicate. Returns it if it does, otherwise returns nil. This method does not need to be overwritten.

                + (NSManagedObject *)fetchForPredicate:(NSPredicate *)predicate forManagedObject:(NSManagedObject *)managedObject
                {
                    NSArray *results = [[VICoreDataManager getInstance] arrayForModel:NSStringFromClass([self class])
                                                                        withPredicate:predicate
                                                                           forContext:[managedObject managedObjectContext]];
                    
                    if ([results count] > 0) {
                        return [results lastObject];
                    }
                    
                    return nil;
                }

* No Relationship
    * addWithArray:forManagedObjectContext:
        * This method simply created a for loop the cycles through the dictionarys passed in with the array and calls addWithParams:forManagedObject:. This class does not need to be overwritten.

                + (void)addWithArray:(NSArray *)array forManagedObjectContext:(NSManagedObjectContext *)context
                {
                    if ([self cleanForArray:array forManagedObjectContext:context]) {
                        for (NSDictionary *params in array) {
                            [self addWithParams:params forManagedObjectContext:context];
                        }
                    }
                }

    * cleanForArray:forManagedObjectContext:
        * This method is here to use to remove any objects that weren't returned in the array that's about to be synced. This method returns a boolean, it should return YES unless there's a reason to stop syncing. It defaults to return YES and can be ignored.

                + (BOOL)cleanForArray:(NSArray *)array forManagedObjectContext:(NSManagedObjectContext *)context
                {
                    NSArray *resultsArray = [[VICoreDataManager getInstance] arrayForModel:NSStringFromClass([self class])
                                                                                forContext:context];
                
                    for (int i = 0; i < [resultsArray count]; i++) {
                        VIPerson *person = [resultsArray objectAtIndex:i];
                        
                        NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:
                                                     [NSArray arrayWithObjects:
                                                         [NSPredicate predicateWithFormat:@"(firstName == %@)", person.firstName],
                                                         [NSPredicate predicateWithFormat:@"(lastName == %@)", person.lastName], nil]];
                        NSArray *matchingDicts = [array filteredArrayUsingPredicate:predicate];
                        
                        if ([matchingDicts count] == 0) {
                            [[VICoreDataManager getInstance] deleteObject:person];
                        }
                    }
    
                    return YES;
                }

    * addWithParams:forManagedObjectContext:
        * This method is where you will find if the object exists and needs to be edited or if a new instance in needed. This methods needs to be overwritten (See the example below).

                + (void)addWithParams:(NSDictionary *)params forManagedObjectContext:(NSManagedObjectContext *)context
                {
                    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:
                                                 [NSArray arrayWithObjects:
                                                     [NSPredicate predicateWithFormat:@"firstName == %@", [params objectForKey:PARAM_FIRST_NAME]],
                                                     [NSPredicate predicateWithFormat:@"lastName == %@", [params objectForKey:PARAM_LAST_NAME]], nil]];
                
                    VIPerson *person = (VIPerson *)[self fetchForPredicate:predicate forManagedObjectContext:context];
                    
                    if (person != nil) {
                        [self editWithParams:params forObject:person];
                    } else {
                        [self syncWithParams:params forManagedObjectContext:context];
                    }
                }

    * editWithParams:forObject:
        * This method is meant for editing an existing model (if overwriting call super of this method). It returns the object it edits. This method does not need to be overwritten.

                + (id)editWithParams:(NSDictionary *)params forObject:(NSManagedObject *)object

    * syncWithParams:forManagedObjectContext:
        * This method creates a new instance of a model (if overwriting call super of this method). It returns the object it creates. This method does not need to be overwritten.

                + (id)syncWithParams:(NSDictionary *)params forManagedObjectContext:(NSManagedObjectContext *)context

    * existsForPredicate:forManagedObjectContext:
        * This method checks to see if an instance of the model matching the predicate exists. This method does not need to be overwritten.

                + (BOOL)existsForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)context

    * fetchPredicate:forManagedObjectContext:
        * This method queries for an object that matches the predicate. Returns it if it does, otherwise returns nil. This method does not need to be overwritten.

                + (NSManagedObject *)fetchForPredicate:(NSPredicate *)predicate forManagedObjectContext:(NSManagedObjectContext *)context

* Shared
    * This method is available to set the information from the dictionary to the object that is passed in. After the parameters are set, the object should be returned. This method needs to be overwritten (See the example below).

            + (id)setInformationFromDictionary:(NSDictionary *)params forObject:(NSManagedObject *)object
            {
                VIPerson *person = (VIPerson *)object;
                
                person.firstName = [[params objectForKey:PARAM_FIRST_NAME] isKindOfClass:[NSNull class]] ? person.firstName :
                                       [params objectForKey:PARAM_FIRST_NAME];
                
                person.lastName = [[params objectForKey:PARAM_LAST_NAME] isKindOfClass:[NSNull class]] ? person.lastName :
                                      [params objectForKey:PARAM_LAST_NAME];

                return person;
            }

##VIFetchResultsDataSource
* This class is designed to take care of the setup needed to take care of a table view using the NSFetchedResultsController. There is little work to be done when this is subclassed.
* VIFetchResultsDataSource
    * initWithPredicate:cacheName:tableView:sortDescriptors:managedObjectClass:
        * This method initializes the class with the necessary objects to show results from coredata.

                - (id)initWithPredicate:(NSPredicate *)predicate
                              cacheName:(NSString *)cacheName
                              tableView:(UITableView *)tableView
                     sectionNameKeyPath:(NSString *)sectionNameKeyPath
                        sortDescriptors:(NSArray *)sortDescriptors
                     managedObjectClass:(Class)managedObjectClass
                     	      batchSize:(NSInteger)batchSize

            * predicate
                * The predicate will tell the NSFetchedResultsController what to filter. Can be nil.

                        predicate = [NSPredicate predicateWithFormat:@"lastName beginswith[cd] %@", [params objectForKey:PARAM_LAST_NAME]];

            * cacheName
                * The cache name sets the cache that the NSFetchedResultsController user. Can be nil.

                        cacheName = @"LastNamesBeginningWithA";

            * tableView
                * The table view that is passed is bound to the NSFetchedResultsController to display the results. Cannot be nil.

                        tableView = self.tableView;

            *sectionNameKeyPath
                * The sectionNameKeyPath tells the NSFetchedResultsController what parameter in the model to use to create sections in the table view. Can be nil.

                        sectionNameKeyPath = @"group"

            * sortDescriptors
                * The sort descriptors is an array of NSSortDescriptors that tell the NSFetchedResultsController how to display the results. Cannot be nil.

                        sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"firstName" ascending:YES]];

            * managedObjectClass
                * This is the class of the NSManagedObject that the NSFetchedResultsController will be displaying. Cannot be nil.

                        managedObjectClass = [VIPerson class];

    * cellAtIndexPath:
        * This method returns a UITableViewCell to display. This method should always be overwritten.

                - (UITableViewCell *)cellAtIndexPath:(NSIndexPath *)indexPath
                {
                    static NSString *CellIdentifier = @"CellIdentifier";
                    
                    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
                    
                    if (cell == nil) {
                        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
                    }
                    
                    VIPerson *person = [self.fetchedResultsController objectAtIndexPath:indexPath];
                    
                    cell.textLabel.text = [NSString stringWithFormat:@"%@, %@", person.lastName, person.firstName];
                    
                    return cell;
                }

* VIFetchResultsDataSourceDelegate
    * fetchResultsDataSourceSelectedObject:
        * This delegate method passes back the object that was selected at on the UITableView at the NSIndexPath. This method is optional.

                - (void)fetchResultsDataSourceSelectedObject:(NSManagedObject *)object

    * fetchResultsDataSourceHasResults:
        * This delegate methods returns a boolean if the tableView is empty. This method is optional.

                - (void)fetchResultsDataSourceHasResults:(BOOL)hasResults

