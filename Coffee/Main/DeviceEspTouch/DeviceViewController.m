//
//  DeviceViewController.m
//  Coffee
//
//  Created by 杭州轨物科技有限公司 on 2018/6/24.
//  Copyright © 2018年 杭州轨物科技有限公司. All rights reserved.
//

#import "DeviceViewController.h"
#import "EspViewController.h"
#import "GCDAsyncUdpSocket.h"
#import <CocoaAsyncSocket/GCDAsyncSocket.h>
#import "GCDAsyncSocket.h"
#import "TouchTableView.h"
#import "DeviceTableViewCell.h"
#import "MJRefresh.h"
#import "DeviceModel.h"
#import "FMDB.h"
#import "AA_TFAlertController.h"

#import <SystemConfiguration/CaptiveNetwork.h>


#define HEIGHT_CELL 70.f
#define HEIGHT_HEADER 44.f
#define resendTimes 3

NSString *const CellIdentifier_device = @"CellID_device";

@interface DeviceViewController () <GCDAsyncUdpSocketDelegate,GCDAsyncSocketDelegate,UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) GCDAsyncUdpSocket *udpSocket;
@property (nonatomic, strong) GCDAsyncSocket *socket;//判断某个设备是否在当前网络并可以连接
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSLock *lock;

@property (nonatomic, strong) UITableView *devieceTable;
@property (nonatomic, strong) UIView *noDeviceView;

///@brief 当前设备
@property (nonatomic, strong) NSMutableArray *onlineDeviceArray;
///@brief 本地所有设备数组
@property (nonatomic, strong) NSMutableArray *deviceArray;

@end

@implementation DeviceViewController
{
    BOOL isConnect;
    int resendTime;
    NSMutableDictionary *ipAndSnDic;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor colorWithRed:250/255.0 green:250/255.0 blue:250/255.0 alpha:1]];

    self.navigationItem.title = LocalString(@"我的设备");
    
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    rightButton.frame = CGRectMake(0, 0, 30, 30);
    [rightButton setImage:[UIImage imageNamed:@"ic_nav_add_black"] forState:UIControlStateNormal];
    [rightButton addTarget:self action:@selector(goEsp) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc] initWithCustomView:rightButton];
    self.navigationItem.rightBarButtonItem = rightBarButton;
    
    _onlineDeviceArray = [NSMutableArray array];
    ipAndSnDic = [[NSMutableDictionary alloc] init];
    _noDeviceView = [self noDeviceView];
    _devieceTable = [self devieceTable];
    _lock = [self lock];
    _socket = [self socket];
    
    if (!_deviceArray.count && !_onlineDeviceArray.count && ![NetWork shareNetWork].connectedDevice) {
        _devieceTable.hidden = YES;
        _noDeviceView.hidden = NO;
    }else{
        _devieceTable.hidden = NO;
        _noDeviceView.hidden = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.rdv_tabBarController setTabBarHidden:YES animated:YES];
    if (!_timer) {
        _timer = [self timer];
    }
    if (self.devieceTable) {
        [self queryDevices];
    }
    
    [self showWifiConnectError];
    
    [_lock unlock];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mysocketDidDisconnect) name:@"mysocketDidDisconnect" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"mysocketDidDisconnect" object:nil];
    
    [_timer setFireDate:[NSDate distantFuture]];
    [_timer invalidate];
    _timer = nil;
    
    [_udpSocket close];
    _udpSocket = nil;
    [_lock unlock];
}

- (void)dealloc{
    if (_timer) {
        [_timer fire];
        _timer = nil;
    }
}

- (void)applicationWillEnterForeground{
    UIApplication *app = [UIApplication sharedApplication];
    [[NSNotificationCenter defaultCenter]addObserverForName:UIApplicationWillEnterForegroundNotification  object:app queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [self sendSearchBroadcast];
    }];
}

#pragma mark - lazy load
- (UITableView *)devieceTable{
    if (!_devieceTable) {
        _devieceTable = ({
            TouchTableView *tableView = [[TouchTableView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, ScreenHeight - getRectNavAndStatusHight) style:UITableViewStylePlain];
            tableView.backgroundColor = [UIColor clearColor];
            tableView.dataSource = self;
            tableView.delegate = self;
            tableView.hidden = YES;
            tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
            [tableView registerClass:[DeviceTableViewCell class] forCellReuseIdentifier:CellIdentifier_device];
            [self.view addSubview:tableView];
            tableView.estimatedRowHeight = 0;
            tableView.estimatedSectionHeaderHeight = 0;
            tableView.estimatedSectionFooterHeight = 0;
            //tableView.scrollEnabled = NO;
            if ([tableView respondsToSelector:@selector(setSeparatorInset:)]) {
                [tableView setSeparatorInset:UIEdgeInsetsZero];
            }
            if ([tableView respondsToSelector:@selector(setLayoutMargins:)])  {
                [tableView setLayoutMargins:UIEdgeInsetsZero];
            }
            
            MJRefreshGifHeader *header = [MJRefreshGifHeader headerWithRefreshingTarget:self refreshingAction:@selector(refreshDevices)];
            // Set title
            [header setTitle:LocalString(@"下拉刷新") forState:MJRefreshStateIdle];
            [header setTitle:LocalString(@"松开刷新") forState:MJRefreshStatePulling];
            [header setTitle:LocalString(@"加载中") forState:MJRefreshStateRefreshing];
            
            // Set font
            header.stateLabel.font = [UIFont systemFontOfSize:15];
            header.lastUpdatedTimeLabel.font = [UIFont systemFontOfSize:14];
            
            // Set textColor
            header.stateLabel.textColor = [UIColor lightGrayColor];
            header.lastUpdatedTimeLabel.textColor = [UIColor lightGrayColor];
            tableView.mj_header = header;
            tableView;
        });
    }
    return _devieceTable;
}

