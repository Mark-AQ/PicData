//
//  PicContentModel.h
//  PicData
//
//  Created by Garenge on 2020/4/19.
//  Copyright © 2020 garenge. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PicContentModel : PicBaseModel///<JKSqliteProtocol>

@property (nonatomic, strong) NSString *sourceTitle;
@property (nonatomic, strong) NSString *thumbnailUrl;
@property (nonatomic, strong) NSString *href;

/// 任务是否已经添加
@property (nonatomic, assign) int hasAdded;
/// 该任务下一共有多少图片
@property (nonatomic, assign) int totalCount;
/// 已下载多少张, 这个属性忽略, 不存数据库
@property (nonatomic, assign) int downloadedCount;

/// 取消已添加任务, 根据父级title
+ (BOOL)unAddALLWithSourceTitle:(NSString *)sourceTitle;
    /// 取消已添加任务
+ (BOOL)unAddALL;

+ (NSArray *)queryTableWithHref:(NSString *)href;
+ (NSArray *)queryTableWithHref:(NSString *)href;

+ (NSArray *)queryTableWhereHasAdded;
/// 获取是否已添加任务
+ (NSArray *)queryTableWhereHasAddedWithHref:(NSString *)href;
@end

NS_ASSUME_NONNULL_END
