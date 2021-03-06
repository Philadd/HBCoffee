//
//  ReportCurveCell.m
//  Coffee
//
//  Created by 杭州轨物科技有限公司 on 2018/8/18.
//  Copyright © 2018年 杭州轨物科技有限公司. All rights reserved.
//

#import "ReportCurveCell.h"
#import "Coffee-Swift.h"


@implementation ReportCurveCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    if (self) {
        if (!_chartView) {
            _chartView = [[LineChartView alloc] init];
            _chartView.frame = CGRectMake(16/WScale, 10/HScale, ScreenWidth - 32/WScale, 192.f/HScale);
            [self.contentView addSubview:_chartView];
            
            _chartView.noDataText = LocalString(@"暂无数据");
            _chartView.delegate = self;
            
            _chartView.chartDescription.enabled = NO;
            
            _chartView.dragEnabled = YES;
            [_chartView setScaleEnabled:YES];//缩放
            //[_chartView setScaleYEnabled:NO];
            
            
            _chartView.drawGridBackgroundEnabled = NO;//网格线
            _chartView.pinchZoomEnabled = YES;
            //_chartView.doubleTapToZoomEnabled = NO;//取消双击缩放
            //_chartView.dragDecelerationEnabled = NO;//拖拽后是否有惯性效果
            //_chartView.dragDecelerationFrictionCoef = 0;//拖拽后惯性效果的摩擦系数(0~1)，数值越小，惯性越不明显
            
            _chartView.backgroundColor = [UIColor clearColor];
            
            
            _chartView.legend.enabled = NO;//不显示图例说明
            ChartLegend *l = _chartView.legend;
            l.form = ChartLegendFormLine;
            l.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:11.f];
            l.textColor = UIColor.whiteColor;
            l.horizontalAlignment = ChartLegendHorizontalAlignmentLeft;
            l.verticalAlignment = ChartLegendVerticalAlignmentBottom;
            l.orientation = ChartLegendOrientationHorizontal;
            l.drawInside = YES;//legend显示在图表里
            
            ChartXAxis *xAxis = _chartView.xAxis;
            xAxis.labelFont = [UIFont fontWithName:@"Avenir-Light" size:12];
            xAxis.labelTextColor = [UIColor colorWithRed:184/255.0 green:190/255.0 blue:204/255.0 alpha:1];
            xAxis.drawGridLinesEnabled = NO;
            xAxis.drawAxisLineEnabled = NO;
            xAxis.labelPosition = XAxisLabelPositionBottom;
            xAxis.valueFormatter = self;
            xAxis.axisRange = self.yVals_Bean.count;
            xAxis.granularity = 60;
            xAxis.axisMinimum = 0;
            
            ChartYAxis *leftAxis = _chartView.leftAxis;
            leftAxis.labelTextColor = [UIColor colorWithRed:184/255.0 green:190/255.0 blue:204/255.0 alpha:1];
            leftAxis.labelFont = [UIFont fontWithName:@"Avenir-Light" size:12];
            leftAxis.axisMaximum = [NSString diffTempUnitStringWithTemp:150.f];
            //leftAxisMax = 140 - 0.5;
            leftAxis.axisMinimum = [NSString diffTempUnitStringWithTemp:0.f];
            leftAxis.spaceTop = 30.f;
            leftAxis.drawGridLinesEnabled = YES;
            leftAxis.gridLineWidth = 0.6f;
            leftAxis.gridColor = [UIColor colorWithHexString:@"EBEDF0"];
            //leftAxis.gridLineDashLengths = @[@5.f,@5.f];//虚线
            leftAxis.drawZeroLineEnabled = NO;
            leftAxis.granularityEnabled = YES;
            leftAxis.granularity = 50.f;
            [self setLeftAxisMaxmium];
            
            ChartYAxis *rightAxis = _chartView.rightAxis;
            rightAxis.labelFont = [UIFont fontWithName:@"Avenir-Light" size:12];
            rightAxis.labelTextColor = [UIColor colorWithRed:184/255.0 green:190/255.0 blue:204/255.0 alpha:1];
            rightAxis.axisMaximum = [NSString diffTempUnitStringWithTemp:30.f];
            rightAxis.axisMinimum = 0;
            rightAxis.drawGridLinesEnabled = NO;
            rightAxis.granularityEnabled = NO;
            
            [_chartView animateWithXAxisDuration:1.0];
            
            // 显示气泡效果
            BalloonMarker *marker = [[BalloonMarker alloc]
                                     initWithColor: [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:0.75]
                                     font: [UIFont systemFontOfSize:15.0]
                                     textColor: [UIColor colorWithHexString:@"333333"]
                                     insets: UIEdgeInsetsMake(8.0, 8.0, 20.0, 8.0)
                                     borderColor:[UIColor colorWithRed:213/255.0 green:218/255.0 blue:224/255.0 alpha:0.5]];
            marker.minimumSize = CGSizeMake(0, 0);
            marker.chartView = self.chartView;
            self.chartView.marker = marker;
            [self.chartView setDrawMarkers:YES];
            [_chartView animateWithXAxisDuration:1.0];

        }
    }
    return self;
}

