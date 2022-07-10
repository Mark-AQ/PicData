//
//  ContentParserManager+Parser.m
//  PicData
//
//  Created by 鹏鹏 on 2022/5/28.
//  Copyright © 2022 garenge. All rights reserved.
//

#import "ContentParserManager+Parser.h"

@implementation ContentParserManager (Parser)

+ (NSString *)getHtmlStringWithData:(NSData *)data sourceType:(int)sourceType {
    switch (sourceType) {
        case 1:
        case 2:
        case 5:
            return [AppTool getStringWithGB_18030_2000Code:data];
            break;
        case 3:
        case 8:
            return [AppTool getStringWithUTF8Code:data];
            break;
        default:
            break;
    }
    return @"";
}

+ (PicContentModel *)getContentModelWithSourceModel:(PicSourceModel *)sourceModel withArticleElement:(OCGumboElement *)articleElement {

    OCGumboElement *aE;
    NSString *title;
    
    switch (sourceModel.sourceType) {
        case 1:
        case 2:
        case 3: {
            aE = articleElement.QueryElement(@"a").firstObject;
            title = aE.attr(@"title");
        }
            break;
        case 5:
            break;
        case 8: {
            OCGumboElement *divE = [articleElement.QueryElement(@"div") objectOrNilAtIndex:3];
            aE = divE.QueryElement(@"a").firstObject;
            title = aE.text();
        }
            break;
        default:
            break;
    }

    NSString *href = aE.attr(@"href");

    OCGumboElement *imgE;

    switch (sourceModel.sourceType) {
        case 1:
        case 2:
        case 5:
            imgE = aE.QueryElement(@"img").firstObject;
            title = imgE.attr(@"alt");
            break;
        case 3:
            imgE = aE.QueryClass(@"xld").firstObject;
            break;
        case 8: {
            imgE = articleElement.QueryElement(@"img").firstObject;
        }
            break;
        default:
            break;
    }

    NSString *thumbnailUrl = imgE.attr(@"src");

    PicContentModel *contentModel = [[PicContentModel alloc] init];
    contentModel.href = href;
    contentModel.sourceHref = sourceModel.url;
    contentModel.sourceTitle = sourceModel.title;
    contentModel.HOST_URL = sourceModel.HOST_URL;
    contentModel.title = title;
    contentModel.thumbnailUrl = thumbnailUrl;

    return contentModel;
}

