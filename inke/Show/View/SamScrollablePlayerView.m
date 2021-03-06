//
//  SamScrollablePlayerView.m
//  inke
//
//  Created by Sam on 2/2/17.
//  Copyright © 2017 Zhejiang University of Tech. All rights reserved.
//

#import "SamScrollablePlayerView.h"
#import "SamLive.h"

@interface SamScrollablePlayerView () <UIScrollViewDelegate>

@property (nonatomic, strong) NSMutableArray * lives;
@property (nonatomic, strong) SamLive *live;
@property (nonatomic, strong) UIImageView *upperBlurImageView, *middleBlurImageView, *downBlurImageView;
@property (nonatomic, strong) SamLive *upperLive, *middleLive, *downLive;
@property (nonatomic, assign) NSInteger currentIndex, previousIndex;



@end

@implementation SamScrollablePlayerView

- (NSMutableArray *)lives
{
    if (!_lives) {
        _lives = [NSMutableArray array];
    }
    return _lives;
}

+ (instancetype)loadScrollablePlayerView
{
    return [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil] lastObject];
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    //    [self setupImageViews];
    [self initUI];
}

- (void) initUI
{
    // prepare scrollView
    self.playerScrollView.delegate = self;
    
    // image views
    // blur effect
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    // blur view
    UIVisualEffectView *visualEffectViewUpper = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    UIVisualEffectView *visualEffectViewMiddle = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    UIVisualEffectView *visualEffectViewDown = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    
    self.upperBlurImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, kScreenHeight)];
    self.middleBlurImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, kScreenHeight, kScreenWidth, kScreenHeight)];
    self.downBlurImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, kScreenHeight*2, kScreenWidth, kScreenHeight)];
    
    // add image views
    [self.playerScrollView addSubview:self.upperBlurImageView];
    [self.playerScrollView addSubview:self.middleBlurImageView];
    [self.playerScrollView addSubview:self.downBlurImageView];
    
    visualEffectViewUpper.frame = self.upperBlurImageView.frame;
    [self.playerScrollView addSubview:visualEffectViewUpper];
    visualEffectViewMiddle.frame = self.middleBlurImageView.frame;
    [self.playerScrollView addSubview:visualEffectViewMiddle];
    visualEffectViewDown.frame = self.downBlurImageView.frame;
    [self.playerScrollView addSubview:visualEffectViewDown];
    
    self.playerScrollView.contentSize = CGSizeMake(0, kScreenHeight*3);
    self.playerScrollView.contentOffset = CGPointMake(0, kScreenHeight);
}


- (void)updateForLives:(NSMutableArray *)livesArray withCurrentIndex:(NSInteger)index
{
    if (livesArray.count && [livesArray firstObject]) {
        [self.lives removeAllObjects];
        [self.lives addObjectsFromArray:livesArray];
        self.currentIndex = index;
        self.previousIndex = index;
        
        _upperLive = [[SamLive alloc] init];
        _middleLive = (SamLive *)_lives[_currentIndex];
        _downLive = [[SamLive alloc] init];
        
        if (_currentIndex == 0) {
            _upperLive = (SamLive *)[_lives lastObject];
        } else {
            _upperLive = (SamLive *)_lives[_currentIndex - 1];
        }
        if (_currentIndex == _lives.count - 1) {
            _downLive = (SamLive *)[_lives firstObject];
        } else {
            _downLive = (SamLive *)_lives[_currentIndex + 1];
        }
    
        [self prepareForImageView:self.upperBlurImageView withLive:_upperLive];
        [self prepareForImageView:self.middleBlurImageView withLive:_middleLive];
        [self prepareForImageView:self.downBlurImageView withLive:_downLive];
    }
}

- (void) prepareForImageView: (UIImageView *)imageView withLive:(SamLive *)live
{
    if (![live.creator.portrait hasPrefix:IMAGE_SERVER_HOST]) {
        live.creator.portrait = [IMAGE_SERVER_HOST stringByAppendingString:live.creator.portrait];
    }
    [imageView downloadImage:live.creator.portrait placeholder:@"default_room"];
}

- (void)switchPlayer:(UIScrollView*)scrollView
{
    CGFloat offset = scrollView.contentOffset.y;
    if (self.lives.count) {
        if (offset >= 2*kScreenHeight)
        {
            // slides to the down player
            scrollView.contentOffset = CGPointMake(0, kScreenHeight);
            _currentIndex++;
            self.upperBlurImageView.image = self.middleBlurImageView.image;
            self.middleBlurImageView.image = self.downBlurImageView.image;
            if (_currentIndex == self.lives.count - 1)
            {
                _downLive = [self.lives firstObject];
            } else if (_currentIndex == self.lives.count)
            {
                _downLive = self.lives[1];
                _currentIndex = 0;
                
            } else
            {
                _downLive = self.lives[_currentIndex+1];
            }
            [self prepareForImageView:self.downBlurImageView withLive:_downLive];
            if (_previousIndex == _currentIndex) {
                return;
            }
            if ([self.playerDelegate respondsToSelector:@selector(scrollablePlayerView:currentPlayIndex:)]) {
                [self.playerDelegate scrollablePlayerView:self currentPlayIndex:_currentIndex];
                _previousIndex = _currentIndex;
                NSLog(@"current index in delegate: %ld -%s",_currentIndex,__FUNCTION__);
            }
        }
        else if (offset <= 0)
        {
            // slides to the middle imageView
            scrollView.contentOffset = CGPointMake(0, kScreenHeight);
            _currentIndex--;
            self.downBlurImageView.image = self.middleBlurImageView.image;
            self.middleBlurImageView.image = self.upperBlurImageView.image;
            if (_currentIndex == 0)
            {
                _upperLive = [self.lives lastObject];
                
            } else if (_currentIndex == -1)
            {
                _upperLive = self.lives[self.lives.count - 2];
                _currentIndex = self.lives.count-1;
                
            } else
            {
                _upperLive = self.lives[_currentIndex - 1];
                [self prepareForImageView:self.upperBlurImageView withLive:_upperLive];
            }
            [self prepareForImageView:self.upperBlurImageView withLive:_upperLive];
            if (_previousIndex == _currentIndex) {
                return;
            }
            if ([self.playerDelegate respondsToSelector:@selector(scrollablePlayerView:currentPlayIndex:)]) {
                [self.playerDelegate scrollablePlayerView:self currentPlayIndex:_currentIndex];
                _previousIndex = _currentIndex;
                NSLog(@"current index in delegate: %ld -%s",_currentIndex,__FUNCTION__);
            }
        }
    }
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self switchPlayer:scrollView];
}

//- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
//{
//    if (_previousIndex == _currentIndex) {
//        return;
//    }
//    if ([self.playerDelegate respondsToSelector:@selector(scrollablePlayerView:currentPlayIndex:)]) {
//        [self.playerDelegate scrollablePlayerView:self currentPlayIndex:_currentIndex];
//        _previousIndex = _currentIndex;
//        NSLog(@"current index in delegate: %ld -%s",_currentIndex,__FUNCTION__);
//    }
//}

@end