- (UIView *)noDeviceView{
    if (!_noDeviceView) {
        _noDeviceView = [[UIView alloc] init];
        _noDeviceView.frame = CGRectMake(0, 0, ScreenWidth, ScreenHeight);
        _noDeviceView.backgroundColor = [UIColor colorWithRed:250/255.0 green:250/255.0 blue:250/255.0 alpha:1];
        _noDeviceView.hidden = YES;
        [self.view addSubview:_noDeviceView];
        
        UIImageView *deviceImage = [[UIImageView alloc] init];
        deviceImage.image = [UIImage imageNamed:@"img_logo_gray"];
        [_noDeviceView addSubview:deviceImage];
        
        UILabel *label = [[UILabel alloc] init];
        label.text = LocalString(@"快添加您的第一个设备吧～");
        label.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
        label.textColor = [UIColor colorWithRed:51/255.0 green:51/255.0 blue:51/255.0 alpha:1];
        [_noDeviceView addSubview:label];
        
        UIButton *addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [addBtn setTitle:LocalString(@"添加设备") forState:UIControlStateNormal];
        [addBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [addBtn.titleLabel setFont:[UIFont fontWithName:@"PingFangSC-Medium" size:16]];
        [addBtn setButtonStyleWithColor:[UIColor clearColor] Width:1.0 cornerRadius:yButtonHeight * 0.5];
        [addBtn setBackgroundColor:[UIColor colorWithRed:71/255.0 green:120/255.0 blue:204/255.0 alpha:1]];
        [addBtn addTarget:self action:@selector(goEsp) forControlEvents:UIControlEventTouchUpInside];
        [_noDeviceView addSubview:addBtn];
        
        [deviceImage mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(225.f / WScale, 150.f / HScale));
            make.centerX.equalTo(_noDeviceView.mas_centerX);
            make.top.equalTo(_noDeviceView.mas_top).offset(80.f / HScale);
        }];
        
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(168.f / WScale, 20.f / HScale));
            make.centerX.equalTo(_noDeviceView.mas_centerX);
            make.top.equalTo(_noDeviceView.mas_top).offset(334.f / HScale);
        }];
        
        [addBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake(345.f / WScale, 50.f / HScale));
            make.centerX.equalTo(_noDeviceView.mas_centerX);
            make.top.equalTo(_noDeviceView.mas_top).offset(374.f / HScale);
        }];
    }
    return _noDeviceView;
}

- (NSTimer *)timer{
    if(!_timer){
        _timer = [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(broadcast) userInfo:nil repeats:YES];
        [_timer setFireDate:[NSDate distantFuture]];
    }
    return _timer;
}

-(NSLock *)lock{
    if (!_lock) {
        _lock = [[NSLock alloc] init];
    }
    return _lock;
}

#pragma mark - udp
- (GCDAsyncUdpSocket *)udpSocket{
    if (!_udpSocket) {
        _udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
    }
    return _udpSocket;
}

- (void)sendSearchBroadcast{
    
    resendTime = resendTimes;
    
    _udpSocket = nil;
    _udpSocket = [self udpSocket];
    
    [_udpSocket localPort];
    
    NSError *error;
    
    //设置广播
    [_udpSocket enableBroadcast:YES error:&error];
    
    //开启接收数据
    [_udpSocket beginReceiving:&error];
    if (error) {
        NSLog(@"开启接收数据:%@",error);
        return;
    }
    
    isConnect = NO;
    [_timer setFireDate:[NSDate date]];
}

