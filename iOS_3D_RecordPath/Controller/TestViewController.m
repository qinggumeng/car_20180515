//
//  LoginViewController.m
//  loginPage
//
//  Created by 吴涛 on 15/12/23.
//  Copyright © 2015年 吴涛. All rights reserved.
//

#import "TestViewController.h"
#import <ReactiveCocoa.h>
#import <Masonry.h>
#import "AFNetworking.h"
#import "MainViewController.h"
#import "AgreementViewController.h"


@interface TestViewController ()

@property (nonatomic, strong) UILabel *loginTipLabel;

@property (nonatomic, strong) UIButton *loginButton;

@property (nonatomic, strong) UILabel *userNameLB;

@property (nonatomic, strong) UITextField *userNameTF;

@property (nonatomic, strong) UILabel *passWordLB;

@property (nonatomic, strong) UITextField *passWordTF;

// 用于显示进度,用UIProgressView 也可以,主要看个人喜好;
@property (nonatomic, strong) UILabel *intactProgress;



@end

@implementation TestViewController


#pragma mark - life

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.view.backgroundColor = [UIColor whiteColor];
    
  
}

//键盘回收
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    for(UIView *view in self.view.subviews)
    {
        [view resignFirstResponder];
    }
}


//移动UIView
-(void)transformView:(NSNotification *)aNSNotification
{
    //获取键盘弹出前的Rect
    NSValue *keyBoardBeginBounds=[[aNSNotification userInfo]objectForKey:UIKeyboardFrameBeginUserInfoKey];
    CGRect beginRect=[keyBoardBeginBounds CGRectValue];
    
    //获取键盘弹出后的Rect
    NSValue *keyBoardEndBounds=[[aNSNotification userInfo]objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect  endRect=[keyBoardEndBounds CGRectValue];
    
    //获取键盘位置变化前后纵坐标Y的变化值
    CGFloat deltaY=endRect.origin.y-beginRect.origin.y;
    NSLog(@"看看这个变化的Y值:%f",deltaY);
    
    //在0.25s内完成self.view的Frame的变化，等于是给self.view添加一个向上移动deltaY的动画
    [UIView animateWithDuration:0.25f animations:^{
        [self.view setFrame:CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y+deltaY, self.view.frame.size.width, self.view.frame.size.height)];
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
   
    
   
    
    
    
    //注册观察键盘的变化
  //  [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(transformView:) name:UIKeyboardWillChangeFrameNotification object:nil];
    
    [self.view addSubview:self.loginTipLabel];
    [self.view addSubview:self.intactProgress];
   // [self.view addSubview:self.userNameLB];
    [self.view addSubview:self.userNameTF];
    //[self.view addSubview:self.passWordLB];
    [self.view addSubview:self.passWordTF];
    [self.view addSubview:self.loginButton];
    
    
    [self.navigationItem setTitle:@"登录"];
    
    [self addConstraints];
    [self addobservers];
    // Do any additional setup after loading the view.
    
    [self.loginButton addTarget:self action:@selector(loginfun:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark - addObservers && addConstraints

static CGFloat buttonW = 150;

#pragma mark - 封装弹出对话框方法
// 提示错误信息
- (void)showError:(NSString *)errorMsg {
    // 1.弹框提醒
    // 初始化对话框
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:errorMsg preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
    // 弹出对话框
    [self presentViewController:alert animated:true completion:nil];
}

-(void)loginfun:(UIButton*)sender{
    AFHTTPSessionManager *session = [AFHTTPSessionManager manager];
    session.requestSerializer = [AFHTTPRequestSerializer serializer];
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"phone"] = self.userNameTF.text;
    params[@"pwd"] = self.passWordTF.text;
    
    NSLog(@"%@",params[@"phone"]);
    NSLog(@"%@",params[@"pwd"]);
    
    [session POST:@"http://106.14.160.90:8082/findmycar/pilot/findIsLogin.do" parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"%@",responseObject);
        
        NSString *token = [responseObject valueForKeyPath:@"token"];
        NSString *id = [responseObject valueForKeyPath:@"id"];
        if(token==nil){
            // 弹出“请检查用户名和密码是否为空！”对话框
            [self showError:@"请检查用户名和密码是否正确！"];
        }else{
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:token forKey:@"token"];
            [defaults setObject:id forKey:@"id"];
            [defaults synchronize];
         
            UIViewController *recordController = [[AgreementViewController alloc] init];
            recordController.title = @"司机版APP隐私政策";
            
            [self.navigationController pushViewController:recordController animated:YES];
        }
        
        
        
//        NSArray *dict = [responseObject valueForKeyPath:@"subjects"];
//
//        for (int i = 0; i<5; i++) {
//            NSString *title = [dict[i] valueForKeyPath:@"title"];
//            NSString *image = [dict[i] valueForKeyPath:@"images.large"];
//            //NSLog(@"%@",image);
//            [_datas appendObject:title];
//            [_images appendObject:image];
//        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"%@",error);
    }];
    
   
       
}

- (void)addobservers{
    
    // 假设账号是11位, 密码是6位, 账号密码位数不对时无法进行登陆操作
    
    
    @weakify(self);
    
    // 根据userName 是否是11位来改变 passTF的enable;
    [self.userNameTF.rac_textSignal subscribeNext:^(NSString *userName) {
        @strongify(self);
        self.passWordTF.enabled = userName.length == 11 ? YES : NO;

    }];
    
    // 根据pass enable 来改变背景颜色
    [RACObserve(self.passWordTF, enabled) subscribeNext:^(NSNumber *x) {
        @strongify(self);
        self.loginButton.backgroundColor = [x boolValue] ?
        [UIColor redColor] : [UIColor lightGrayColor];
    }];
    
    // 根据 pass 是否是6位来 决定是否可以进行Login操作
    [[[self.passWordTF.rac_textSignal
       filter:^BOOL(NSString  *value) {
           if (value.length == 0) {
               @strongify(self);
               [self.intactProgress mas_updateConstraints:^(MASConstraintMaker *make) {
                   make.width.mas_equalTo(0);
               }];
           }
           return value.length > 5 && value.length < 10;
       }]
      map:^id(NSString  *value) {
          return @(value.length);
      }]
     subscribeNext:^(NSNumber *x) {
         @strongify(self);
         [self.intactProgress mas_updateConstraints:^(MASConstraintMaker *make) {
             make.width.mas_equalTo(buttonW*([x floatValue] / 6.f));
         }];
     }];
}

// 加约束
- (void)addConstraints{
    [self.loginTipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).offset(100);
        make.centerX.equalTo(self.view);
    }];
    
    
