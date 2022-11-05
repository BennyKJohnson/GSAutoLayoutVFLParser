//
//  LayoutConstraint.m
//  GSAutoLayoutVFLParser
//
//  Created by Benjamin Johnson on 2/11/22.
//  Copyright © 2022 Benjamin Johnson. All rights reserved.
//

#import "LayoutConstraint.h"
#import "GSAutoLayoutVFLParser.h"

@implementation LayoutConstraint

+(NSArray*)constraintsWithVisualFormat:(NSString *)format options:(NSLayoutFormatOptions)opts metrics:(nullable NSDictionary<NSString *, id> *)metrics views:(NSDictionary<NSString *, id> *)views {
    
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:format options:opts metrics:metrics views:views];
    return [parser parse];
}

@end