- (void)broadcast{
    if (isConnect || resendTime == 0) {
        //[_timer setFireDate:[NSDate distantFuture]];
       // NSLog(@"发送三次udp请求或已经接收到数据");
        [self.devieceTable.mj_header endRefreshing];
    }else{
        resendTime--;
    }
    
    NSString *currentIP = [NSObject getIPAddress];
    NSString *host = @"";
    if ([currentIP isEqualToString:@"error"]) {
        [self showNoWifiConnect];
        resendTime = 0;
    }else{
        NSArray *array = [currentIP componentsSeparatedByString:@"."];
        host = [NSString stringWithFormat:@"%@.%@.%@.255",array[0],array[1],array[2]];
    }
    NSLog(@"%@",host);
    NSTimeInterval timeout = 2000;
    NSString *request = @"whereareyou\r\n";
    NSData *data = [NSData dataWithData:[request dataUsingEncoding:NSASCIIStringEncoding]];
    UInt16 port = 17888;

    [_udpSocket sendData:data toHost:host port:port withTimeout:timeout tag:200];
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext{
    [_lock lock];
    NSLog(@"UDP接收数据……………………………………………………");
    [self.devieceTable.mj_header endRefreshing];
    isConnect = YES;//停止发送udp
    if (1) {
        /**
         *获取IP地址
         **/
        NSString *ipAddress = [address IpAddress];
        
        //避免重复显示同一个设备
        for (DeviceModel *device in _onlineDeviceArray) {
            if ([ipAddress isEqualToString:device.ipAddress]) {
                return;
            }
        }
        
        DeviceModel *dModel = [[DeviceModel alloc] init];
        dModel.ipAddress = ipAddress;
        NSLog(@"strAddr = %@", ipAddress);
        
        NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"%@",msg);
        dModel.sn = [msg substringWithRange:NSMakeRange(0, 8)];
        
        if ([[NetWork shareNetWork].connectedDevice.sn isEqualToString:dModel.sn]) {
            //如果已经连接了
            [_lock unlock];
            return;
        }
        
        //判断本地是否已经存储过，如果有则将_deviceArray中的该设备删除，如果没有则存储该设备
        BOOL isStored = [[DataBase shareDataBase] queryDevice:[msg substringWithRange:NSMakeRange(0, 8)]];
        if (!isStored) {
            AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
            //AFHTTPSessionManager 的POST请求默认是用FORM请求的,如果需要转为JSON
            manager.requestSerializer = [AFJSONRequestSerializer serializer];
            //设置超时时间
            [manager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
            manager.requestSerializer.timeoutInterval = 6.f;
            [manager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
            
            [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
            [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@",[DataBase shareDataBase].token] forHTTPHeaderField:@"Authorization"];
            [manager.requestSerializer setValue:[DataBase shareDataBase].userId forHTTPHeaderField:@"userId"];
            
            NSNumber *deviceType;
            NSString *name;
            if ([ipAddress isEqualToString:[NetWork shareNetWork].ipAddr]) {
                deviceType = [NetWork shareNetWork].deviceType;
                name = [self getNameByDeviceType:deviceType];
            }else{
                [_lock unlock];
                return;//修改成未保存且未配网不显示了，防止一个账号配网后另一个账号出现乱码
//                deviceType = @0;
//                name = [msg substringWithRange:NSMakeRange(0, 8)];
            }
            
            
            dModel.deviceType = deviceType;
            dModel.deviceName = name;
            NSDictionary *parameters = @{@"sn":[msg substringWithRange:NSMakeRange(0, 8)],@"name":name,@"userId":[DataBase shareDataBase].userId,@"deviceType":deviceType};
            [manager POST:@"http://139.196.90.97:8080/coffee/roaster" parameters:parameters headers:nil progress:nil
                  success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                      
                      if ([[responseObject objectForKey:@"errno"] intValue] == 0) {
                          [NSObject showHudTipStr:LocalString(@"添加新设备到服务器成功")];
                          //[self setRouteInfoWithSn:dModel.sn ip:ipAddress];
                          [[DataBase shareDataBase].queueDB inDatabase:^(FMDatabase * _Nonnull db) {
                              BOOL result = [db executeUpdate:@"INSERT INTO device (sn,deviceName,deviceType) VALUES (?,?,?)",[msg substringWithRange:NSMakeRange(0, 8)],name,deviceType];
                              if (result) {
                                  NSLog(@"插入新设备到device成功");
                                  [NetWork shareNetWork].ipAddr = @"";
                              }else{
                                  NSLog(@"插入新设备到device失败");
                              }
                          }];
                      }else{
                          [NSObject showHudTipStr:LocalString(@"添加新设备到服务器失败")];
                      }
                  } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                      NSLog(@"Error:%@",error);
                      if (error.code == -1001) {
                          [NSObject showHudTipStr:LocalString(@"当前网络状况不佳")];
                      }
                  }];
        }else{
            for (int i = 0; i < _deviceArray.count; i++) {
                DeviceModel *device = _deviceArray[i];
                if ([[msg substringWithRange:NSMakeRange(0, 8)] isEqualToString:device.sn]) {
                    dModel.deviceName = device.deviceName;
                    dModel.deviceType = device.deviceType;
                    [_deviceArray removeObject:device];
                    break;
                }
            }
            if ([ipAddress isEqualToString:[NetWork shareNetWork].ipAddr]) {
                NSLog(@"%@    %@",ipAddress,[NetWork shareNetWork].ipAddr);
                //更新咖啡机设备的信息
                NSNumber *deviceType = [NetWork shareNetWork].deviceType;
                AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
                manager.requestSerializer = [AFJSONRequestSerializer serializer];
                //设置超时时间
                [manager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
                manager.requestSerializer.timeoutInterval = 6.f;
                [manager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
                
                [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
                [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@",[DataBase shareDataBase].token] forHTTPHeaderField:@"Authorization"];
                [manager.requestSerializer setValue:[DataBase shareDataBase].userId forHTTPHeaderField:@"userId"];
                dModel.deviceType = deviceType;
                NSString *name = [self getNameByDeviceType:deviceType];
                dModel.deviceName = name;

                NSDictionary *parameters = @{@"sn":[msg substringWithRange:NSMakeRange(0, 8)],@"name":name,@"userId":[DataBase shareDataBase].userId,@"deviceType":deviceType};
                [manager PUT:@"http://139.196.90.97:8080/coffee/roaster" parameters:parameters headers:nil
                     success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                         
                         NSLog(@"%@",responseObject);
                         if ([[responseObject objectForKey:@"errno"] intValue] == 0) {
                             //[self setRouteInfoWithSn:dModel.sn ip:ipAddress];
                             [[DataBase shareDataBase].queueDB inDatabase:^(FMDatabase * _Nonnull db) {
                                 BOOL result = [db executeUpdate:@"UPDATE device SET deviceType = ?,deviceName = ? WHERE sn = ?",deviceType,name,[msg substringWithRange:NSMakeRange(0, 8)]];
                                 if (result) {
                                     [NetWork shareNetWork].ipAddr = @"";
                                     NSLog(@"更新咖啡机到device表成功");
                                 }else{
                                     NSLog(@"更新咖啡机到device表失败");
                                 }
                             }];
                         }else{
                             [NSObject showHudTipStr:LocalString(@"更新咖啡机到服务器失败")];
                         }
                     } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                         NSLog(@"Error:%@",error);
                         if (error.code == -1001) {
                             [NSObject showHudTipStr:LocalString(@"当前网络状况不佳")];
                         }
                     }];
            }
        }
        
        [_onlineDeviceArray updateOrAddDeviceModel:dModel];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.onlineDeviceArray.count) {
                self.devieceTable.hidden = YES;
                self.noDeviceView.hidden = NO;
            }else{
                self.devieceTable.hidden = NO;
                self.noDeviceView.hidden = YES;
            }
            
            [self.devieceTable reloadData];
        });
        
    }
    sleep(1.f);
    [_lock unlock];
}

- (NSString *)getNameByDeviceType:(NSNumber *)deviceType{
    NSString *name;
    switch ([deviceType intValue]) {
        case 0:
        {
            name = LocalString(@"HB-M6G咖啡烘焙机");
        }
            break;
            
        case 1:
        {
            name = LocalString(@"HB-L2咖啡烘焙机");
            
        }
            break;
            
        case 2:
        {
            name = LocalString(@"PEAK-Edmund咖啡烘焙机");
        }
            break;
            
        case 3:
        {
            
            name = LocalString(@"HB-M6E咖啡烘焙机");
        }
            break;
            
        case 4:{
            name = LocalString(@"其他机型咖啡烘焙机");
        }
            break;
            
        default:
            name = LocalString(@"其他机型咖啡烘焙机");
            break;
    }
    return name;
}


- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError *)error{
    NSLog(@"断开连接");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag{
    NSLog(@"发送的消息");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address{
    NSLog(@"已经连接");
}

- (void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error{
    NSLog(@"断开连接");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error{
    NSLog(@"没有发送数据");
}

#pragma mark - tcp
- (GCDAsyncSocket *)socket{
    if (!_socket) {
        _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
    }
    return _socket;
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    NSLog(@"连接成功");
    NSString *sn = [ipAndSnDic objectForKey:host];
    for (DeviceModel *device in _deviceArray) {
        if([device.sn isEqualToString:sn]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.devieceTable.mj_header endRefreshing];
                device.ipAddress = host;
                [self.onlineDeviceArray updateOrAddDeviceModel:device];
                [self.deviceArray removeObject:device];
                [self.devieceTable reloadData];
            });
            break;
        }
    }
    [_socket disconnect];
}

- (BOOL)connectToHost:(NSString *)host onPort:(uint16_t)port error:(NSError *__autoreleasing *)errPtr{
    if (![_socket isDisconnected]) {
        NSLog(@"主动断开");
        [_socket disconnect];
    }
    return [_socket connectToHost:host onPort:port error:errPtr];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"断开连接");
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSLog(@"接收到消息%@",data);
    
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
    
}


