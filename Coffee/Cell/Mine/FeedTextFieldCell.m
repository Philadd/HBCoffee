//
//  FeedTextFieldCell.m
//  Coffee
//
//  Created by 杭州轨物科技有限公司 on 2018/10/12.
//  Copyright © 2018年 杭州轨物科技有限公司. All rights reserved.
//

#import "FeedTextFieldCell.h"

@implementation FeedTextFieldCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        if (!self.nameLabel) {
            _nameLabel = [[UILabel alloc] init];
            _nameLabel.font = [UIFont systemFontOfSize:15.f];
            _nameLabel.backgroundColor = [UIColor clearColor];
            _nameLabel.textColor = [UIColor colorWithHexString:@"222222"];
            _nameLabel.textAlignment = NSTextAlignmentLeft;
            [self.contentView addSubview:_nameLabel];
            
            [_nameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.size.mas_equalTo(CGSizeMake(100/WScale, 21/HScale));
                make.centerY.equalTo(self.contentView.mas_centerY);
                make.left.equalTo(self.contentView.mas_left).offset(15/WScale);
            }];
        }
        if (!_contentTF) {
            _contentTF = [[UITextField alloc] init];
            _contentTF.backgroundColor = [UIColor clearColor];
            _contentTF.font = [UIFont fontWithName:@"Arial" size:15.0f];
            _contentTF.textColor = [UIColor colorWithHexString:@"666666"];
            _contentTF.autocorrectionType = UITextAutocorrectionTypeNo;
            _contentTF.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
            //设置为YES时文本会自动缩小以适应文本窗口大小.默认是保持原来大小,而让长文本滚动
            _contentTF.adjustsFontSizeToFitWidth = YES;
            //设置自动缩小显示的最小字体大小
            _contentTF.minimumFontSize = 11.f;
            [_contentTF addTarget:self action:@selector(textFieldTextChange:) forControlEvents:UIControlEventEditingChanged];
            [self.contentView addSubview:_contentTF];
            
            [_contentTF mas_makeConstraints:^(MASConstraintMaker *make) {
                make.size.mas_equalTo(CGSizeMake(200/WScale, 30/HScale));
                make.centerY.equalTo(self.contentView.mas_centerY);
                make.left.equalTo(self.nameLabel.mas_right).offset(15/WScale);
            }];
        }
    }
    return self;
}

-(void)textFieldTextChange:(UITextField *)textField{
    if (self.TFBlock) {
        self.TFBlock(textField.text);
    }
}

@end
