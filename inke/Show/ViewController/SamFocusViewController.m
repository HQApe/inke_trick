//
//  SamFocusViewController.m
//  inke
//
//  Created by Sam on 12/2/16.
//  Copyright © 2016 Zhejiang University of Tech. All rights reserved.
//

#import "SamFocusViewController.h"
#import "SamLiveCell.h"
#import "SamLive.h"
#import "SamPlayerViewController.h"
#import "SamLiveHandler.h"
#import "SamTickersView.h"
#import "SamTickerActionsViewController.h"
#import "MJRefresh.h"



static NSString * identifier = @"focus";

@interface SamFocusViewController () <SamTickersDelegate>

@property(nonatomic, strong) NSArray *dataList;
@property(nonatomic, strong) SamTickersView *tickersView;
@property(nonatomic, strong) NSMutableArray *imageAndLinkArray;

@end

@implementation SamFocusViewController

-(NSMutableArray *)imageAndLinkArray
{
    if (!_imageAndLinkArray) {
        _imageAndLinkArray = [NSMutableArray array];
//        [SamLiveHandler executeGetTickersTaskWithSuccess:^(id obj) {
//            [_imageAndLinkArray removeAllObjects];
//            [_imageAndLinkArray addObjectsFromArray:obj];
//            [self.tickersView updateForImagesAndLinks:_imageAndLinkArray];
//            //NSLog(@"_imageAndLinkArray init: %@",_imageAndLinkArray);
//        } failed:^(id obj) {
//            NSLog(@"%@",obj);
//        }];
        // if failed to get tickers from internet, load images from local.
        if (!_imageAndLinkArray) {
            for (int i = 0; i < 7; i++) {
                UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%d",i+1]];
                [_imageAndLinkArray addObject:image];
            }
        }
        
    }
    return _imageAndLinkArray;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    [self initUI];
    
    [self loadData];
    
    [self prepareRefresh];
}

-(SamTickersView *)TickersView
{
    if (!_tickersView) {
        _tickersView = [SamTickersView loadTickersView];
    }
    return _tickersView;
}

-(void) initUI
{
    [self.tableView registerNib:[UINib nibWithNibName:@"SamLiveCell" bundle:nil] forCellReuseIdentifier:identifier];
    self.tickersView = [SamTickersView loadTickersView];
    self.tickersView.delegate = self;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(clickTickerOfTickersView:)];
    [self.tickersView addGestureRecognizer:tapGesture];
    self.tableView.tableHeaderView = self.tickersView;
}

- (void)prepareRefresh
{
    NSMutableArray *imagesArray = [NSMutableArray array];
    for (int i = 1; i < 29; i++) {
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"refresh_fly_00%02d",i]];
        [imagesArray addObject:image];
    }
    MJRefreshGifHeader *gifRefreshHeader = [MJRefreshGifHeader headerWithRefreshingBlock:^{
        [self loadData];
    }];
    gifRefreshHeader.stateLabel.hidden = YES;
    gifRefreshHeader.lastUpdatedTimeLabel.hidden = YES;
    [gifRefreshHeader setImages:imagesArray duration:1.5 forState:MJRefreshStateIdle];
    [gifRefreshHeader setImages:imagesArray duration:1.5 forState:MJRefreshStatePulling];
    [gifRefreshHeader setImages:imagesArray duration:1.5 forState:MJRefreshStateRefreshing];
    [gifRefreshHeader setImages:imagesArray duration:1.5 forState:MJRefreshStateNoMoreData];
    self.tableView.mj_header = gifRefreshHeader;
}

- (void)clickTickerOfTickersView:(UITapGestureRecognizer *)tapGesture
{
    SamTickerActionsViewController *actionVC = [[SamTickerActionsViewController alloc]init];
    actionVC.urlString = [self.tickersView LinkAtCurrentPageIndex];
    [self.navigationController pushViewController:actionVC animated:YES];
    [self.tabBarController setHidesBottomBarWhenPushed:YES];
}

- (void)loadData
{
    SamLive *live = [[SamLive alloc]init];
    live.city = @"杭州";
    live.onlineUsers = 18999;
    live.streamAddr = LIVE_SAM;
    
    SamCreator *creator = [[SamCreator alloc]init];
    creator.nick = @"Sam";
    creator.portrait = @"Sam";
    live.creator = creator;
    self.dataList = @[live];
    
    [SamLiveHandler executeGetTickersTaskWithSuccess:^(id obj) {
        [self.imageAndLinkArray removeAllObjects];
        [self.imageAndLinkArray addObjectsFromArray:obj];
        [self.tickersView updateForImagesAndLinks:_imageAndLinkArray];
        if (self.tableView.mj_header.isRefreshing) {
            [self.tableView.mj_header endRefreshing];
        }
    } failed:^(id obj) {
        NSLog(@"%@",obj);
    }];
    
    
    [self.tableView reloadData];
}

#pragma mark TableView staff

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
//    return self.dataList.count;
    return 1;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SamLiveCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"SamLiveCell" owner:self options:nil] lastObject];
    }
    cell.live = self.dataList[indexPath.row];
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat cellHeight;
    cellHeight = 70 + [UIScreen mainScreen].bounds.size.width;
    return cellHeight;
}

#pragma mark TableView delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    SamLive *live = self.dataList[indexPath.row];
    SamPlayerViewController *playerVC = [[SamPlayerViewController alloc]init];
    playerVC.live = live;
    
    [playerVC setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
    [self presentViewController:playerVC animated:YES completion:nil];
    
    //    self.parentViewController.view.hidden = YES;
    //    playerVC.hidesBottomBarWhenPushed = YES;
    //    [self.navigationController pushViewController:playerVC animated:YES];
}

#pragma mark TickersDelegate

-(NSMutableArray *)tickersDataList
{
    return self.imageAndLinkArray;
}

-(CGSize)sizeForTickersView
{
    if ([[self.imageAndLinkArray firstObject] isKindOfClass:[UIImage class]]) {
        UIImage *image = [self.imageAndLinkArray firstObject];
        return CGSizeMake(image.size.width, image.size.height);
    } else {
        return CGSizeMake(kScreenWidth, kScreenHeight*0.3);
    }
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