#pragma mark - 获取网络信息
- (NSDictionary *)fetchNetInfo
{
    NSArray *interfaceNames = CFBridgingRelease(CNCopySupportedInterfaces());
    //    NSLog(@"%s: Supported interfaces: %@", __func__, interfaceNames);
    
    NSDictionary *SSIDInfo;
    for (NSString *interfaceName in interfaceNames) {
        SSIDInfo = CFBridgingRelease(
                                     CNCopyCurrentNetworkInfo((__bridge CFStringRef)interfaceName));
        //        NSLog(@"%s: %@ => %@", __func__, interfaceName, SSIDInfo);
        
        BOOL isNotEmpty = (SSIDInfo.count > 0);
        if (isNotEmpty) {
            break;
        }
    }
    return SSIDInfo;
}

- (void)showNoWifiConnect{
    YYBtn_AlertViewController *alert = [[YYBtn_AlertViewController alloc] init];
    alert.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    alert.rBlock = ^{
    };
    alert.lBlock = ^{
    };
    [self presentViewController:alert animated:NO completion:^{
        [self.rdv_tabBarController setTabBarHidden:YES animated:YES];
        alert.WScale_alert = WScale;
        alert.HScale_alert = HScale;
        [alert showView];
        alert.titleLabel.text = LocalString(@"提示");
        alert.messageLabel.text = LocalString(@"请连接Wi-Fi");
        [alert.leftBtn setTitle:LocalString(@"取消") forState:UIControlStateNormal];
        [alert.rightBtn setTitle:LocalString(@"确认") forState:UIControlStateNormal];
    }];
}

- (void)showWifiConnectError{
    NSDictionary *netInfo = [self fetchNetInfo];
    NSString *ssid = [netInfo objectForKey:@"SSID"];
    if (![[NetWork shareNetWork].ssid isEqualToString:@""] && ![ssid isEqualToString:[NetWork shareNetWork].ssid]) {
        YYBtn_AlertViewController *alert = [[YYBtn_AlertViewController alloc] init];
        alert.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        alert.rBlock = ^{
        };
        alert.lBlock = ^{
        };
        [self presentViewController:alert animated:NO completion:^{
            [self.rdv_tabBarController setTabBarHidden:YES animated:YES];
            alert.WScale_alert = WScale;
            alert.HScale_alert = HScale;
            [alert showView];
            alert.titleLabel.text = LocalString(@"提示");
            alert.messageLabel.text = LocalString(@"您未连接到配网的Wi-Fi,会导致搜索不到设备，请注意切换Wi-Fi");
            [alert.leftBtn setTitle:LocalString(@"取消") forState:UIControlStateNormal];
            [alert.rightBtn setTitle:LocalString(@"确认") forState:UIControlStateNormal];
        }];
    }
}

