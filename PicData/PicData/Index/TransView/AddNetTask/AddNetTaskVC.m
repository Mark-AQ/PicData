//
//  AddNetTaskVC.m
//  PicData
//
//  Created by CleverPeng on 2020/8/18.
//  Copyright © 2020 garenge. All rights reserved.
//

#import "AddNetTaskVC.h"

@interface AddNetTaskVC ()

@property (weak, nonatomic) IBOutlet UITextField *contentTF;
@property (weak, nonatomic) IBOutlet UITextField *titleTF;
@property (weak, nonatomic) IBOutlet UIButton *downloadBtn;
@property (weak, nonatomic) IBOutlet UIButton *batchDownloadBtn;

@property (weak, nonatomic) IBOutlet UITextView *multiTextView;

@property (nonatomic, strong) NSLock *lock;

@property (nonatomic, strong) NSString *host_url;

@end

@implementation AddNetTaskVC

- (NSString *)host_url {
    return [AppTool sharedAppTool].HOST_URL;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (NSLock *)lock {
    if (nil == _lock) {
        _lock = [[NSLock alloc] init];
    }

    return _lock;
}

- (void)loadNavigationItem {
    self.navigationItem.title = @"创建网络任务";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(sureToAdd:)];
}

- (void)loadMainView {
    [super loadMainView];
    self.multiTextView.layer.cornerRadius = 4;
    self.multiTextView.layer.borderWidth = 1;
    self.multiTextView.layer.borderColor = [UIColor lightGrayColor].CGColor;

    self.downloadBtn.layer.cornerRadius = 4;
    self.downloadBtn.layer.borderColor = self.downloadBtn.tintColor.CGColor;
    self.downloadBtn.layer.borderWidth = 1;
    self.downloadBtn.layer.masksToBounds = YES;

    self.batchDownloadBtn.layer.cornerRadius = 4;
    self.batchDownloadBtn.layer.borderColor = self.batchDownloadBtn.tintColor.CGColor;
    self.batchDownloadBtn.layer.borderWidth = 1;
    self.batchDownloadBtn.layer.masksToBounds = YES;
}

- (void)prepareSourceWithUrl:(NSString *)url HOST_URLString:(NSString *)HOST_URLString title:(NSString *)title resultHandler:(void(^)(PicSourceModel *sourceModel, PicContentModel *contentModel))result {

    if ([url containsString:@"_"]) {
        NSRange range = [url rangeOfString:@"_"];
        url = [[url substringToIndex:range.location] stringByAppendingString:@".html"];
    }
    url = [url stringByReplacingOccurrencesOfString:HOST_URLString withString:@""];
    PDBlockSelf
    dispatch_queue_t serialDiapatchQueue = dispatch_queue_create("com.test.queue.add", DISPATCH_QUEUE_SERIAL);
    dispatch_sync(serialDiapatchQueue, ^{
        // 创建一个SourceModel
        PicSourceModel *sourceModel = [[PicSourceModel alloc] init];
        sourceModel.title = @"网络美女";

        sourceModel.HOST_URL = HOST_URLString;
        sourceModel.url = @"";
        sourceModel.sourceType = 5;


        [weakSelf.lock lock];
        if ([PicSourceModel queryTableWithTitle:@"网络美女"].count == 0) {
            [sourceModel insertTable];
        }
        [weakSelf.lock unlock];

        PicContentModel *contentModel = [[PicContentModel alloc] init];
        contentModel.title = title;
        contentModel.HOST_URL = sourceModel.HOST_URL;
        contentModel.sourceTitle = sourceModel.title;
        contentModel.thumbnailUrl = @"";
        contentModel.href = url;

        [weakSelf.lock lock];
        if ([PicContentModel queryTableWithHref:url].count == 0) {

            [contentModel insertTable];
        }
        [weakSelf.lock unlock];


        NSError *error = nil;
        NSURL *baseURL = [NSURL URLWithString:sourceModel.HOST_URL];
        NSString *content = [NSString stringWithContentsOfURL:[NSURL URLWithString:url relativeToURL:baseURL] encoding:[AppTool getNSStringEncoding_GB_18030_2000] error:&error];

        if (error) {
            NSLog(@"%@, 出现错误-1, %@", [NSURL URLWithString:url relativeToURL:baseURL].absoluteString, error);
        } else {
            NSLog(@"%@, 完成", [NSURL URLWithString:url relativeToURL:baseURL].absoluteString);

            NSString *title = [weakSelf dealWithHtmlData:content];
            contentModel.title = title;
            [contentModel updateTable];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            result(sourceModel, contentModel);
        });
    });
}

- (NSString *)dealWithHtmlData:(NSString *)htmlString {
    NSString *title = @"";
    if (htmlString.length > 0) {

        OCGumboDocument *document = [[OCGumboDocument alloc] initWithHTMLString:htmlString];

        OCGumboElement *HE = document.QueryClass(@"articleV4Tit").firstObject;
        if (HE) {
            title = HE.text();
        }
//        OCQueryObject *metaEs = document.QueryElement(@"meta");
//        for (OCGumboElement *metaE in metaEs) {
//            if ([metaE.attr(@"name") isEqualToString:@"keywords"]) {
//                title = metaE.attr(@"content");
//                break;
//            }
//        }
    }

    return title ?: @"";
}

- (void)sureToAdd:(UIBarButtonItem *)sender {
    if (self.contentTF.text.length > 0) {
        [self prepareSourceWithUrl:self.contentTF.text HOST_URLString:self.host_url title:self.titleTF.text resultHandler:^(PicSourceModel *sourceModel, PicContentModel *contentModel) {
            DetailViewController *detailVC = [[DetailViewController alloc] init];
            detailVC.sourceModel = sourceModel;
            detailVC.contentModel = contentModel;
            [self.navigationController pushViewController:detailVC animated:YES];
        }];

        self.contentTF.text = @"";
    }
}

- (IBAction)downAction:(id)sender {
    if (self.contentTF.text.length > 0) {
        [self prepareSourceWithUrl:self.contentTF.text HOST_URLString:self.host_url title:self.titleTF.text resultHandler:^(PicSourceModel *sourceModel, PicContentModel *contentModel) {
            [ContentParserManager tryToAddTaskWithSourceModel:sourceModel ContentModel:contentModel operationTips:^(BOOL isSuccess, NSString * _Nonnull tips) {
                [MBProgressHUD showInfoOnView:self.view WithStatus:tips afterDelay:0.5];
            }];
        }];
    }
}

- (IBAction)multiDownAction:(id)sender {

    if (self.multiTextView.text.length > 0) {
        NSString *targetUrls = self.multiTextView.text;
        NSArray *urls = [targetUrls componentsSeparatedByString:@"\n"];
        for (NSString *url in urls) {
            if (url.length == 0) {
                continue;
            }
            [self prepareSourceWithUrl:url HOST_URLString:self.host_url title:@"" resultHandler:^(PicSourceModel *sourceModel, PicContentModel *contentModel) {
                [ContentParserManager tryToAddTaskWithSourceModel:sourceModel ContentModel:contentModel operationTips:^(BOOL isSuccess, NSString * _Nonnull tips) {
                    [MBProgressHUD showInfoOnView:self.view WithStatus:tips afterDelay:0.5];
                }];
            }];
        }
        self.multiTextView.text = @"";
    }

}

@end
