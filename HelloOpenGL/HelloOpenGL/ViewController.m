//
//  ViewController.m
//  HelloOpenGL
//
//  Created by Elber Carneiro on 8/24/15.
//  Copyright (c) 2015 Elber Carneiro. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CGRect screenbounds = [[UIScreen mainScreen] bounds];
    self.glView = [[OpenGLView alloc] initWithFrame:screenbounds];
    [self.view addSubview:self.glView];
}

@end
