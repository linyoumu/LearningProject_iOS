//
//  ViewController.m
//  LearningProject_iOS
//
//  Created by LinMacmini on 2023/4/7.
//

#import "ViewController.h"
#import "avformat.h"
#import "timestamp.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    av_log_set_level(AV_LOG_DEBUG);

    
    const char * version = av_version_info();
    const char * config = avutil_configuration();
    av_log(NULL, AV_LOG_INFO, "当前ffmpeg版本号：%s\n\n", version);
    av_log(NULL, AV_LOG_INFO, "当前ffmpeg配置：%s", config);
    
    
    
}


@end
