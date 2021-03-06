//
//  VerifyCodeLoginController.m
//  Coffee
//
//  Created by 杭州轨物科技有限公司 on 2018/9/20.
//  Copyright © 2018年 杭州轨物科技有限公司. All rights reserved.
//

#import "VerifyCodeLoginController.h"
#import "PhoneTFCell.h"
#import "PhoneVerifyCell.h"
#import "MainViewController.h"
#import "DataWithApi.h"
#import "HBRegisterViewController.h"

NSString *const CellIdentifier_VerifyLoginUserPhone = @"CellID_VerifyLoginuserPhone";
NSString *const CellIdentifier_VerifyLoginUserPhoneVerify = @"CellID_VerifyLoginuserPhoneVerify";


@interface VerifyCodeLoginController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UIImageView *headerImage;
@property (nonatomic, strong) UITableView *codeLoginTable;
@property (nonatomic, strong) UIButton *loginBtn;
@property (nonatomic, strong) NSString *code;
@property (nonatomic, strong) UIButton *mobileLoginBtn;
@property (nonatomic, strong) UIButton *registeBtn;

@end

@implementation VerifyCodeLoginController
static float HEIGHT_CELL = 50.f;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.layer.backgroundColor = [UIColor colorWithRed:250/255.0 green:250/255.0 blue:250/255.0 alpha:1].CGColor;
    [self setNavItem];
    
    _headerImage = [self headerImage];
    _codeLoginTable = [self codeLoginTable];
    _code = @"";
}

#pragma mark - LazyLoad
- (void)setNavItem{
    self.navigationItem.title = LocalString(@"验证码登录");
}

- (UIImageView *)headerImage{
    if (!_headerImage) {
        _headerImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"img_logo"]];
        [self.view addSubview:_headerImage];
        [_headerImage mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(140/WScale, 112/HScale));
            make.centerX.equalTo(self.view.mas_centerX);
            make.top.equalTo(self.view.mas_top).offset(20/HScale);
        }];
        
    }
    return _headerImage;
}


- (UITableView *)codeLoginTable{
    if (!_codeLoginTable) {
        _codeLoginTable = ({
            UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 150, ScreenWidth, ScreenHeight - 64)];
            tableView.backgroundColor = [UIColor clearColor];
            tableView.dataSource = self;
            tableView.delegate = self;
            [tableView registerClass:[PhoneVerifyCell class] forCellReuseIdentifier:CellIdentifier_VerifyLoginUserPhoneVerify];
            [tableView registerClass:[PhoneTFCell class] forCellReuseIdentifier:CellIdentifier_VerifyLoginUserPhone];
            tableView.separatorColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.08];
            
            [self.view addSubview:tableView];
            tableView.scrollEnabled = NO;
            
            UIView *footView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 110/HScale)];
            footView.backgroundColor = [UIColor clearColor];
            _loginBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            [_loginBtn setTitle:LocalString(@"登录") forState:UIControlStateNormal];
            _loginBtn.frame = CGRectMake(0, 30/HScale, 345/WScale, 50/HScale);
            [_loginBtn.titleLabel setFont:[UIFont systemFontOfSize:16.f]];
            [_loginBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [_loginBtn setBackgroundColor:[UIColor colorWithRed:71/255.0 green:120/255.0 blue:204/255.0 alpha:0.4]];
            [_loginBtn addTarget:self action:@selector(login) forControlEvents:UIControlEventTouchUpInside];
            _loginBtn.center = footView.center;
            _loginBtn.layer.borderWidth = 0.5;
            _loginBtn.layer.borderColor = [UIColor colorWithHexString:@"4778CC"].CGColor;
            _loginBtn.layer.cornerRadius = _loginBtn.bounds.size.height / 2.f;
            _loginBtn.enabled = NO;
            [footView addSubview:_loginBtn];
            
            _mobileLoginBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            [_mobileLoginBtn setTitle:LocalString(@"账号密码登录") forState:UIControlStateNormal];
            [_mobileLoginBtn.titleLabel setFont:[UIFont systemFontOfSize:14.f]];
            _mobileLoginBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
            [_mobileLoginBtn setBackgroundColor:[UIColor clearColor]];
            [_mobileLoginBtn setTitleColor:[UIColor colorWithHexString:@"4778CC"] forState:UIControlStateNormal];
            [_mobileLoginBtn addTarget:self action:@selector(mobileLogin) forControlEvents:UIControlEventTouchUpInside];
            [footView addSubview:_mobileLoginBtn];
            [_mobileLoginBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                make.size.mas_equalTo(CGSizeMake(100/WScale, 20/HScale));
                make.left.equalTo(self.loginBtn.mas_left);
                make.top.equalTo(self.loginBtn.mas_bottom).offset(10/HScale);
            }];

            _registeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            [_registeBtn setTitle:LocalString(@"注册新用户") forState:UIControlStateNormal];
            [_registeBtn.titleLabel setFont:[UIFont systemFontOfSize:14.f]];
            _registeBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
            [_registeBtn setBackgroundColor:[UIColor clearColor]];
            [_registeBtn setTitleColor:[UIColor colorWithHexString:@"4778CC"] forState:UIControlStateNormal];
            [_registeBtn addTarget:self action:@selector(registeUser) forControlEvents:UIControlEventTouchUpInside];
            [footView addSubview:_registeBtn];
            [_registeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                make.size.mas_equalTo(CGSizeMake(80/WScale, 20/HScale));
                make.right.equalTo(self.loginBtn.mas_right);
                make.top.equalTo(self.loginBtn.mas_bottom).offset(10/HScale);
            }];

            
            tableView.tableFooterView = footView;
            
            tableView;
        });
    }
    return _codeLoginTable;
}

