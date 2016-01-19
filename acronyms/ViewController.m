//
//  ViewController.m
//  acronyms
//
//  Created by Han Li on 1/18/16.
//  Copyright © 2016 Han. All rights reserved.
//

#import "ViewController.h"
#import <AFNetworking.h>
#import <MBProgressHUD/MBProgressHUD.h>

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property (nonatomic) NSArray *resultArray;
@property (nonatomic) BOOL flag;

@end

@implementation ViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self tapDismissKeyBoard];
    [self setBackgroundImage];
    
    //set tableview cell height dynamic with content
    self.tableView.estimatedRowHeight = 55.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)viewDidAppear:(BOOL)animated{
    [self showAlert];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - User-friendly Methods

//dismiss keyboard
- (void)tapDismissKeyBoard{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
}

- (void)dismissKeyboard{
    [self.searchBar resignFirstResponder];
}

- (void)setBackgroundImage{
    UIImageView *backgroundImage = [[UIImageView alloc] initWithFrame:self.view.frame];
    [backgroundImage setImage:[UIImage imageNamed:@"background.png"]];
    
    [backgroundImage setContentMode:UIViewContentModeScaleAspectFill];
    [self.view addSubview:backgroundImage];
    [self.view sendSubviewToBack:backgroundImage];
}

- (void)showAlert{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Welcome" message:@"Start by inputing an acronym in the search bar above" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSLog(@"");
    }];
    
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - search and fetch data

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    
    //wait indication
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = @"Loading";
    
    //fetch data on background queue
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        //fetch data using AFNetworking from server
        NSString *string = @"http://www.nactem.ac.uk/software/acromine/dictionary.py?sf=";
        NSString *URLString = [string stringByAppendingString:self.searchBar.text];
        NSURL *URL = [NSURL URLWithString:URLString];
        NSURLRequest *request = [NSURLRequest requestWithURL:URL];
        
        NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
            if (error) {
                NSLog(@"Error: %@", error);
            }
            else{
                id jsonData = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:nil];
                NSArray *jsonArray = [jsonData valueForKeyPath:@"lfs.lf"];
                if ([jsonArray count] == 0) {
                    self.resultArray = [NSArray arrayWithArray:jsonArray];
                }
                else{
                    self.resultArray = [jsonArray objectAtIndex:0];
                }
                
                //update UI on main queue
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                    self.flag = true;
                    [self.searchBar resignFirstResponder];
                    [MBProgressHUD hideHUDForView:self.view animated:YES];
                });
            }
        }];
        [dataTask resume];
    });
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar{
    searchBar.text = @"";
    self.resultArray = nil;
    self.flag = false;
    [self.tableView reloadData];
}

#pragma mark - UITableView display

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if ([self.resultArray count] == 0) {
        return 1;
    }
    else{
        return [self.resultArray count];
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    
    if ([self.resultArray count] == 0 && self.flag == true) {
        cell.textLabel.text = @"Sorry, no result found!";
    }
    else if ([self.resultArray count] == 0 && self.flag == false) {
        cell.textLabel.text = @"";
    }
    else{
        cell.textLabel.text = [self.resultArray objectAtIndex:indexPath.row];
    }
    
    return cell;
}

@end
