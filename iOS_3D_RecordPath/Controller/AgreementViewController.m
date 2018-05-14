//
//  AgreementViewController.m
//  iOS_3D_RecordPath
//
//  Created by zheng zhang on 2018/3/31.
//  Copyright © 2018年 FENGSHENG. All rights reserved.
//

#import "AgreementViewController.h"
#import "MainViewController.h"


@interface AgreementViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *webview;

@end

@implementation AgreementViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.navigationItem setTitle:@"司机版APP隐私政策"];
    [self.navigationItem setHidesBackButton:TRUE animated:NO];
    NSURL *url = [NSURL URLWithString:@"http://106.14.160.90:8082/agreement.htm"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [_webview loadRequest:request];
    
    
   
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)agreeclick:(UIButton *)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"true" forKey:@"agree"];
    [defaults synchronize];
    
    UIViewController *recordController = [[MainViewController alloc] init];
    recordController.title = @"在途监控测试";
    
    [self.navigationController pushViewController:recordController animated:YES];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
