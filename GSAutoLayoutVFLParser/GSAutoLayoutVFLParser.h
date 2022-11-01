//
//  GSAutoLayoutVFLParser.h
//  GSAutoLayoutVFLParser
//
//  Created by Benjamin Johnson on 30/10/22.
//  Copyright © 2022 Benjamin Johnson. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GSAutoLayoutVFLParser : NSObject

@property (nonatomic, strong) NSDictionary *views;

@property (nonatomic, strong) NSDictionary *metrics;

-(instancetype)initWithFormat: (NSString*)format options: NSLayoutFormatOptions metrics: (NSDictionary*)metrics views: (NSDictionary*)views;

-(NSArray*)parse;

@end