#pragma mark - uitableview
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
            return [NetWork shareNetWork].connectedDevice?1:0;
            
        case 1:
            return _onlineDeviceArray.count;
            //return 1;
            
        case 2:
            return _deviceArray.count;
            
        default:
            return 0;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return HEIGHT_CELL;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    DeviceTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier_device];
    if (cell == nil) {
        cell = [[DeviceTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier_device];
    }
    if (indexPath.section == 1) {
        //在线设备
        cell.backgroundColor = [UIColor clearColor];
        //cell.userInteractionEnabled = YES;
        DeviceModel *dModel = _onlineDeviceArray[indexPath.row];
        if (!dModel.deviceName || [dModel.deviceName isEqualToString:@""]) {
            cell.deviceName.text = dModel.sn;
        }else{
            cell.deviceName.text = dModel.deviceName;
        }
        cell.deviceImage.image = [UIImage imageNamed:[self getCorrespondPicByDeviceType:[dModel.deviceType integerValue]]];
        
        UILongPressGestureRecognizer *longPressGesture =[[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(deviceCellLongPress:)];
        
        longPressGesture.minimumPressDuration=1.f;//设置长按 时间
        [cell addGestureRecognizer:longPressGesture];
        
    }else if (indexPath.section == 0){
        //已经连接设备
        cell.backgroundColor = [UIColor clearColor];
        //cell.userInteractionEnabled = YES;

        NetWork *net = [NetWork shareNetWork];
        
        if (!net.connectedDevice.deviceName) {
            NSLog(@"%@",net.connectedDevice.sn);
            cell.deviceName.text = net.connectedDevice.sn;
        }else{
            NSLog(@"%@",net.connectedDevice.deviceName);
            cell.deviceName.text = net.connectedDevice.deviceName;
        }
        cell.deviceImage.image = [UIImage imageNamed:[self getCorrespondPicByDeviceType:[net.connectedDevice.deviceType integerValue]]];
        
        UILongPressGestureRecognizer *longPressGesture =[[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(connectedDeviceCellLongPress:)];
        
        longPressGesture.minimumPressDuration=1.f;//设置长按 时间
        [cell addGestureRecognizer:longPressGesture];

        
    }else{
        //离线设备
        cell.backgroundColor = [UIColor colorWithRed:247/255.0 green:247/255.0 blue:247/255.0 alpha:1];
        //cell.userInteractionEnabled = YES;
        DeviceModel *device = _deviceArray[indexPath.row];
        cell.deviceName.text = device.deviceName;
        cell.deviceImage.image = [UIImage imageNamed:[self getCorrespondPicByDeviceType:[device.deviceType integerValue]]];
        
        UILongPressGestureRecognizer *longPressGesture =[[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(deviceCellLongPress:)];
        
        longPressGesture.minimumPressDuration=1.f;//设置长按 时间
        [cell addGestureRecognizer:longPressGesture];

    }
    //添加长按手势

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NetWork *net = [NetWork shareNetWork];
    if (indexPath.section == 1) {
        if (!net.connectedDevice) {
            NSError *error = nil;
            DeviceModel *dModel = _onlineDeviceArray[indexPath.row];
            [net connectToHost:dModel.ipAddress onPort:16888 error:&error];
            
            if (error) {
                NSLog(@"tcp连接错误:%@",error);
            }else{
                [net setConnectedDevice:dModel];
                [self.navigationController popViewControllerAnimated:YES];
            }
        }else{
            YYBtn_AlertViewController *alert = [[YYBtn_AlertViewController alloc] init];
            alert.lBlock = ^{
                
            };
            alert.rBlock = ^{
                NSError *error = nil;
                DeviceModel *dModel = self.onlineDeviceArray[indexPath.row];
                [net connectToHost:dModel.ipAddress onPort:16888 error:&error];
                
                if (error) {
                    NSLog(@"tcp连接错误:%@",error);
                }else{
                    [net setConnectedDevice:dModel];
                    [self.navigationController popViewControllerAnimated:YES];
                }
            };
            alert.modalPresentationStyle = UIModalPresentationOverCurrentContext;
            [self presentViewController:alert animated:NO completion:^{
                alert.WScale_alert = WScale;
                alert.HScale_alert = HScale;
                [alert showView];
                alert.titleLabel.text = LocalString(@"提示");
                alert.messageLabel.text = LocalString(@"当前已经连接一个设备,确认切换设备吗？");
                [alert.leftBtn setTitle:LocalString(@"取消") forState:UIControlStateNormal];
                [alert.rightBtn setTitle:LocalString(@"确认") forState:UIControlStateNormal];
            }];

        }
        
    }else if (indexPath.section == 0){
        /*
         *改成返回主页面
         */
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, ScreenWidth, HEIGHT_HEADER)];
    UILabel *headerTitle = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 200, HEIGHT_HEADER)];
    headerTitle.font = [UIFont systemFontOfSize:14.f];
    if (section == 0) {
        headerTitle.text = LocalString(@"已连接设备");
    }else if (section == 1){
        headerTitle.text = LocalString(@"在线设备");
    }else{
        headerTitle.text = LocalString(@"离线设备");
    }
    [headerView addSubview:headerTitle];
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return HEIGHT_HEADER;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0) {
        return NO;
    }
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleDelete;
}

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return LocalString(@"删除");
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //获取设备
        DeviceModel *device;
        if (indexPath.section == 1) {
            device = _onlineDeviceArray[indexPath.row];
        }else if (indexPath.section == 2){
            device = _deviceArray[indexPath.row];
        }
        
        //http delete
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
        //设置超时时间
        [manager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
        manager.requestSerializer.timeoutInterval = 6.f;
        [manager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
        
        [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@",[DataBase shareDataBase].token] forHTTPHeaderField:@"Authorization"];
        [manager.requestSerializer setValue:[DataBase shareDataBase].userId forHTTPHeaderField:@"userId"];
        
        NSDictionary *parameters = @{@"sn":device.sn,@"userId":[DataBase shareDataBase].userId};

        manager.requestSerializer.HTTPMethodsEncodingParametersInURI = [NSSet setWithObjects:@"GET", @"HEAD", nil];

        [manager DELETE:@"http://139.196.90.97:8080/coffee/roaster" parameters:parameters headers:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            
            NSData * data = [NSJSONSerialization dataWithJSONObject:responseObject options:(NSJSONWritingOptions)0 error:nil];
            NSString * daetr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
            NSLog(@"success:%@",daetr);

            if ([[responseObject objectForKey:@"errno"] intValue] == 0) {
                
                //本地数据库delete
                [[DataBase shareDataBase].queueDB inDatabase:^(FMDatabase * _Nonnull db) {
                    BOOL result = [db executeUpdate:@"delete from device where sn = ?",device.sn];
                    if (result) {
                        [NSObject showHudTipStr:LocalString(@"删除设备成功")];
                    }else{
                        [NSObject showHudTipStr:LocalString(@"删除设备失败")];
                    }
                }];
                
                if (indexPath.section == 1) {
                    [_onlineDeviceArray removeObject:device];
                }else if (indexPath.section == 2){
                    [_deviceArray removeObject:device];
                }
                [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [tableView endEditing:YES];
                
            }else{
                [NSObject showHudTipStr:LocalString(@"删除设备失败")];
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if (error.code == -1001) {
                [NSObject showHudTipStr:LocalString(@"当前网络状况不佳")];
            }else{
                [NSObject showHudTipStr:LocalString(@"删除设备失败")];
            }
            NSLog(@"Error:%@",error);
        }];

    }
}

#pragma mark - view action
- (void)goEsp{
    
    NetWork *net = [NetWork shareNetWork];
    //如果当前有设备连接，先断开 再去配网
    if (net.connectedDevice) {
        
        YYBtn_AlertViewController *alert = [[YYBtn_AlertViewController alloc] init];
        alert.lBlock = ^{
            
        };
        alert.rBlock = ^{
            if (!net.mySocket.isDisconnected) {
                [net.mySocket disconnect];
                [net setConnectedDevice:nil];
                
                [self.udpSocket close];
                self.udpSocket = nil;
                [self.lock unlock];
                [self queryDevices];
                
            }else{
                [net setConnectedDevice:nil];
                [self.devieceTable reloadData];
            }
            //断开网路连接之后 去配网
            EspViewController *EspVC = [[EspViewController alloc] init];
            NSDictionary *netInfo = [self fetchNetInfo];
            EspVC.ssid = [netInfo objectForKey:@"SSID"];
            EspVC.bssid = [netInfo objectForKey:@"BSSID"];
            NSLog(@"%@",[netInfo objectForKey:@"SSID"]);
            EspVC.block = ^(ESPTouchResult *result) {
                
            };
            [self.navigationController pushViewController:EspVC animated:YES];
            
        };
        alert.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [self presentViewController:alert animated:NO completion:^{
            alert.WScale_alert = WScale;
            alert.HScale_alert = HScale;
            [alert showView];
            alert.titleLabel.text = LocalString(@"提示");
            alert.messageLabel.text = LocalString(@"确认断开设备连接吗？");
            [alert.leftBtn setTitle:LocalString(@"取消") forState:UIControlStateNormal];
            [alert.rightBtn setTitle:LocalString(@"确认") forState:UIControlStateNormal];
        }];
        
    }else{
        
        if (!net.mySocket.isDisconnected) {
            [net.mySocket disconnect];
            [net setConnectedDevice:nil];
            
            [self.udpSocket close];
            self.udpSocket = nil;
            [self.lock unlock];
            [self queryDevices];
            
        }else{
            [net setConnectedDevice:nil];
            [self.devieceTable reloadData];
        }
        //断开网路连接之后 去配网
        EspViewController *EspVC = [[EspViewController alloc] init];
        NSDictionary *netInfo = [self fetchNetInfo];
        EspVC.ssid = [netInfo objectForKey:@"SSID"];
        EspVC.bssid = [netInfo objectForKey:@"BSSID"];
        NSLog(@"%@",[netInfo objectForKey:@"SSID"]);
        EspVC.block = ^(ESPTouchResult *result) {
            
        };
        [self.navigationController pushViewController:EspVC animated:YES];
    }
    
}

- (NSString *)getCorrespondPicByDeviceType:(HBCoffeeDeviceType)deviceType{
    switch (deviceType) {
        case Coffee_HB_M6G:
        {
            return @"img_hb_m6g_small";
        }
            break;
            
        case Coffee_HB_L2:
        {
            return @"img_hb_l2_small";
        }
            break;
        case Coffee_PEAK_Edmund:
        {
            return @"img_peak_edmund_small";
        }
            break;
            
        case Coffee_HB_M6E:
        {
            return @"img_hb_m6g_small";
        }
            break;
        case Coffee_HB_Another:
        {
            return @"img_logo_gray";
        }
            break;
            
        default:
            break;
    }
}

- (void)deviceCellLongPress:(UILongPressGestureRecognizer *)longRecognizer{
    if (longRecognizer.state==UIGestureRecognizerStateBegan) {
        //成为第一响应者，需重写该方法
        [self becomeFirstResponder];
        
        //获取此时长按的Cell位置
        CGPoint location = [longRecognizer locationInView:self.devieceTable];
        NSIndexPath *indexPath = [self.devieceTable indexPathForRowAtPoint:location];
        DeviceModel *device;
        switch (indexPath.section) {
            case 0:
            {
                device = [NetWork shareNetWork].connectedDevice;
            }
                break;
                
            case 1:
            {
                device = _onlineDeviceArray[indexPath.row];
            }
                break;
                
            case 2:
            {
                device = _deviceArray[indexPath.row];
            }
                break;
                
            default:
                break;
        }
        AA_TFAlertController *alert = [[AA_TFAlertController alloc] init];
        alert.lBlock = ^{
        };
        alert.rBlock = ^(NSString * _Nullable text) {
            device.deviceName = text;
            [self modifyDeviceNameByApi:device];
        };
        alert.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [self presentViewController:alert animated:NO completion:^{
            alert.titleLabel.text = LocalString(@"更改设备名称");
            alert.textField.text = device.deviceName;
            [alert.leftBtn setTitle:LocalString(@"取消") forState:UIControlStateNormal];
            [alert.rightBtn setTitle:LocalString(@"确认") forState:UIControlStateNormal];
        }];

    }
}

- (void)connectedDeviceCellLongPress:(UILongPressGestureRecognizer *)longRecognizer{
    if (longRecognizer.state==UIGestureRecognizerStateBegan) {
        //成为第一响应者，需重写该方法
        [self becomeFirstResponder];
        NetWork *net = [NetWork shareNetWork];
        YYBtn_AlertViewController *alert = [[YYBtn_AlertViewController alloc] init];
        alert.lBlock = ^{
            
        };
        alert.rBlock = ^{
            if (!net.mySocket.isDisconnected) {
                [net.mySocket disconnect];
                [net setConnectedDevice:nil];
                
                [_udpSocket close];
                _udpSocket = nil;
                [_lock unlock];
                [self queryDevices];
            }else{
                [net setConnectedDevice:nil];
                [_devieceTable reloadData];
            }
        };
        alert.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        [self presentViewController:alert animated:NO completion:^{
            alert.WScale_alert = WScale;
            alert.HScale_alert = HScale;
            [alert showView];
            alert.titleLabel.text = LocalString(@"提示");
            alert.messageLabel.text = LocalString(@"确认断开设备连接吗？");
            [alert.leftBtn setTitle:LocalString(@"取消") forState:UIControlStateNormal];
            [alert.rightBtn setTitle:LocalString(@"确认") forState:UIControlStateNormal];
        }];
    }
}

- (void)modifyDeviceNameByApi:(DeviceModel *)device{
    [SVProgressHUD show];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    //设置超时时间
    [manager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
    manager.requestSerializer.timeoutInterval = 6.f;
    [manager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
    
    NSString *url = [NSString stringWithFormat:@"http://139.196.90.97:8080/coffee/roaster"];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"`#%^{}\"[]|\\<> "].invertedSet];
    
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [manager.requestSerializer setValue:[DataBase shareDataBase].userId forHTTPHeaderField:@"userId"];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"bearer %@",[DataBase shareDataBase].token] forHTTPHeaderField:@"Authorization"];
    
    NSDictionary *parameters = @{@"sn":device.sn,@"name":device.deviceName,@"userId":[DataBase shareDataBase].userId};
    
    [manager PUT:url parameters:parameters headers:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSData * data = [NSJSONSerialization dataWithJSONObject:responseObject options:(NSJSONWritingOptions)0 error:nil];
        NSString * daetr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"success:%@",daetr);
        if ([[responseObject objectForKey:@"errno"] integerValue] == 0) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                [NSObject showHudTipStr:@"修改设备名称成功"];
                [self queryDevicesByApi:^{
                    
                } fail:^{
                    
                }];
            });
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD dismiss];
                [NSObject showHudTipStr:@"修改设备名称失败"];
            });
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Error:%@",error);
        if (error.code == -1001) {
            [NSObject showHudTipStr:LocalString(@"当前网络状况不佳")];
        }else{
            [NSObject showHudTipStr:@"修改设备名称失败"];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });

    }];
}

