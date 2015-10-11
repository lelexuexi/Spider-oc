//
//  ViewController.m
//  爬虫测试
//
//  Created by Jefferson on 15/10/9.
//  Copyright © 2015年 Jefferson. All rights reserved.
//

#import "ViewController.h"
#import "NSArray+Log.h"
#import "NSString+Regex.h"
#define kBaseURL @"http://zhougongjiemeng.1518.com/"
//#define kBaseURL @"http://www.meilishuo.com/"

@interface ViewController ()

@property (nonatomic, strong) NSMutableArray *dataList;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (NSMutableArray *)dataList {
    
    if (!_dataList) {
        _dataList = [[NSMutableArray alloc] init];
    }
    return _dataList;

}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
    [self spider];

}

// 通过网络请求获取数据，转成字符串返回
- (NSString *)htmlWithUrlString:(NSString *)urlString {
    
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    NSError *error = nil;
    
    if (error) {
        NSLog(@"%@",error.localizedDescription);
        return nil;
    }
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:&error];
    
    return [NSString UTF8StringWithHZGB2312Data:data];

}


- (void)spider {
    
    NSString *html = [self htmlWithUrlString:kBaseURL];
    
//    NSLog(@"%@",html);
    
    // <ul class=\"cs_list\">.*?</ul>
    NSString *pattern = [NSString stringWithFormat:@"<ul class=\"cs_list\"(>.*?)</ul>"];
//    NSRegularExpression *regular = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive | NSRegularExpressionDotMatchesLineSeparators error:NULL];
//    
//    NSTextCheckingResult *result = [regular firstMatchInString:html options:0 range:NSMakeRange(0, html.length)];
//
//    NSRange r = [result rangeAtIndex:1];
//    NSString *content = [html substringWithRange:r];
    
    NSString *content = [html firstMatchWithPattern:pattern];
    
    // 开始抓取
    NSString *p = @"<li><a href=\"(.*?)\">(.*?)</a>\\((.*?)\\)</li>";

    NSArray *array = [content matchesWithPattern:p keys:@[@"url", @"title", @"count"]];

    for (NSDictionary *dict in array) {
        [self spider2Dict:dict];
    }
    NSLog(@"已全部下载");
    [self.dataList writeToFile:@"/Users/jefferson/Desktop/category.plist" atomically:YES];
}

- (void)spider2Dict:(NSDictionary *)dict {
    
    NSString *urlString = [NSString stringWithFormat:@"%@%@",kBaseURL,dict[@"url"]];
    NSString *html = [self htmlWithUrlString:urlString];
    
    
    // <li><a href="/zhougongjiemeng-7355-yingshi" title="硬石">硬石</a></li>
    NSString *content = [html firstMatchWithPattern:@"<div class=\"listpage_content\">.*?<ul>(.*?)</ul>"];
    

    NSArray *array = [content matchesWithPattern:@"<li><a href=\"(.*?)\".*?>(.*?)</a></li>" keys:@[@"url", @"name"]];

//    NSLog(@"%@",array);
    for (NSDictionary *d in array) {
        [self spider3Dict:d withCategory:dict[@"title"]];
        NSLog(@"正在抓取中%@。。。",d[@"name"]);
        [NSThread sleepForTimeInterval:0.1];
        
    }
    
}

- (void)spider3Dict:(NSDictionary *)dict withCategory:(NSString *)category {
 
    // 获取 urlstring
    NSString *urlString = [NSString stringWithFormat:@"%@%@",kBaseURL,dict[@"url"]];
    NSString *html = [self htmlWithUrlString:urlString];
    
    NSString *desc = [html firstMatchWithPattern:@"<dd>(.*?)</dd>"];
    
//    NSLog(@"%@",desc);
 
    NSString *content = [html firstMatchWithPattern:@"相关词条:(.*?)</div>"];
//    NSLog(@"%@",content);
    
    NSArray *array = [content matchesWithPattern:@"梦见：<a href=\"/.*?\"><u>(.*?)</u></a>" keys:@[@"title"]];

    
    NSDictionary *item = @{@"category": category, @"title": dict[@"name"], @"desc": desc};
    NSLog(@"%@",self.dataList);
    
    [self.dataList addObject:item];
    
}

@end
