//
//  SPKRViewController.m
//  ScrumPoker
//
//  Created by Daniel Leber on 9/4/14.
//  Copyright (c) 2014 Daniel Leber. All rights reserved.
//

#import "SPKRViewController.h"
#import "SPKRCollectionViewCell.h"
@import AVFoundation;
@import MediaPlayer;

static CGFloat SPKRViewControllerAnimationDuration = 0.4f;

@interface SPKRViewController ()

@property (nonatomic, strong) NSArray *cellTitles;
@property (nonatomic, weak) NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) MPVolumeView *volumeView;
@property (nonatomic, assign) float previousOutputVolume;

@end

@implementation SPKRViewController

- (void)dealloc
{
	[self.volumeView removeFromSuperview];
	self.volumeView = nil;
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[AVAudioSession sharedInstance] setActive:NO error:nil];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	MPVolumeView *volumeView = [[MPVolumeView alloc] initWithFrame:CGRectZero];
	volumeView.layer.mask = [CALayer layer];
	volumeView.userInteractionEnabled = NO;
	[self.view addSubview:volumeView];
	self.volumeView = volumeView;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(systemControllerSystemVolumeDidChangeNotification:) name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startAudioSession) name:UIApplicationDidBecomeActiveNotification object:[UIApplication sharedApplication]];
	self.cellTitles = @[@"1/2", @"1", @"2", @"3", @"5", @"8", @"13", @"20", @"40", @"100", @"∞", @"☕️"];
	
	self.view.backgroundColor = self.collectionView.backgroundColor;
	
	UIView *behindGestureView = [[UIView alloc] initWithFrame:(CGRect){CGPointZero, self.view.bounds.size}];
	behindGestureView.backgroundColor = [UIColor clearColor];
	behindGestureView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view insertSubview:behindGestureView belowSubview:self.collectionView];
	
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
	[behindGestureView addGestureRecognizer:tapGesture];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self startAudioSession];
}

#pragma mark - Private

- (void)startAudioSession
{
	self.previousOutputVolume = [[AVAudioSession sharedInstance] outputVolume];
	[[AVAudioSession sharedInstance] setActive:YES error:nil];
}

- (void)systemControllerSystemVolumeDidChangeNotification:(NSNotification *)note
{
	if (!self.selectedIndexPath)
		return;
	
	CGFloat oldVolume = self.previousOutputVolume;
	CGFloat newVolume = [note.userInfo[@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
	self.previousOutputVolume = newVolume;
	
	NSInteger newIndex = NSIntegerMax;
	
	if (newVolume > oldVolume || (fabs(1.0f - oldVolume) < __FLT_EPSILON__ && fabs(1.0f - newVolume) < __FLT_EPSILON__))
	{
		newIndex = self.selectedIndexPath.item + 1;
	}
	else if (newVolume < oldVolume || (newVolume < __FLT_EPSILON__ && oldVolume < __FLT_EPSILON__))
	{
		newIndex = self.selectedIndexPath.item - 1;
	}
	
	if (newIndex >= 0 && newIndex < self.cellTitles.count)
	{
		SPKRCollectionViewCell *currentCell = (id)[self.collectionView cellForItemAtIndexPath:self.selectedIndexPath];
		currentCell.transform = CGAffineTransformIdentity;
		currentCell.alpha = 0.0;
		
		self.selectedIndexPath = [NSIndexPath indexPathForItem:newIndex inSection:0];
		SPKRCollectionViewCell *newCell = (id)[self.collectionView cellForItemAtIndexPath:self.selectedIndexPath];
		newCell.alpha = 1.0;
		newCell.transform = [self transformForCell:newCell];
	}
}

- (CGAffineTransform)transformForCell:(UICollectionViewCell *)newCell
{
	CGFloat scale = (CGRectGetWidth(self.collectionView.frame) / CGRectGetWidth(newCell.frame));
	CGFloat tx = self.collectionView.center.x - newCell.center.x;
	CGFloat ty = self.collectionView.center.y - newCell.center.y;
	
	CGAffineTransform t = CGAffineTransformIdentity;
	t = CGAffineTransformTranslate(t, tx, ty);
	t = CGAffineTransformScale(t, scale, scale);
	
	return t;
}

- (void)decorateView:(UIView *)cell;
{
	cell.layer.cornerRadius = 5.0;
	cell.layer.borderColor = [UIColor blueColor].CGColor;
	cell.layer.borderWidth = 1.0;
	cell.backgroundColor = [UIColor lightGrayColor];
}

- (void)didTap:(UITapGestureRecognizer *)recognizer
{
	if (!self.selectedIndexPath)
		return;
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	
	[UIView animateWithDuration:SPKRViewControllerAnimationDuration animations:^{
		
		self.collectionView.alpha = 1.0;
	} completion:^(BOOL finished) {
		
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
	}];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
	return self.cellTitles.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
	SPKRCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[SPKRCollectionViewCell reuseIdentifier] forIndexPath:indexPath];
	
	[self decorateView:cell];
	cell.titleLabel.text = self.cellTitles[indexPath.item];
	cell.transform = CGAffineTransformIdentity;
	cell.alpha = 1.0;
	
	return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
	if (self.selectedIndexPath)
	{
		SPKRCollectionViewCell *cell = (id)[collectionView cellForItemAtIndexPath:self.selectedIndexPath];
		self.selectedIndexPath = nil;
		
		[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
		[UIView animateWithDuration:SPKRViewControllerAnimationDuration animations:^{
			
			cell.transform = CGAffineTransformIdentity;
			
			for (UIView *subview in collectionView.subviews)
			{
				if ([subview isKindOfClass:[SPKRCollectionViewCell class]])
				{
					subview.alpha = 1.0;
				}
			}

		} completion:^(BOOL finished) {
			
			[[UIApplication sharedApplication] endIgnoringInteractionEvents];
		}];
	}
	else
	{
		self.selectedIndexPath = indexPath;
		
		SPKRCollectionViewCell *cell = (id)[collectionView cellForItemAtIndexPath:indexPath];
		[cell.superview bringSubviewToFront:cell];
		
		[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
		[UIView animateWithDuration:SPKRViewControllerAnimationDuration animations:^{
			
			cell.transform = [self transformForCell:cell];
			
			for (UIView *subview in [collectionView subviews])
			{
				if ([subview isKindOfClass:[SPKRCollectionViewCell class]])
				{
					if (subview != cell)
					{
						subview.alpha = 0.0;
					}
				}
			}
			
		} completion:^(BOOL finished) {
			
			[UIView animateWithDuration:SPKRViewControllerAnimationDuration animations:^{
				
				collectionView.alpha = 0.0;
			} completion:^(BOOL finished) {
				
				[[UIApplication sharedApplication] endIgnoringInteractionEvents];
			}];
		}];
	}
}

@end