- (void)mysocketDidDisconnect{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.devieceTable reloadData];
    });
}

#pragma mark - Data Source
- (void)queryDevicesByApi:(SuccessBlock)success fail:(FailureBlock)failure{
    [SVProgressHUD show];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    //设置超时时间
    [manager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
    manager.requestSerializer.timeoutInterval = 6.f;
    [manager.requestSerializer didChangeValueForKey:@"timeoutInterval"];

    NSString *url = [NSString stringWithFormat:@"http://139.196.90.97:8080/coffee/roaster?userId=%@",[DataBase shareDataBase].userId];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"`#%^{}\"[]|\\<> "].invertedSet];
    
    NSLog(@"%@",[DataBase shareDataBase].userId);
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [manager.requestSerializer setValue:[DataBase shareDataBase].userId forHTTPHeaderField:@"userId"];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"bearer %@",[DataBase shareDataBase].token] forHTTPHeaderField:@"Authorization"];
    [manager GET:url parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSData * data = [NSJSONSerialization dataWithJSONObject:responseObject options:(NSJSONWritingOptions)0 error:nil];
        NSString * daetr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"success:%@",daetr);
        [responseObject[@"data"] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            DeviceModel *device = [[DeviceModel alloc] init];
            device.sn = [obj objectForKey:@"sn"];
            device.deviceName = [obj objectForKey:@"name"];
            device.deviceType = [obj objectForKey:@"deviceType"];
            
            if (!device.deviceType) {
                device.deviceType = @0;
            }
            BOOL isStored = [[DataBase shareDataBase] queryDevice:device.sn];
            if (!isStored) {
                [[DataBase shareDataBase].queueDB inDatabase:^(FMDatabase * _Nonnull db) {
                    BOOL result = [db executeUpdate:@"INSERT INTO device (sn,deviceName,deviceType) VALUES (?,?,?)",device.sn,device.deviceName,device.deviceType];
                    if (result) {
                        NSLog(@"插入服务器device成功");
                    }else{
                        NSLog(@"插入服务器device失败");
                    }
                }];
            }else{
                [[DataBase shareDataBase].queueDB inDatabase:^(FMDatabase * _Nonnull db) {
                    [db executeUpdate:@"UPDATE device SET deviceName = ?,deviceType = ? WHERE sn = ?",device.deviceName,device.deviceType,device.sn];
                }];
            }
        }];
        
        self.deviceArray = [[DataBase shareDataBase] queryAllDevice];
        if (!self.deviceArray.count && !self.onlineDeviceArray.count && ![NetWork shareNetWork].connectedDevice) {
            self.devieceTable.hidden = YES;
            self.noDeviceView.hidden = NO;
        }else{
            self.devieceTable.hidden = NO;
            self.noDeviceView.hidden = YES;
            for (DeviceModel *onlineDevice in self.onlineDeviceArray) {
                for (DeviceModel *device in self.deviceArray) {
                    if ([onlineDevice.sn isEqualToString:device.sn]) {
                        //去除掉在线列表存在的设备
                        [self.deviceArray removeObject:device];
                        break;
                    }
                }
            }
            for (DeviceModel *device in self.deviceArray) {
                //去掉当前连接的设备
                if ([device.sn isEqualToString:[NetWork shareNetWork].connectedDevice.sn]) {
                    [_deviceArray removeObject:device];
                    break;
                }
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
            [self.devieceTable reloadData];
            [self sendSearchBroadcast];
            [self findDeviceByTCP];
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if(failure){
            failure();
        }
        NSLog(@"Error:%@",error);
        if (error.code == -1001) {
            [NSObject showHudTipStr:LocalString(@"当前网络状况不佳")];
        }else{
            [NSObject showHudTipStr:@"从服务器获取咖啡机信息失败"];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
    }];
}

