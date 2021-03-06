//
//  OAOptionsPanelBlackViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 04.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAOptionsPanelBlackViewController.h"
#import "OAMapSettingsViewController.h"
#import "OASettingsViewController.h"
#import "OAFavoriteListViewController.h"
#import "OAWebViewController.h"

@interface OAOptionsPanelBlackViewController ()

@property (weak, nonatomic) IBOutlet UIButton *menuButtonMaps;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonMyData;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonSettings;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonMapsAndResources;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonQuiz;
@property (weak, nonatomic) IBOutlet UIButton *menuButtonHelp;

@end

@implementation OAOptionsPanelBlackViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated {
    self.menuButtonMaps.layer.borderColor = [[UIColor colorWithRed:70.0/255.0 green:70.0/255.0 blue:71.0/255.0 alpha:1] CGColor];
    self.menuButtonMaps.layer.borderWidth = 1.0;
    
    self.menuButtonMyData.layer.borderColor = [[UIColor colorWithRed:70.0/255.0 green:70.0/255.0 blue:71.0/255.0 alpha:1] CGColor];
    self.menuButtonMyData.layer.borderWidth = 1.0;
    
    self.menuButtonMapsAndResources.layer.borderColor = [[UIColor colorWithRed:70.0/255.0 green:70.0/255.0 blue:71.0/255.0 alpha:1] CGColor];
    self.menuButtonMapsAndResources.layer.borderWidth = 1.0;
    
    
    self.menuButtonSettings.layer.borderColor = [[UIColor colorWithRed:70.0/255.0 green:70.0/255.0 blue:71.0/255.0 alpha:1] CGColor];
    self.menuButtonSettings.layer.borderWidth = 1.0;
    
    self.menuButtonQuiz.layer.borderColor = [[UIColor colorWithRed:70.0/255.0 green:70.0/255.0 blue:71.0/255.0 alpha:1] CGColor];
    self.menuButtonQuiz.layer.borderWidth = 1.0;
    
    self.menuButtonHelp.layer.borderColor = [[UIColor colorWithRed:70.0/255.0 green:70.0/255.0 blue:71.0/255.0 alpha:1] CGColor];
    self.menuButtonHelp.layer.borderWidth = 1.0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)mapsButtonClicked:(id)sender {
    OAMapSettingsViewController* settingsViewController = [[OAMapSettingsViewController alloc] init];
    [self.navigationController pushViewController:settingsViewController animated:YES];
}

- (IBAction)myDataButtonClicked:(id)sender {
    OAFavoriteListViewController* settingsViewController = [[OAFavoriteListViewController alloc] init];
    [self.navigationController pushViewController:settingsViewController animated:YES];
}

- (IBAction)settingsButtonClicked:(id)sender {
    OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:kSettingsScreenGeneral];
    [self.navigationController pushViewController:settingsViewController animated:YES];
}


- (IBAction)mapsAndResourcesButtonClicked:(id)sender {
    OASettingsViewController* resourcesViewController = [[UIStoryboard storyboardWithName:@"Resources" bundle:nil] instantiateInitialViewController];
    [self.navigationController pushViewController:resourcesViewController animated:YES];
}

- (IBAction)helpButtonClicked:(id)sender {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Copyright OsmAnd 2014" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

- (IBAction)quizButtonClicked:(id)sender {
    OAWebViewController* quizViewController = [[OAWebViewController alloc] initWithUrl:@"http://kwiksurveys.com/app/showpoll.asp?qid=457757&sid=iis3saqkqrn2pos457757&new=True"];
    [self.navigationController pushViewController:quizViewController animated:YES];
}




@end
