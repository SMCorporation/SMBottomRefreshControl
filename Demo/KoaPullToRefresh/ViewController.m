//
//  ViewController.m
//  KoaPullToRefresh
//
//  Created by Sergi Gracia on 09/05/13.
//  Copyright (c) 2013 Sergi Gracia. All rights reserved.
//

#import "ViewController.h"
#import "KoaBottomPullToRefresh.h"
#import <QuartzCore/QuartzCore.h>

@interface ViewController ()

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *tableValues;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    //Init values
    self.tableValues = [[NSMutableArray alloc] initWithObjects: @"Croissant cookie gingerbread",
                                                                @"Chocolate bar marshmallow",
                                                                @"Pudding carrot cake",
                                                                @"Topping candy canes chocolate bar",
                                                                @"Fruitcake chocolate",
                                                                @"Brownie biscuit",
                                                                @"Gummies ice cream",
                                                                @"Topping sesame snaps",
                                                                @"Topping marshmallow applicake",
                                                                @"Toffee jujubes",
                                                                @"Tart macaroon muffin",
                                                                @"Lemon drops",
                                                                @"Dessert biscuit oat cake",
                                                                @"Chocolate bar pastry", nil];
    
    //Add pull to refresh
    [self.tableView addBottomPullToRefreshWithActionHandler:^{
        [self refreshTable];
    } backgroundColor:[UIColor colorWithRed:0.251 green:0.663 blue:0.827 alpha:1] pullToRefreshHeightShowed:4];
    
    //Customize pulltorefresh text colors
    [self.tableView.bottomPullToRefreshView setTextColor:[UIColor whiteColor]];
    [self.tableView.bottomPullToRefreshView setTextFont:[UIFont fontWithName:@"OpenSans-Semibold" size:16]];
    
    //Set fontawesome icon
    [self.tableView.bottomPullToRefreshView setFontAwesomeIcon:@"icon-refresh"];

    //Set titles
    [self.tableView.bottomPullToRefreshView setTitle:@"Pull" forState:KoaBottomPullToRefreshStateStopped];
    [self.tableView.bottomPullToRefreshView setTitle:@"Release" forState:KoaBottomPullToRefreshStateTriggered];
    [self.tableView.bottomPullToRefreshView setTitle:@"Loading" forState:KoaBottomPullToRefreshStateLoading];
    
    //Hide scroll indicator
    [self.tableView setShowsVerticalScrollIndicator:NO];

//    [self.tableView.pullToRefreshView startAnimating];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.tableView.bottomPullToRefreshView performSelector:@selector(stopAnimating) withObject:nil afterDelay:5];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)refreshTable
{
    [self performSelector:@selector(newValues) withObject:nil afterDelay:5];
}

- (void)newValues
{
    self.tableValues = [@[@"Croissant cookie gingerbread",
                          @"Chocolate bar marshmallow",
                          @"Pudding carrot cake",
                          @"Topping candy canes chocolate bar",
                          @"Fruitcake chocolate",
                          @"Brownie biscuit",
                          @"Gummies ice cream",
                          @"Topping sesame snaps",
                          @"Topping marshmallow applicake",
                          @"Toffee jujubes",
                          @"Tart macaroon muffin",
                          @"Lemon drops",
                          @"Dessert biscuit oat cake",
                          @"Chocolate bar pastry",
                          @"New Value 1",
                          @"New Value 2",
                          @"New Value 3",
                          @"New Value 4",
                          @"New Value 5",
                          @"New Value 6",
                          @"New Value 7",
                          @"New Value 8",
                          @"New Value 9",
                          @"New Value 10",] mutableCopy];

    [self.tableView reloadData];
    [self.tableView.bottomPullToRefreshView stopAnimating];

}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.tableValues.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    
    cell.textLabel.text = [self.tableValues objectAtIndex:indexPath.row];
    [cell.textLabel setFont:[UIFont fontWithName:@"OpenSans-Semibold" size:13]];
    [cell.textLabel setTextColor:[UIColor grayColor]];
    [cell setBackgroundColor:[UIColor whiteColor]];
    
    return cell;
}

@end