- (void)refreshDevices{
    if (!_timer) {
        _timer = [self timer];
    }
    if (self.devieceTable) {
        [self queryDevices];
    }
    
    [self showWifiConnectError];
    
    [_lock unlock];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mysocketDidDisconnect) name:@"mysocketDidDisconnect" object:nil];
}

- (void)queryDevices{
    _deviceArray = [[DataBase shareDataBase] queryAllDevice];
    if (_deviceArray.count == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self queryDevicesByApi:^{
                
            } fail:^{
                
            }];
        });
    }else{
        [_onlineDeviceArray removeAllObjects];
        [self queryDevicesByApi:^{
            
        } fail:^{
            //开启广播udp
            [self sendSearchBroadcast];
            self.devieceTable.hidden = NO;
            self.noDeviceView.hidden = YES;
            if ([NetWork shareNetWork].connectedDevice) {
                for (DeviceModel *device in self.deviceArray) {
                    if ([device.sn isEqualToString:[NetWork shareNetWork].connectedDevice.sn]) {
                        [self.deviceArray removeObject:device];
                        break;
                    }
                }
            }
            [self findDeviceByTCP];
        }];
    }
}

- (void)findDeviceByTCP{
    for (DeviceModel *device in _deviceArray) {
        [self getRouteInfoWithSn:device.sn success:^(NSDictionary *dic) {
            NSDictionary *netInfo = [self fetchNetInfo];
            NSString *ssid = [netInfo objectForKey:@"SSID"];
            NSString *ip = [dic objectForKey:@"ip"];
            if([ssid isEqualToString:[dic objectForKey:@"routingName"]]) {
                [ipAndSnDic setObject:device.sn forKey:ip];
                NSError *error = nil;
                [_socket connectToHost:ip onPort:16888 error:&error];
            }
        }];
    }
}

