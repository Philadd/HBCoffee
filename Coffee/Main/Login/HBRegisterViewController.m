//
//  RegisterController.m
//  Coffee
//
//  Created by 杭州轨物科技有限公司 on 2018/9/20.
//  Copyright © 2018年 杭州轨物科技有限公司. All rights reserved.
//

#import "HBRegisterViewController.h"
#import "PhoneTFCell.h"
#import "PhoneVerifyCell.h"
#import "TextFieldCell.h"
#import "CompleteInfoController.h"
#import "firstAgreementController.h"
#import "secondAgreementController.h"

NSString *const CellIdentifier_RegisterUserPhone = @"CellID_RegisteruserPhone";
NSString *const CellIdentifier_RegisterUserPhoneVerify = @"CellID_RegisteruserPhoneVerify";
NSString *const CellIdentifier_RegisterTextField = @"CellID_RegisterTextField";

@interface HBRegisterViewController () <UITableViewDataSource, UITableViewDelegate,UITextViewDelegate>

@property (nonatomic, strong) UIImageView *headerImage;
@property (nonatomic, strong) UITableView *registerTable;
@property (nonatomic, strong) UIButton *remeberAgreementBtn;
@property (nonatomic, strong) UIButton *registerBtn;
@property (nonatomic, strong) NSString *phone;
@property (nonatomic, strong) NSString *code;
@property (nonatomic, strong) NSString *pwText;
@property (nonatomic, strong) NSString *pwConText;

@end

@implementation HBRegisterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.layer.backgroundColor = [UIColor colorWithRed:250/255.0 green:250/255.0 blue:250/255.0 alpha:1].CGColor;
    [self setNavItem];
    
    _headerImage = [self headerImage];
    _registerTable = [self registerTable];
    _phone = @"";
    _code = @"";
    _pwText = @"";
    _pwConText = @"";
}

#pragma mark - LazyLoad
static float HEIGHT_CELL = 50.f;

- (void)setNavItem{
    self.navigationItem.title = LocalString(@"注册新用户");
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

- (UITableView *)registerTable{
    if (!_registerTable) {
        _registerTable = ({
            UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 150, ScreenWidth, ScreenHeight - 64)];
            tableView.backgroundColor = [UIColor clearColor];
            tableView.dataSource = self;
            tableView.delegate = self;
            [tableView registerClass:[PhoneVerifyCell class] forCellReuseIdentifier:CellIdentifier_RegisterUserPhoneVerify];
            [tableView registerClass:[PhoneTFCell class] forCellReuseIdentifier:CellIdentifier_RegisterUserPhone];
            [tableView registerClass:[TextFieldCell class] forCellReuseIdentifier:CellIdentifier_RegisterTextField];
            tableView.separatorColor = [UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:0.08];
            
            [self.view addSubview:tableView];
            tableView.scrollEnabled = NO;
            
            UIView *footView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, 160/HScale)];
            footView.backgroundColor = [UIColor clearColor];
            _registerBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            [_registerBtn setTitle:LocalString(@"注册") forState:UIControlStateNormal];
            _registerBtn.frame = CGRectMake(0, 30/HScale, 345/WScale, 50/HScale);
            [_registerBtn.titleLabel setFont:[UIFont systemFontOfSize:16.f]];
            [_registerBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [_registerBtn setBackgroundColor:[UIColor colorWithRed:71/255.0 green:120/255.0 blue:204/255.0 alpha:0.4]];
            [_registerBtn addTarget:self action:@selector(registerUser) forControlEvents:UIControlEventTouchUpInside];
            _registerBtn.center = footView.center;
            _registerBtn.layer.borderWidth = 0.5;
            _registerBtn.layer.borderColor = [UIColor colorWithHexString:@"4778CC"].CGColor;
            _registerBtn.layer.cornerRadius = _registerBtn.bounds.size.height / 2.f;
            [footView addSubview:_registerBtn];
            
            _remeberAgreementBtn = [UIButton buttonWithType:UIButtonTypeCustom];
            _remeberAgreementBtn.tag = unselect;
            [_remeberAgreementBtn setImage:[UIImage imageNamed:@"ic_select"] forState:UIControlStateNormal];
            [_remeberAgreementBtn.imageView sizeThatFits:CGSizeMake(30.f, 30.f)];
            [_remeberAgreementBtn.titleLabel setFont:[UIFont systemFontOfSize:14.f]];
            _remeberAgreementBtn.titleLabel.adjustsFontSizeToFitWidth = YES;
            [_remeberAgreementBtn setBackgroundColor:[UIColor clearColor]];
            [_remeberAgreementBtn setTitleColor:[UIColor colorWithHexString:@"999999"] forState:UIControlStateNormal];
            [_remeberAgreementBtn addTarget:self action:@selector(remeberAgreement) forControlEvents:UIControlEventTouchUpInside];
            [footView addSubview:_remeberAgreementBtn];

            [_remeberAgreementBtn mas_makeConstraints:^(MASConstraintMaker *make) {
                make.size.mas_equalTo(CGSizeMake(20/WScale, 20/HScale));
                make.right.equalTo(self.registerBtn.mas_left).offset(60/HScale);
                make.bottom.equalTo(self.registerBtn.mas_top).offset(-10/HScale);
            }];
            //文字相对于图片的偏移量
            [_remeberAgreementBtn setImageEdgeInsets:UIEdgeInsetsMake(0, -5, 0, 0)];
            [_remeberAgreementBtn setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
            
            //富文本
            NSString *str1 = LocalString(@"我已阅读");
            NSString *str2 = LocalString(@"《用户协议》");
            NSString *str3 = LocalString(@"和");
            NSString *str4 = LocalString(@"《隐私政策》");
            
            NSString *str = [NSString stringWithFormat:@"%@%@%@%@",str1,str2,str3,str4];
            NSRange range1 = [str rangeOfString:str1];
            NSRange range2 = [str rangeOfString:str2];
            NSRange range3 = [str rangeOfString:str3];
            NSRange range4 = [str rangeOfString:str4];
            
            UITextView *textView = [[UITextView alloc] init];
            
            textView.frame = CGRectMake(0,0, ScreenWidth, 25);
            textView.backgroundColor = [UIColor clearColor];
            
            textView.scrollEnabled = NO;
            textView.editable = NO;
            
            textView.delegate = self;
            
            [footView addSubview:textView];
            
            [textView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.size.mas_equalTo(CGSizeMake(ScreenWidth, 25));
                make.left.equalTo(self.remeberAgreementBtn.mas_right);
                make.bottom.equalTo(self.registerBtn.mas_top).offset(-10/HScale);
            }];
            
            NSMutableAttributedString *mastring = [[NSMutableAttributedString alloc] initWithString:str attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:12.0f]}];
            
            [mastring addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:range1];
            
            [mastring addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:range2];
            
            [mastring addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:range3];
            
            [mastring addAttribute:NSForegroundColorAttributeName value:[UIColor greenColor] range:range4];
            
            // 1.必须要用前缀（firstAgreement，secondAgreement），随便写但是要有
            
            // 2.要有后面的方法，如果含有中文，url会无效，所以转码
            
            NSString *valueString2 = [[NSString stringWithFormat:@"firstAgreement://%@",str2] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
            
            NSString *valueString4 = [[NSString stringWithFormat:@"secondAgreement://%@",str4] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]];
            [mastring addAttribute:NSLinkAttributeName value:valueString2 range:range2];
            [mastring addAttribute:NSLinkAttributeName value:valueString4 range:range4];
            textView.attributedText = mastring;
            
            tableView.tableFooterView = footView;
            
            tableView;
        });
    }
    return _registerTable;
}