+ (PicClassModel *)getClassModelWithHostModel:(PicNetModel *)hostModel withTagsListElement:(OCGumboElement *)tagsListE {

    OCQueryObject *aEs = tagsListE.QueryElement(@"a");

    NSMutableArray *subTitles = [NSMutableArray array];
    for (OCGumboElement *aE in aEs) {
        NSString *href = aE.attr(@"href");

        PicSourceModel *sourceModel = [[PicSourceModel alloc] init];
        sourceModel.sourceType = hostModel.sourceType;

        NSString *url;
        NSString *subTitle;
        switch (hostModel.sourceType) {
            case 1: {
                url = [hostModel.HOST_URL stringByAppendingPathComponent:href];
                subTitle = aE.text();
            }
                break;
            case 2: {
                url = href;
                subTitle = aE.text();
            }
                break;
            case 5: {
                url = href;
                subTitle = aE.text();
            }
                break;
            case 8: {
                url = [[hostModel.HOST_URL stringByAppendingPathComponent:href] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                url = [url stringByReplacingOccurrencesOfString:@".html" withString:@"/sort-read.html"];
                subTitle = aE.text();
                if ([href containsString:@"series-"]) {
                    NSString *regex = @"(?<=series-).*?(?=.html)";
                    NSError *error;
                    NSRegularExpression *regular = [NSRegularExpression regularExpressionWithPattern:regex options:NSRegularExpressionCaseInsensitive error:&error];
                    // 对str字符串进行匹配
                    NSString *result = [href substringWithRange:[regular firstMatchInString:href options:0 range:NSMakeRange(0, href.length)].range];
                    if (result.length > 0) {
                        subTitle = result;
                    }
                } else if ([href containsString:@"model-"]) {
                    NSString *regex = @"(?<=model-).*?(?=.html)";
                    NSError *error;
                    NSRegularExpression *regular = [NSRegularExpression regularExpressionWithPattern:regex options:NSRegularExpressionCaseInsensitive error:&error];
                    // 对str字符串进行匹配
                    NSString *result = [href substringWithRange:[regular firstMatchInString:href options:0 range:NSMakeRange(0, href.length)].range];
                    if (result.length > 0) {
                        subTitle = result;
                    }
                } else if ([subTitle containsString:@"全部"]){
                    subTitle = @"全部";
                }
            }
                break;
            default:
                break;
        }
        sourceModel.url = url;
        sourceModel.title = subTitle;
        sourceModel.HOST_URL = hostModel.HOST_URL;
        [sourceModel insertTable];

        [subTitles addObject:sourceModel];
    }

    PicClassModel *classModel = [PicClassModel modelWithHOST_URL:hostModel.HOST_URL Title:@"标签" sourceType:hostModel.sourceType subTitles:subTitles];

    return classModel;

}

+ (NSArray <PicClassModel *>*)parseTagsWithHtmlString:(NSString *)htmlString HostModel:(PicNetModel *)hostModel {

    NSMutableArray *classModelsM = [NSMutableArray array];

    if (htmlString.length == 0) { return classModelsM; }

    OCGumboDocument *document = [[OCGumboDocument alloc] initWithHTMLString:htmlString];

    OCQueryObject *tagsListEs;
    switch (hostModel.sourceType) {
        case 1: {
            tagsListEs = document.QueryClass(@"jigou");
        }
            break;
        case 2: {
            tagsListEs = document.QueryClass(@"TagTop_Gs_r");
        }
            break;
        case 5: {
            tagsListEs = document.QueryClass(@"jigou");
        }
            break;
        case 8: {
            tagsListEs = document.QueryClass(@"series");
        }
        default:
            break;
    }

    for (OCGumboElement *tagsListE in tagsListEs) {

        PicClassModel *classModel = [self getClassModelWithHostModel:hostModel withTagsListElement:tagsListE];
        [classModelsM addObject:classModel];
    }

    return classModelsM;
}

+ (NSArray<PicContentModel *> *)parseContentListWithDocument:(OCGumboDocument *)document sourceModel:(PicSourceModel *)sourceModel {

    NSMutableArray *articleContents = [NSMutableArray array];

    switch (sourceModel.sourceType) {
        case 1: {
            OCGumboElement *listDiv = document.QueryClass(@"w1000").firstObject;
            if(nil == listDiv) {return @[];}
            OCQueryObject *articleEs = listDiv.QueryClass(@"post");

            for (OCGumboElement *articleE in articleEs) {

                PicContentModel *contentModel = [self getContentModelWithSourceModel:sourceModel withArticleElement:articleE];

                // 部分查找结果会返回高亮语句<font color='red'>keyword</font>, 想了好几种方法, 不如直接替换了最快
                NSString *title = contentModel.title;
                title = [title stringByReplacingOccurrencesOfString:@"<font color=\'red\'>" withString:@""];
                title = [title stringByReplacingOccurrencesOfString:@"</font>" withString:@""];
                contentModel.title = title;

                [contentModel insertTable];
                [articleContents addObject:contentModel];
            }
        }
            break;
        case 2: {
            OCGumboElement *listDiv = document.QueryClass(@"listMeinuT").firstObject;
            OCQueryObject *articleEs = listDiv.QueryElement(@"li");

            for (OCGumboElement *articleE in articleEs) {

                PicContentModel *contentModel = [self getContentModelWithSourceModel:sourceModel withArticleElement:articleE];

                [contentModel insertTable];
                [articleContents addObject:contentModel];
            }
        }
            break;
        case 3: {
            OCGumboElement *listDiv = document.QueryClass(@"videos").firstObject;
            OCQueryObject *articleEs = listDiv.QueryClass(@"thcovering-video");

            for (OCGumboElement *articleE in articleEs) {

                PicContentModel *contentModel = [self getContentModelWithSourceModel:sourceModel withArticleElement:articleE];

                [contentModel insertTable];
                [articleContents addObject:contentModel];
            }
        }
            break;
        case 5: {
            OCGumboElement *listDiv = document.QueryClass(@"list").firstObject;
            if(nil == listDiv) {return @[];}
            OCQueryObject *articleEs = listDiv.QueryClass(@"piece");

            for (OCGumboElement *articleE in articleEs) {

                PicContentModel *contentModel = [self getContentModelWithSourceModel:sourceModel withArticleElement:articleE];

                // 部分查找结果会返回高亮语句<font color='red'>keyword</font>, 想了好几种方法, 不如直接替换了最快
                NSString *title = contentModel.title;
                title = [title stringByReplacingOccurrencesOfString:@"<font color=\'red\'>" withString:@""];
                title = [title stringByReplacingOccurrencesOfString:@"</font>" withString:@""];
                contentModel.title = title;

                [contentModel insertTable];
                [articleContents addObject:contentModel];
            }
        }
            break;
        case 8: {
            OCGumboElement *listDiv = document.QueryClass(@"list").firstObject;
            if(nil == listDiv) {return @[];}
            OCQueryObject *articleEs = listDiv.QueryClass(@"item");

            for (OCGumboElement *articleE in articleEs) {

                PicContentModel *contentModel = [self getContentModelWithSourceModel:sourceModel withArticleElement:articleE];

                [contentModel insertTable];
                [articleContents addObject:contentModel];
            }
        }
            break;
        default:
            break;
    }

    return [articleContents copy];
}

+ (void)parseContentListWithHtmlString:(NSString *)htmlString sourceModel:(nonnull PicSourceModel *)sourceModel completeHandler:(void(^)(NSArray <PicContentModel *>* _Nonnull contentList, NSURL * _Nullable nextPageURL))completeHandler {

    if (htmlString.length == 0) {
        PPIsBlockExecute(completeHandler, @[], nil);
        return;
    }
    
    OCGumboDocument *document = [[OCGumboDocument alloc] initWithHTMLString:htmlString];

    NSArray *results = [self parseContentListWithDocument:document sourceModel:sourceModel];

    NSURL *nextPageURL = nil;

    OCGumboElement *nextE;

    switch (sourceModel.sourceType) {
        case 1:{
            nextE = document.QueryClass(@"pageart").firstObject;
        }
            break;
        case 2: {
            nextE = document.QueryClass(@"page-tag").firstObject;
        }
            break;
        case 3: {
            nextE = document.QueryClass(@"pag").firstObject;
        }
            break;
        case 5: {
            nextE = document.QueryClass(@"page-list").firstObject;
        }
            break;
        case 8: {
            nextE = document.QueryClass(@"pager").firstObject;
        }
            break;
        default:
            break;
    }

    NSString *nextPage = @"";

    if (nextE) {
        OCQueryObject *aEs = nextE.QueryElement(@"a");

        NSString *nextPageTitle = @"下一页";
        switch (sourceModel.sourceType) {
            case 3:
                nextPageTitle = @"Next »";
                break;
            default:
                break;
        }

        for (OCGumboElement *aE in aEs) {
            if ([aE.text() isEqualToString:nextPageTitle]) {
                nextPage = aE.attr(@"href");
                break;
            }
        }
    }

    if (nextPage.length > 0) {
        switch (sourceModel.sourceType) {
            case 1: {
                nextPageURL = [NSURL URLWithString:[sourceModel.url stringByAppendingPathComponent:nextPage]];
            }
                break;
            case 2: {
                nextPageURL = [NSURL URLWithString:[sourceModel.url stringByReplacingOccurrencesOfString:sourceModel.url.lastPathComponent withString:nextPage]];
            }
                break;
            case 3: {
                nextPageURL = [NSURL URLWithString:nextPage relativeToURL:[NSURL URLWithString:sourceModel.HOST_URL]];
            }
                break;
            case 5: {
                nextPageURL = [NSURL URLWithString:nextPage relativeToURL:[NSURL URLWithString:sourceModel.url]];
            }
                break;
            case 8: {
                nextPageURL = [NSURL URLWithString:[nextPage stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]] relativeToURL:[NSURL URLWithString:sourceModel.HOST_URL]];
            }
                break;
            default:
                break;
        }
    } else {
        nextPageURL = nil;
    }

    PPIsBlockExecute(completeHandler, results, nextPageURL)
}

