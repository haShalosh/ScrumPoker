//
//  SPKRViewController.h
//  ScrumPoker
//
//  Created by Daniel Leber on 9/4/14.
//  Copyright (c) 2014 Daniel Leber. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPKRViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;

@end
