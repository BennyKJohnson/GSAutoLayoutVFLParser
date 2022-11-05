//
//  LayoutConstraint.h
//  GSAutoLayoutVFLParser
//
//  Created by Benjamin Johnson on 2/11/22.
//  Copyright © 2022 Benjamin Johnson. All rights reserved.
//

#import <AppKit/AppKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LayoutConstraint : NSObject

+(NSArray*)constraintsWithVisualFormat:(NSString *)format options:(NSLayoutFormatOptions)opts metrics:(nullable NSDictionary<NSString *, id> *)metrics views:(NSDictionary<NSString *, id> *)views;

@end

NS_ASSUME_NONNULL_END