#pragma mark - UITableView Delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0) {
        if (indexPath.row == 1) {
            PhoneVerifyCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier_RegisterUserPhoneVerify];;
            if (cell == nil) {
                cell = [[PhoneVerifyCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier_RegisterUserPhoneVerify];
            }
            cell.TFBlock = ^(NSString *text) {
                _code = text;
                [self textFieldChange];
            };
            cell.BtnBlock = ^BOOL{
                PhoneVerifyCell *cell1 = [self.registerTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
                [cell1.codeTF resignFirstResponder];
                PhoneTFCell *cell2 = [self.registerTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];;
                [cell2.phoneTF resignFirstResponder];
                TextFieldCell *cell3 = [self.registerTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
                [cell3.textField resignFirstResponder];
                TextFieldCell *cell4 = [self.registerTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
                [cell4.textField resignFirstResponder];

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
                
                [manager POST:url parameters:nil  headers:nil progress:nil
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
                          }else
                          {
                              [NSObject showHudTipStr:LocalString(@"操作失败")];
                          }
                          
                      }
                ];
                return YES;
            };
            return cell;
        }else{
            PhoneTFCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier_RegisterUserPhone];;
            if (cell == nil) {
                cell = [[PhoneTFCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier_RegisterUserPhone];
            }
            cell.TFBlock = ^(NSString *text) {
                _phone = text;
                [self textFieldChange];
            };
            return cell;
        }
    }else{
        TextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier_RegisterTextField];
        if (cell == nil) {
            cell = [[TextFieldCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier_RegisterTextField];
        }
        cell.textField.secureTextEntry = YES;
        if (indexPath.row == 0) {
            cell.textField.placeholder = LocalString(@"请输入密码（6位以上字符）");
            cell.TFBlock = ^(NSString *text) {
                _pwText = text;
                [self textFieldChange];
            };
        }else{
            cell.textField.placeholder = LocalString(@"请再次输入密码");
            cell.TFBlock = ^(NSString *text) {
                _pwConText = text;
                [self textFieldChange];
            };
        }
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
- (void)registerUser{
    PhoneVerifyCell *cell1 = [self.registerTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
    [cell1.codeTF resignFirstResponder];
    PhoneTFCell *cell2 = [self.registerTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];;
    [cell2.phoneTF resignFirstResponder];
    TextFieldCell *cell3 = [self.registerTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
    [cell3.textField resignFirstResponder];
    TextFieldCell *cell4 = [self.registerTable cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:1]];
    [cell4.textField resignFirstResponder];

    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    //设置超时时间
    [manager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
    manager.requestSerializer.timeoutInterval = 6.f;
    [manager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
    
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSDictionary *parameters = [[NSDictionary alloc] init];
    if ([NSString validateMobile:_phone] && _code.length == 6 && _pwText.length >= 6 && _pwText.length <= 16 && [_pwText isEqualToString:_pwConText] && _remeberAgreementBtn.tag == select){
        self.remeberAgreementBtn.tag == unselect;
        parameters = @{@"mobile":_phone,@"password":_pwText,@"code":_code};
    }else if(![NSString validateMobile:_phone]){
        [NSObject showHudTipStr:LocalString(@"无效的手机号码")];
        return;
    }else if(_code.length != 6){
        [NSObject showHudTipStr:LocalString(@"无效的验证码")];
        return;
    }else if(_pwText.length < 6 || _pwText.length > 16){
        [NSObject showHudTipStr:LocalString(@"请输入6-16位字符的密码")];
        return;
    }else if(![_pwText isEqualToString:_pwConText]){
        [NSObject showHudTipStr:LocalString(@"两次输入的密码不一致")];
        return;
    }else{
        [NSObject showHudTipStr:LocalString(@"注册用户失败，请检查您填写的信息")];
        return;
    }
    
    [manager POST:@"http://139.196.90.97:8080/coffee/user/register" parameters:parameters headers:nil progress:nil
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
              
              NSData * data = [NSJSONSerialization dataWithJSONObject:responseObject options:(NSJSONWritingOptions)0 error:nil];
              NSString * daetr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
              NSLog(@"success:%@",daetr);
              if ([[responseObject objectForKey:@"errno"] intValue] == 0) {
                  CompleteInfoController *infoVC = [[CompleteInfoController alloc] init];
                  infoVC.mobile = self.phone;
                  infoVC.password = self.pwText;
                  [self.navigationController pushViewController:infoVC animated:YES];
              }else{
                  if ([[responseObject objectForKey:@"error"] isEqualToString:@"该用户已注册"]) {
                      [NSObject showHudTipStr:LocalString(@"该用户已注册")];
                      [self.registerBtn setBackgroundColor:[UIColor colorWithRed:71/255.0 green:120/255.0 blue:204/255.0 alpha:0.4]];
                  }
              }
          } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
              NSLog(@"Error:%@",error);
              if (error.code == -1001) {
                  [NSObject showHudTipStr:LocalString(@"当前网络状况不佳") withTime:1.5];
              }
          }];
}

- (void)textFieldChange{
    if (![_code isEqualToString:@""] && ![_phone isEqualToString:@""] && ![_pwText isEqualToString:@""] && ![_pwConText isEqualToString:@""]) {
        [_registerBtn setBackgroundColor:[UIColor colorWithRed:71/255.0 green:120/255.0 blue:204/255.0 alpha:0.4]];
    }else{
        [_registerBtn setBackgroundColor:[UIColor colorWithRed:71/255.0 green:120/255.0 blue:204/255.0 alpha:0.4]];
    }
}

- (void)remeberAgreement{
    if (_remeberAgreementBtn.tag == select) {
        _remeberAgreementBtn.tag = unselect;
        [_remeberAgreementBtn setImage:[UIImage imageNamed:@"ic_select"] forState:UIControlStateNormal];
        [_registerBtn setBackgroundColor:[UIColor colorWithRed:71/255.0 green:120/255.0 blue:204/255.0 alpha:0.4]];
        _registerBtn.enabled = NO;
    }else{
        _remeberAgreementBtn.tag = select;
        [_remeberAgreementBtn setImage:[UIImage imageNamed:@"ic_selected"] forState:UIControlStateNormal];
        [_registerBtn setBackgroundColor:[UIColor colorWithRed:71/255.0 green:120/255.0 blue:204/255.0 alpha:1]];
        _registerBtn.enabled = YES;
        //防止直接点击协议
        if ([_code isEqualToString:@""] || [_phone isEqualToString:@""] || [_pwText isEqualToString:@""] || [_pwConText isEqualToString:@""]) {
            [_registerBtn setBackgroundColor:[UIColor colorWithRed:71/255.0 green:120/255.0 blue:204/255.0 alpha:0.4]];
            _registerBtn.enabled = NO;
        }
    }
}

//富文本
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    if ([[URL scheme] isEqualToString:@"firstAgreement"]) {
        
        [self clickLinkFirst];
        return NO;
        
    } else if ([[URL scheme] isEqualToString:@"secondAgreement"]) {
        
        [self clickLinkSecond];
        return NO;
    }
    return YES;
    
}

- (void)clickLinkFirst{
    firstAgreementController *firstVC = [[firstAgreementController alloc] init];
    [self.navigationController pushViewController:firstVC animated:YES];
}

- (void)clickLinkSecond{
    secondAgreementController *secondVC = [[secondAgreementController alloc] init];
    [self.navigationController pushViewController:secondVC animated:YES];
}
@end