#pragma mark - 路由API
//- (void)setRouteInfoWithSn:(NSString *)sn ip:(NSString *)ip{
//    NSDictionary *netInfo = [self fetchNetInfo];
//    NSString *ssid = [netInfo objectForKey:@"SSID"];
//
//    [SVProgressHUD show];
//    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
//
//    //设置超时时间
//    [manager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
//    manager.requestSerializer.timeoutInterval = 6.f;
//    [manager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
//
//    NSString *url = [NSString stringWithFormat:@"http://139.196.90.97:8080/coffee/setting/routing?sn=%@&routingName=%@&ip=%@",sn,ssid,ip];
//    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"`#%^{}\"[]|\\<> "].invertedSet];
//
//    NSLog(@"%@",[DataBase shareDataBase].userId);
//    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
//    [manager.requestSerializer setValue:[DataBase shareDataBase].userId forHTTPHeaderField:@"userId"];
//    [manager.requestSerializer setValue:[NSString stringWithFormat:@"bearer %@",[DataBase shareDataBase].token] forHTTPHeaderField:@"Authorization"];
//    [manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        
//        NSData * data = [NSJSONSerialization dataWithJSONObject:responseObject options:(NSJSONWritingOptions)0 error:nil];
//        NSString * daetr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
//        NSLog(@"success:%@",daetr);
//        if([[responseObject objectForKey:@"errno"] intValue] == 0) {
//            [NSObject showHudTipStr:LocalString(@"绑定路由成功")];
//        }
//        [SVProgressHUD dismiss];
//    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//        NSLog(@"Error:%@",error);
//        if (error.code == -1001) {
//            [NSObject showHudTipStr:LocalString(@"当前网络状况不佳")];
//        }
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [SVProgressHUD dismiss];
//        });
//    }];
//
//}

- (void)getRouteInfoWithSn:(NSString *)sn  success:(void(^)(NSDictionary *dic))success{
    [SVProgressHUD show];
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    //设置超时时间
    [manager.requestSerializer willChangeValueForKey:@"timeoutInterval"];
    manager.requestSerializer.timeoutInterval = 6.f;
    [manager.requestSerializer didChangeValueForKey:@"timeoutInterval"];
    
    NSString *url = [NSString stringWithFormat:@"http://139.196.90.97:8080/coffee/setting/routing/msg?sn=%@",sn];
    url = [url stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"`#%^{}\"[]|\\<> "].invertedSet];
    
    NSLog(@"%@",[DataBase shareDataBase].userId);
    [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [manager.requestSerializer setValue:[DataBase shareDataBase].userId forHTTPHeaderField:@"userId"];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"bearer %@",[DataBase shareDataBase].token] forHTTPHeaderField:@"Authorization"];
    [manager GET:url parameters:nil headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSData * data = [NSJSONSerialization dataWithJSONObject:responseObject options:(NSJSONWritingOptions)0 error:nil];
        NSString * daetr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"success:%@",daetr);
        if([[responseObject objectForKey:@"errno"] intValue] == 0) {
            NSDictionary *dic = [responseObject objectForKey:@"data"];
            //NSString *routingName = [dic objectForKey:@"routingName"];
            //NSString *ip = [dic objectForKey:@"ip"];
            if(success){
                success(dic);
            }
        }
        [SVProgressHUD dismiss];
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"Error:%@",error);
        if (error.code == -1001) {
            [NSObject showHudTipStr:LocalString(@"当前网络状况不佳")];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
    }];
    
}
@end