- (void)setLeftAxisMaxmium{
    for (int i = 0; i < _yVals_In.count; i++) {
        ChartDataEntry *entry = _yVals_In[i];
        if (entry.y > self.chartView.leftAxis.axisMaximum) {
            self.chartView.leftAxis.axisMaximum += [NSString diffTempUnitStringWithTemp:50.f];
        }
    }
    for (int i = 0; i < _yVals_Bean.count; i++) {
        ChartDataEntry *entry = _yVals_Bean[i];
        if (entry.y > self.chartView.leftAxis.axisMaximum) {
            self.chartView.leftAxis.axisMaximum += [NSString diffTempUnitStringWithTemp:50.f];
        }
    }
    for (int i = 0; i < _yVals_Out.count; i++) {
        ChartDataEntry *entry = _yVals_Out[i];
        if (entry.y > self.chartView.leftAxis.axisMaximum) {
            self.chartView.leftAxis.axisMaximum += [NSString diffTempUnitStringWithTemp:50.f];
        }
    }
    for (int i = 0; i < _yVals_Environment.count; i++) {
        ChartDataEntry *entry = _yVals_Environment[i];
        if (entry.y > self.chartView.leftAxis.axisMaximum) {
            self.chartView.leftAxis.axisMaximum += [NSString diffTempUnitStringWithTemp:50.f];
        }
    }
    if (self.chartView.leftAxis.axisMaximum > [NSString diffTempUnitStringWithTemp:400.f]) {
        self.chartView.leftAxis.axisMaximum = [NSString diffTempUnitStringWithTemp:400.f];
    }
}