+ (void)parseDetailWithHtmlString:(NSString *)htmlString sourceModel:(PicSourceModel *)sourceModel preNextUrl:(NSString *)preNextUrl needSuggest:(BOOL)needSuggest completeHandler:(void (^)(NSArray<NSString *> * _Nonnull, NSString * _Nonnull, NSArray<PicContentModel *> * _Nullable, NSString * _Nullable))completeHandler {

    if (htmlString.length == 0) {
        PPIsBlockExecute(completeHandler, @[], @"", @[], @"");
        return;
    }

    OCGumboDocument *document = [[OCGumboDocument alloc] initWithHTMLString:htmlString];

    NSMutableArray *urls = [NSMutableArray array];
    NSMutableArray *suggesM = [NSMutableArray array];

    OCGumboElement *contentE;

    switch (sourceModel.sourceType) {
        case 1:{
            contentE = document.QueryClass(@"contents").firstObject;
        }
            break;
        case 2: {
            contentE = document.QueryClass(@"content").firstObject;
        }
            break;
        case 3: {
            contentE = document.QueryClass(@"contentme").firstObject;
        }
            break;
        case 5: {
            contentE = document.QueryClass(@"content").firstObject;
        }
            break;
        case 8: {
            contentE = document.QueryClass(@"photos").firstObject;
        }
            break;
        default:
            break;
    }

    OCQueryObject *es = contentE.Query(@"img");
    for (OCGumboElement *e in es) {
        NSString *src;
        switch (sourceModel.sourceType) {
            case 8: {
                src = e.attr(@"src");
                if (![src containsString:@"https://"]) {
                    continue;
                }
                src = [src stringByReplacingOccurrencesOfString:@"_600x0" withString:@""];
            }
                break;
            default:
                src = e.attr(@"src");
                break;
        }
        if (src.length > 0) {
            [urls addObject:src];
        }
    }

    OCGumboElement *nextE;

    switch (sourceModel.sourceType) {
        case 1:{
            nextE = document.QueryClass(@"pageart").firstObject;
        }
            break;
        case 2: {
            nextE = document.QueryClass(@"page-tag").firstObject;
        }
            break;
        case 3: {
            nextE = document.QueryClass(@"pag").firstObject;
        }
            break;
        case 5: {
            nextE = document.QueryClass(@"page-list").firstObject;
        }
            break;
        case 8: {
            nextE = document.QueryClass(@"pager").firstObject;
        }
            break;
        default:
            break;
    }

    NSString *nextPage = @"";
    if (nextE) {
        OCQueryObject *aEs = nextE.QueryElement(@"a");

        NSString *nextPageTitle = @"下一页";
        switch (sourceModel.sourceType) {
            case 3:
                nextPageTitle = @"Next >";
                break;
            default:
                break;
        }

        for (OCGumboElement *aE in aEs) {
            if ([aE.text() isEqualToString:nextPageTitle]) {
                nextPage = aE.attr(@"href");
                break;
            }
        }
    }

    if (nextPage.length > 0) {
        switch (sourceModel.sourceType) {
            case 1: {
                nextPage = [preNextUrl stringByReplacingOccurrencesOfString:preNextUrl.lastPathComponent withString:nextPage];
            }
                break;
            case 2: {
                nextPage = [preNextUrl stringByReplacingOccurrencesOfString:preNextUrl.lastPathComponent withString:nextPage];
            }
                break;
            case 3: {
                nextPage = [NSURL URLWithString:nextPage relativeToURL:[NSURL URLWithString:sourceModel.HOST_URL]].absoluteString;
            }
                break;
            case 5: {
                nextPage = [NSURL URLWithString:nextPage relativeToURL:[NSURL URLWithString:preNextUrl]].absoluteString;
            }
                break;
            case 8: {
                nextPage = [NSURL URLWithString:nextPage relativeToURL:[NSURL URLWithString:sourceModel.HOST_URL]].absoluteString;
            }
                break;
            default:
                break;
        }
    } else {
        nextPage = @"";
    }

    NSString *contentTitle = [self parsePageForTitleWithDocument:document sourceModel:sourceModel];

    if (!needSuggest) {
        PPIsBlockExecute(completeHandler, urls, nextPage, suggesM, contentTitle);
        return;
    }

    switch (sourceModel.sourceType) {
        case 1: {

            // 推荐
            OCGumboElement *listDiv = document.QueryClass(@"w980").firstObject;
            OCQueryObject *articleEs = listDiv.QueryClass(@"post");

            for (OCGumboElement *articleE in articleEs) {

                PicContentModel *contentModel = [self getContentModelWithSourceModel:sourceModel withArticleElement:articleE];

                [contentModel insertTable];
                [suggesM addObject:contentModel];
            }
        }
            break;
        case 2: {

            // 推荐
            OCGumboElement *listDiv = document.QueryClass(@"articleV4PicList").firstObject;
            OCQueryObject *articleEs = listDiv.QueryElement(@"li");

            for (OCGumboElement *articleE in articleEs) {

                PicContentModel *contentModel = [self getContentModelWithSourceModel:sourceModel withArticleElement:articleE];

                [contentModel insertTable];
                [suggesM addObject:contentModel];
            }
        }
            break;
        case 3: {

            // 推荐
            OCGumboElement *listDiv = document.QueryClass(@"videos").firstObject;
            OCQueryObject *articleEs = listDiv.QueryClass(@"thcovering-video");

            for (OCGumboElement *articleE in articleEs) {

                PicContentModel *contentModel = [self getContentModelWithSourceModel:sourceModel withArticleElement:articleE];

                [contentModel insertTable];
                [suggesM addObject:contentModel];
            }
        }
            break;
        case 5: {

            // 推荐
            OCQueryObject *listDivs = document.QueryClass(@"list");

            for (OCGumboElement *listDivE in listDivs) {

                OCQueryObject *articleEs = listDivE.QueryClass(@"piece");

                for (OCGumboElement *articleE in articleEs) {

                    PicContentModel *contentModel = [self getContentModelWithSourceModel:sourceModel withArticleElement:articleE];

                    [contentModel insertTable];
                    [suggesM addObject:contentModel];
                }
            }
        }
            break;
        default:
            break;
    }

    PPIsBlockExecute(completeHandler, urls, nextPage, suggesM, contentTitle);

}