#pragma mark - UITableView Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.row == 1) {
        PhoneVerifyCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier_VerifyLoginUserPhoneVerify];;
        if (cell == nil) {
            cell = [[PhoneVerifyCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier_VerifyLoginUserPhoneVerify];
        }
        cell.TFBlock = ^(NSString *text) {
            _code = text;
            [self textFieldChange];
        };
        cell.BtnBlock = ^BOOL{
            PhoneVerifyCell *cell1 = [self.codeLoginTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
            [cell1.codeTF resignFirstResponder];
            PhoneTFCell *cell2 = [self.codeLoginTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];;
            [cell2.phoneTF resignFirstResponder];

            AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
            manager.requestSerializer = [AFJSONRequestSerializer serializer];
            //设置超时时间
            [manager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
            manager.requestSerializer.timeoutInterval = 6.f;
            [manager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
            
            NSString *url;
            if ([NSString validateMobile:_phone]){
                url = [NSString stringWithFormat:@"http://139.196.90.97:8080/coffee/util/smsCode?mobile=%@",_phone];
                url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"`#%^{}\"[]|\\<> "].invertedSet];
            }else {
                [NSObject showHudTipStr:LocalString(@"手机号码不正确")];
                return NO;
            }
            
            [manager POST:url parameters:nil headers:nil progress:nil
                  success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                      
                      NSData * data = [NSJSONSerialization dataWithJSONObject:responseObject options:(NSJSONWritingOptions)0 error:nil];
                      NSString * daetr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
                      NSLog(@"success:%@",daetr);
                      if ([[responseObject objectForKey:@"errno"] intValue] == 0) {
                          [NSObject showHudTipStr:LocalString(@"已向您的手机发送验证码")];
                      }else{
                          [NSObject showHudTipStr:[responseObject objectForKey:@"error"]];
                      }
                  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                      NSLog(@"Error:%@",error);
                      if (error.code == -1001) {
                          [NSObject showHudTipStr:LocalString(@"当前网络状况不佳")];
                      }else{
                          [NSObject showHudTipStr:LocalString(@"操作失败")];
                      }
                      
                  }
             ];
            return YES;
        };
        return cell;
    }else{
        PhoneTFCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier_VerifyLoginUserPhone];;
        if (cell == nil) {
            cell = [[PhoneTFCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier_VerifyLoginUserPhone];
        }
        cell.phoneTF.text = self.phone;
        cell.TFBlock = ^(NSString *text) {
            _phone = text;
            [self textFieldChange];
        };
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return HEIGHT_CELL/HScale;
}

//section头部间距

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 15/HScale;
}
//section头部视图
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view=[[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 0)];
    view.backgroundColor = [UIColor clearColor];
    return view ;
}