//    [self.userNameLB mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.left.equalTo(self.view).offset(60);
//        make.top.equalTo(self.loginTipLabel.mas_bottom).offset(80);
//    }];
    
    [self.userNameTF mas_makeConstraints:^(MASConstraintMaker *make) {
        //make.left.equalTo(self.userNameLB.mas_right).offset(10);
        make.left.equalTo(self.view.mas_left).offset(20);
        make.right.equalTo(self.view.mas_right).offset(-20);
        make.height.equalTo(@40);
       // make.centerY.equalTo(self.userNameLB);
        make.top.equalTo(self.loginTipLabel).offset(60);
    }];
    
//    [self.passWordLB mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.right.equalTo(self.userNameLB);
//        make.top.equalTo(self.userNameLB.mas_bottom).offset(50);
//    }];
    
    [self.passWordTF mas_makeConstraints:^(MASConstraintMaker *make) {
      //  make.left.equalTo(self.passWordLB.mas_right).offset(10);
        make.left.equalTo(self.view.mas_left).offset(20);
        make.right.equalTo(self.view.mas_right).offset(-20);
        make.height.equalTo(@40);
        //make.centerY.equalTo(self.passWordLB);
        make.top.equalTo(self.userNameTF).offset(70);
        
    }];
    
    [self.loginButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view);
        make.top.equalTo(self.passWordTF.mas_bottom).offset(50);
        make.height.equalTo(@40);
        make.left.equalTo(self.view.mas_left).offset(20);
        make.right.equalTo(self.view.mas_right).offset(-20);
        //make.height.mas_equalTo(30);
    }];
    
    
    [self.intactProgress mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.height.equalTo(self.loginButton);
        make.width.mas_equalTo(0);
    }];
    
    
    
    
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



#pragma mark - setter && getter

// 进度条
- (UILabel *)intactProgress{
    if (_intactProgress == nil) {
        _intactProgress = [UILabel new];
        _intactProgress.backgroundColor = [UIColor yellowColor];
    }
    return _intactProgress;
}


// 密码填写
- (UITextField *)passWordTF{
    if (_passWordTF == nil) {
        _passWordTF = [UITextField new];
        _passWordTF.placeholder = @"请输入密码";
        _passWordTF.layer.borderWidth = 1;
        _passWordTF.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        _passWordTF.secureTextEntry = YES;
        
        //设置左边视图的宽度
        
        _passWordTF.leftView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 8, 0)];
        
        //设置显示模式为永远显示(默认不显示 必须设置 否则没有效果)
        
        _passWordTF.leftViewMode = UITextFieldViewModeAlways;
    }
    return _passWordTF;
}

// 用户名填写
- (UITextField *)userNameTF{
    if (_userNameTF == nil) {
        _userNameTF = [UITextField new];
        _userNameTF.placeholder = @"请输入手机号";
        //_userNameTF.borderStyle = UITextBorderStyleLine;
        _userNameTF.layer.borderWidth = 1;
       _userNameTF.layer.borderColor = [[UIColor lightGrayColor] CGColor];
        _userNameTF.keyboardType = UIKeyboardTypeNumberPad;
        //设置左边视图的宽度
        
       _userNameTF.leftView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 8, 0)];
        
        //设置显示模式为永远显示(默认不显示 必须设置 否则没有效果)
        
        _userNameTF.leftViewMode = UITextFieldViewModeAlways;
    }
    return _userNameTF;
}


// 密码
- (UILabel *)passWordLB{
    if (_passWordLB == nil) {
        _passWordLB = [UILabel new];
        _passWordLB.text = @"密码";
    }
    return _passWordLB;
}


// 用户名
- (UILabel *)userNameLB{
    if (_userNameLB == nil) {
        _userNameLB = [UILabel new];
        _userNameLB.text = @"手机号";
    }
    return _userNameLB;
}


// 登陆
- (UILabel *)loginTipLabel{
    if (_loginTipLabel == nil) {
        _loginTipLabel = [UILabel new];
        _loginTipLabel.text = @"在途监控登录";
        _loginTipLabel.font =  [UIFont fontWithName:@"Arial-BoldItalicMT" size:24];
    }
    return _loginTipLabel;
}

// 登陆按钮
- (UIButton *)loginButton{
    if (_loginButton == nil) {
        _loginButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_loginButton setTitle:@"登录" forState:UIControlStateNormal];
        [_loginButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_loginButton setBackgroundColor:UIColor.lightGrayColor];
         _loginButton.layer.cornerRadius = 5;
        [_loginButton.layer setMasksToBounds:YES];
    }
    return _loginButton;
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

