//
//  NSString+ChangeUnicode.m
//  PPToolSKYD
//
//  Created by 鹏鹏 on 2020/11/6.
//  Copyright © 2020 CleverPeng. All rights reserved.
//

#import "NSString+ChangeUnicode.h"

#import <objc/runtime.h>   // 导入运行时

@implementation NSObject (ChangeUnicode)

+(NSString *)stringByReplaceUnicode:(NSString *)string{

    NSMutableString *convertedString=[string mutableCopy];
    [convertedString replaceOccurrencesOfString:@"\\U" withString:@"\\u" options:0 range:NSMakeRange(0, convertedString.length)];
    CFStringRef transform=CFSTR("Any-Hex/Java");
    CFStringTransform((__bridge CFMutableStringRef)convertedString, NULL, transform, YES);
    return convertedString;
}
@end

@implementation NSArray (LengUnicode)

+ (void)load {
    method_exchangeImplementations(class_getInstanceMethod([self class], @selector(description)), class_getInstanceMethod([self class], @selector(replaceDescription)));
    method_exchangeImplementations(class_getInstanceMethod([self class], @selector(descriptionWithLocale:)), class_getInstanceMethod([self class], @selector(replaceDescriptionWithLocale:)));
    method_exchangeImplementations(class_getInstanceMethod([self class], @selector(descriptionWithLocale:indent:)), class_getInstanceMethod([self class], @selector(replaceDescriptionWithLocale:indent:)));
}

- (NSString *)replaceDescription {
    return [NSObject stringByReplaceUnicode:[self replaceDescription]];
}

- (NSString *)replaceDescriptionWithLocale:(nullable id)locale {
    return [NSObject stringByReplaceUnicode:[self replaceDescriptionWithLocale:locale]];
}

- (NSString *)replaceDescriptionWithLocale:(nullable id)locale indent:(NSUInteger)level {
    return [NSObject stringByReplaceUnicode:[self replaceDescriptionWithLocale:locale indent:level]];
}
@end

@implementation NSDictionary (LengUnicode)

+ (void)load {
    method_exchangeImplementations(class_getInstanceMethod([self class], @selector(description)), class_getInstanceMethod([self class], @selector(replaceDescription)));
    method_exchangeImplementations(class_getInstanceMethod([self class], @selector(descriptionWithLocale:)), class_getInstanceMethod([self class], @selector(replaceDescriptionWithLocale:)));
    method_exchangeImplementations(class_getInstanceMethod([self class], @selector(descriptionWithLocale:indent:)), class_getInstanceMethod([self class], @selector(replaceDescriptionWithLocale:indent:)));
}

- (NSString *)replaceDescription {
    return [NSObject stringByReplaceUnicode:[self replaceDescription]];
}

- (NSString *)replaceDescriptionWithLocale:(nullable id)locale {
    return [NSObject stringByReplaceUnicode:[self replaceDescriptionWithLocale:locale]];
}

- (NSString *)replaceDescriptionWithLocale:(nullable id)locale indent:(NSUInteger)level {
    return [NSObject stringByReplaceUnicode:[self replaceDescriptionWithLocale:locale indent:level]];
}
@end