#pragma mark - Actions
- (void)login{
    NSLog(@"%@",[[UIDevice currentDevice] identifierForVendor]);
    PhoneVerifyCell *cell1 = [self.codeLoginTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    [cell1.codeTF resignFirstResponder];
    PhoneTFCell *cell2 = [self.codeLoginTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];;
    [cell2.phoneTF resignFirstResponder];
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    //设置超时时间
    [manager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
    manager.requestSerializer.timeoutInterval = 6.f;
    [manager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
    
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSDictionary *parameters = @{@"mobile":_phone,@"code":_code,@"nowMobile":[[[UIDevice currentDevice] identifierForVendor] UUIDString]};
    
    [manager POST:@"http://139.196.90.97:8080/coffee/user/login/code" parameters:parameters headers:nil progress:nil
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
              
              NSData * data = [NSJSONSerialization dataWithJSONObject:responseObject options:(NSJSONWritingOptions)0 error:nil];
              NSString * daetr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
              NSLog(@"success:%@",daetr);
              if ([[responseObject objectForKey:@"errno"] intValue] == 0) {
                  DataBase *db = [DataBase shareDataBase];
                  NSDictionary *dic = [responseObject objectForKey:@"data"];
                  db.userId = [[dic objectForKey:@"userId"] copy];
                  db.userName = [dic objectForKey:@"userName"];
                  db.token = [[dic objectForKey:@"token"] copy];
                  [db initDB];
                  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                  BOOL isECSUpdate = [[userDefaults objectForKey:self.phone] boolValue];
                  [userDefaults setObject:@1 forKey:self.phone];
                  [userDefaults synchronize];
                  
                  if (![[dic objectForKey:@"lastMobile"] isEqualToString:[[[UIDevice currentDevice] identifierForVendor] UUIDString]] || !isECSUpdate) {
                      [db deleteAllTable];
                      [db createTable];
                      [[DataBase shareDataBase] getSettingByApi];
                      DataWithApi *data = [[DataWithApi alloc] init];
                      [SVProgressHUD showWithStatus:LocalString(@"从服务器同步用户存储内容中...")];
                      [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
                      [data startGetInfoSuccess:^{
                          [SVProgressHUD dismiss];
                          dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                              MainViewController *mainVC = [[MainViewController alloc] init];
                              mainVC.modalPresentationStyle = UIModalPresentationFullScreen;
                              [self presentViewController:mainVC animated:NO completion:nil];
                          });
                      } failure:^{
                          [userDefaults setObject:@0 forKey:self.phone];
                          [SVProgressHUD dismiss];
                      }];
                  }
                  MainViewController *mainVC = [[MainViewController alloc] init];
                  mainVC.modalPresentationStyle = UIModalPresentationFullScreen;
                  [self presentViewController:mainVC animated:NO completion:nil];
              }else{
                  if ([[responseObject objectForKey:@"error"] isEqualToString:@"lock"]) {
                      [NSObject showHudTipStr:LocalString(@"重试次数过多，请5分钟后再试")];
                      [self.loginBtn setBackgroundColor:[UIColor colorWithRed:71/255.0 green:120/255.0 blue:204/255.0 alpha:0.4]];
                      return;
                  }
                  [NSObject showHudTipStr:LocalString(@"登录失败，请确认验证码")];
              }
          } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
              NSLog(@"Error:%@",error);
              if (error.code == -1001) {
                  [NSObject showHudTipStr:LocalString(@"当前网络状况不佳") withTime:1.5];
              }
          }];

}

- (void)textFieldChange{
    if ([NSString validateMobile:_phone] && _code.length == 6) {
        [_loginBtn setBackgroundColor:[UIColor colorWithRed:71/255.0 green:120/255.0 blue:204/255.0 alpha:1]];
        _loginBtn.enabled = YES;
    }else{
        [_loginBtn setBackgroundColor:[UIColor colorWithRed:71/255.0 green:120/255.0 blue:204/255.0 alpha:0.4]];
        _loginBtn.enabled = NO;
    }
}

- (void)mobileLogin{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)registeUser{
    HBRegisterViewController *registVC = [[HBRegisterViewController alloc] init];
    [self.navigationController pushViewController:registVC animated:YES];
}

@end
