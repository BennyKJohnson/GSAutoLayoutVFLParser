//
//  GSAutoLayoutVFLParser.h
//  GSAutoLayoutVFLParser
//
//  Created by Benjamin Johnson on 30/10/22.
//  Copyright © 2022 Benjamin Johnson. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface GSAutoLayoutVFLParser : NSObject

@property (nonatomic, strong) NSDictionary *views;

@property (nonatomic, strong) NSDictionary *metrics;

@property (nonatomic) NSLayoutFormatOptions options;

-(instancetype)initWithFormat: (NSString*)format options: (NSLayoutFormatOptions)options metrics: (NSDictionary*)metrics views: (NSDictionary*)views;

-(NSArray*)parse;

@end