- (void)setDataValue
{
    [self setLeftAxisMaxmium];
    if (self.yVals_Bean.count > (60 * 3)) {
        if ((self.yVals_Bean.count / 60) % 2) {
            //判断分钟数此时是单数还是双数
            self.chartView.xAxis.axisMaximum = (self.yVals_Bean.count/60+1)*60;
        }else{
            self.chartView.xAxis.axisMaximum = (self.yVals_Bean.count/60+2)*60;
        }
        self.chartView.xAxis.labelCount = self.chartView.xAxis.axisMaximum / 60 / 2;
    }else{
        self.chartView.xAxis.axisMaximum = 60 * 3;
    }

    
    LineChartDataSet *set1 = nil, *set2 = nil, *set3 = nil, *set4 = nil, *set5 = nil;
    
    if (_chartView.data.dataSetCount > 0)
    {
        set1 = (LineChartDataSet *)_chartView.data.dataSets[0];
        set1.values = _yVals_Out;

        set2 = (LineChartDataSet *)_chartView.data.dataSets[1];
        set2.values = _yVals_In;

        set3 = (LineChartDataSet *)_chartView.data.dataSets[2];
        set3.values = _yVals_Bean;

        set4 = (LineChartDataSet *)_chartView.data.dataSets[3];
        set4.values = _yVals_Environment;
        
        set5 = (LineChartDataSet *)_chartView.data.dataSets[4];
        set5.values = _yVals_Diff;
        
        
        
//        if (_yVals_Out.count > 150) {
//            _chartView.xAxis.axisRange = 15;
//            [_chartView setVisibleXRangeWithMinXRange:0.5 maxXRange:UI_IS_IPHONE5?4:5];
//        }
        
        [_chartView.data notifyDataChanged];
        [_chartView notifyDataSetChanged];
    }
    else
    {
        set1 = [[LineChartDataSet alloc] initWithValues:_yVals_In label:LocalString(@"热风温")];
        set1.axisDependency = AxisDependencyLeft;
        [set1 setColor:[UIColor colorWithRed:123/255.0 green:179/255.0 blue:64/255.0 alpha:1]];
        [set1 setCircleColor:UIColor.whiteColor];
        set1.lineWidth = 1.5;
        set1.circleRadius = 0.0;
        set1.fillAlpha = 65/255.0;
        set1.fillColor = [UIColor colorWithRed:123/255.0 green:179/255.0 blue:64/255.0 alpha:1];
        //set1.highlightColor = [UIColor colorWithRed:244/255.f green:117/255.f blue:117/255.f alpha:1.f];
        set1.drawCircleHoleEnabled = NO;
        set1.drawValuesEnabled = NO;//是否在拐点处显示数据
        //set1.cubicIntensity = 5;//曲线弧度
        set1.highlightEnabled = NO;//选中拐点,是否开启高亮效果(显示十字线)
        //set1.mode = LineChartModeCubicBezier;
        
        set2 = [[LineChartDataSet alloc] initWithValues:_yVals_Out label:LocalString(@"排气温")];
        set2.axisDependency = AxisDependencyLeft;
        [set2 setColor:[UIColor colorWithRed:80/255.0 green:227/255.0 blue:194/255.0 alpha:1]];
        [set2 setCircleColor:UIColor.whiteColor];
        set2.lineWidth = 1.5;
        set2.circleRadius = 0.0;
        set2.fillAlpha = 65/255.0;
        set2.fillColor = [UIColor colorWithRed:80/255.0 green:227/255.0 blue:194/255.0 alpha:1];
        set2.drawCircleHoleEnabled = NO;
        set2.drawValuesEnabled = NO;//是否在拐点处显示数据
        //set1.cubicIntensity = 1;//曲线弧度
        set2.highlightEnabled = NO;//选中拐点,是否开启高亮效果(显示十字线)
        
        set3 = [[LineChartDataSet alloc] initWithValues:_yVals_Bean label:LocalString(@"豆温")];
        set3.axisDependency = AxisDependencyLeft;
        [set3 setColor:[UIColor colorWithRed:71/255.0 green:120/255.0 blue:204/255.0 alpha:1]];
        [set3 setCircleColor:[UIColor colorWithRed:71/255.0 green:120/255.0 blue:204/255.0 alpha:1]];
        [set3 setCircleHoleColor:[UIColor whiteColor]];
        set3.lineWidth = 1.5;
        set3.circleRadius = 4.0;
        set3.circleHoleRadius = 3.0;
        set3.highlightLineWidth = 0.0;
        set3.fillAlpha = 65/255.0;
        set3.fillColor = [UIColor colorWithRed:71/255.0 green:120/255.0 blue:204/255.0 alpha:1];
        set3.drawCircleHoleEnabled = YES;
        set3.drawValuesEnabled = NO;//是否在拐点处显示数据
        //set1.cubicIntensity = 1;//曲线弧度
        set3.highlightEnabled = YES;//选中拐点,是否开启高亮效果(显示十字线)

        set4 = [[LineChartDataSet alloc] initWithValues:_yVals_Environment label:LocalString(@"环境温")];
        set4.axisDependency = AxisDependencyLeft;
        [set4 setColor:[UIColor colorWithRed:245/255.0 green:166/255.0 blue:35/255.0 alpha:1]];
        [set4 setCircleColor:UIColor.whiteColor];
        set4.lineWidth = 1.5;
        set4.circleRadius = 0.0;
        set4.fillAlpha = 65/255.0;
        set4.fillColor = [UIColor colorWithRed:245/255.0 green:166/255.0 blue:35/255.0 alpha:1];
        set4.drawCircleHoleEnabled = NO;
        set4.drawValuesEnabled = NO;//是否在拐点处显示数据
        //set1.cubicIntensity = 1;//曲线弧度
        set4.highlightEnabled = NO;//选中拐点,是否开启高亮效果(显示十字线)
        
        set5 = [[LineChartDataSet alloc] initWithValues:_yVals_Diff label:LocalString(@"升温率")];
        set5.axisDependency = AxisDependencyRight;
        [set5 setColor:[UIColor colorWithRed:255/255.0 green:71/255.0 blue:51/255.0 alpha:1]];
        [set5 setCircleColor:UIColor.whiteColor];
        set5.lineWidth = 1.5;
        set5.circleRadius = 0.0;
        set5.fillAlpha = 65/255.0;
        set5.fillColor = [UIColor colorWithRed:255/255.0 green:71/255.0 blue:51/255.0 alpha:1];
        set5.drawCircleHoleEnabled = NO;
        set5.drawValuesEnabled = NO;//是否在拐点处显示数据
        set5.highlightEnabled = NO;//选中拐点,是否开启高亮效果(显示十字线)
        
        NSMutableArray *dataSets = [[NSMutableArray alloc] init];
        [dataSets addObject:set1];
        [dataSets addObject:set2];
        [dataSets addObject:set3];
        [dataSets addObject:set4];
        [dataSets addObject:set5];
        
        LineChartData *data = [[LineChartData alloc] initWithDataSets:dataSets];
        [data setValueTextColor:UIColor.whiteColor];
        [data setValueFont:[UIFont systemFontOfSize:9.f]];
        
//        _chartView.xAxis.axisRange = 15;
//        [_chartView setVisibleXRangeWithMinXRange:0.5 maxXRange:UI_IS_IPHONE5?4:5];
        
        //_chartView.xAxis.labelCount = 5;
        _chartView.data = data;
    }
}

- (NSString *)stringForValue:(double)value axis:(ChartAxisBase *)axis{
    return [NSString stringWithFormat:@"%d",(int)value/60];
}
@end