+ (NSString *)parsePageForTitleWithDocument:(OCGumboDocument *)document sourceModel:(PicSourceModel *)sourceModel {

    NSString *title = @"";

    switch (sourceModel.sourceType) {
//        case 1: {
//            OCGumboElement *divE = document.QueryClass(@"Title9").firstObject;
//            OCGumboElement *h9E = divE.childNodes.firstObject;
//            title = h9E.text();
//        }
//            break;
//        case 2: {
//            OCGumboElement *h1E = document.QueryClass(@"articleV4Tit").firstObject;
//            title = h1E.text();
//        }
//            break;
        case 3: {
            OCGumboElement *headE = document.QueryElement(@"head").firstObject;
            OCGumboElement *titleE = headE.QueryElement(@"title").firstObject;
            if (titleE) {
                NSString *title1 = titleE.text();
                // title1 => "Hit-x-Hot: Vol. 4832 可乐Vicky | Page 1/5"
                if ([title1 containsString:@" | Page"]) {
                    NSString *regex = @"(?<= Hit-x-Hot: ).*?(?= | Page)";
                    NSError *error;
                    NSRegularExpression *regular = [NSRegularExpression regularExpressionWithPattern:regex options:NSRegularExpressionCaseInsensitive error:&error];
                    // 对str字符串进行匹配
                    NSString *title2 = [title1 substringWithRange:[regular firstMatchInString:title1 options:0 range:NSMakeRange(0, title1.length)].range];
                    title = title2;
                } else {
                    title = [title1 stringByReplacingOccurrencesOfString:@" Hit-x-Hot: " withString:@""];
                }

            }
        }
            break;
        case 5: {
            OCGumboElement *containerE = document.QueryClass(@"container").firstObject;
            OCGumboElement *titleE = containerE.QueryElement(@"h2").firstObject;
            title = titleE.text();
        }
        case 8: {
            OCGumboElement *breadcrumbE = document.QueryClass(@"breadcrumb").firstObject;
            OCGumboElement *aEs = breadcrumbE.QueryElement(@"a").lastObject;
            title = aEs.text();
        }
        default:
            break;
    }

    return title;
}

+ (NSString *)parsePageForTitle:(NSString *)htmlString sourceModel:(PicSourceModel *)sourceModel {

    NSString *title = @"";
    if (htmlString.length > 0) {

        OCGumboDocument *document = [[OCGumboDocument alloc] initWithHTMLString:htmlString];
        title = [self parsePageForTitleWithDocument:document sourceModel:sourceModel];
    }

    return title ?: @"";
}

@end
