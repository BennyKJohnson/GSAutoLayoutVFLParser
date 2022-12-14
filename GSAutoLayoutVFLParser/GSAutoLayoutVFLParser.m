#import "GSAutoLayoutVFLParser.h"
#import <AppKit/AppKit.h>

struct GSObjectOfPredicate {
    NSNumber *priority;
    NSView *view;
    NSLayoutRelation relation;
    CGFloat constant;
};
typedef struct GSObjectOfPredicate GSObjectOfPredicate;

NSInteger const GS_DEFAULT_VIEW_SPACING = 8;
NSInteger const GS_DEFAULT_SUPERVIEW_SPACING = 20;

@implementation GSAutoLayoutVFLParser
{
    NSScanner *scanner;
    
    NSMutableArray *constraints;
    
    NSMutableArray *layoutFormatConstraints;
            
    NSView *view;
        
    BOOL createLeadingConstraintToSuperview;
    
    BOOL isVerticalOrientation;
        
    NSLayoutFormatOptions formatOptions;
}

-(instancetype)initWithFormat: (NSString*)format options: (NSLayoutFormatOptions)options metrics: (NSDictionary*)metrics views: (NSDictionary*)views
{
    if (self = [super init]) {
        if ([format length] == 0) {
            [self failParseWithMessage:@"Cannot parse an empty string"];
        }
        
        self.views = views;
        self.metrics = metrics;
        self.options = options;
        
        scanner = [NSScanner scannerWithString:format];
        constraints = [NSMutableArray array];
        layoutFormatConstraints = [NSMutableArray array];
    }
    
    return self;
}

-(NSArray*)parse
{
    [self parseOrientation];
    NSNumber *spacingConstant = [self parseLeadingSuperViewConnection];
    NSView *previousView = nil;

    while (![scanner isAtEnd]) {
        NSArray *viewConstraints = [self parseView];
        if (createLeadingConstraintToSuperview) {
            [self addLeadingSuperviewConstraint: spacingConstant];
            createLeadingConstraintToSuperview = NO;
        }
             
        if (previousView != nil) {
            [self addViewSpacingConstraint:spacingConstant previousView:previousView];
            [self addFormattingConstraints: previousView];
        }
        [constraints addObjectsFromArray:viewConstraints];
        
        spacingConstant = [self parseConnection];
        if ([scanner scanString:@"|" intoString:nil]) {
            [self addTrailingToSuperviewConstraint: spacingConstant];
        }
        previousView = view;
    }
    
    [constraints addObjectsFromArray:layoutFormatConstraints];
        
    return constraints;
}

-(void)addFormattingConstraints: (NSView*)lastView
{
    BOOL hasFormatOptions = (self.options & NSLayoutFormatAlignmentMask) > 0;
    if (!hasFormatOptions) {
         return;
     }
    [self assertHasValidFormatLayoutOptions];
    
    NSArray *attributes = [self layoutAttributesForLayoutFormatOptions:self.options];
    for (NSNumber *layoutAttribute in attributes) {
        NSLayoutConstraint *formatConstraint = [NSLayoutConstraint constraintWithItem:lastView  attribute:[layoutAttribute integerValue] relatedBy:NSLayoutRelationEqual toItem:view attribute:[layoutAttribute integerValue] multiplier:1.0 constant:0];
        [layoutFormatConstraints addObject:formatConstraint];
    }
}

-(void)assertHasValidFormatLayoutOptions
{
    if (isVerticalOrientation && [self isVerticalEdgeFormatLayoutOption: self.options]) {
        [self failParseWithMessage:@"A vertical alignment format option cannot be used with a vertical layout"];
    } else if (!isVerticalOrientation && ![self isVerticalEdgeFormatLayoutOption:self.options]) {
        [self failParseWithMessage:@"A horizontal alignment format option cannot be used with a horizontal layout"];
    }
}
         
-(void)parseOrientation
{
    if ([scanner scanString:@"V:" intoString:nil]) {
        isVerticalOrientation = true;
    } else {
        [scanner scanString:@"H:" intoString:nil];
    }
}

-(NSArray*)parseView
{
    [self parseViewOpen];
    
    view = [self parseViewName];
    NSArray *viewConstraints = [self parsePredicateList];
    [self parseViewClose];
    
    return viewConstraints;
}

-(NSView*)parseViewName
{
    NSString *viewName = nil;
    NSCharacterSet *viewTerminators = [NSCharacterSet characterSetWithCharactersInString:@"]("];
    [scanner scanUpToCharactersFromSet:viewTerminators intoString:&viewName];
        
    if (viewName == nil) {
        [self failParseWithMessage:@"Failed to parse view name"];
    }
    
    if (![self isValidIdentifer:viewName]) {
        [self failParseWithMessage:@"Invalid view name. A view name must be a valid C identifier and may only contain letters, numbers and underscores"];
    }
    
    return [self resolveViewWithIdentifier:viewName];
}

-(BOOL)isVerticalEdgeFormatLayoutOption: (NSLayoutFormatOptions)options
{
    if (options & NSLayoutFormatAlignAllTop) {
        return YES;
    }
    if (options & NSLayoutFormatAlignAllBaseline) {
        return YES;
    }
    if (options & NSLayoutFormatAlignAllFirstBaseline) {
        return YES;
    }
    if (options & NSLayoutFormatAlignAllBottom) {
        return YES;
    }
    if (options & NSLayoutFormatAlignAllCenterY) {
        return YES;
    }
    
    return NO;
}

-(void)addViewSpacingConstraint: (NSNumber*)spacing previousView: (NSView*)previousView
{
    CGFloat viewSpacingConstant = spacing ? [spacing doubleValue] : GS_DEFAULT_VIEW_SPACING;
    NSLayoutAttribute firstAttribute;
    NSLayoutAttribute secondAttribute;
    NSView *firstItem;
    NSView *secondItem;
    
    NSLayoutFormatOptions directionOptions = self.options & NSLayoutFormatDirectionMask;
    if (isVerticalOrientation) {
        firstAttribute = NSLayoutAttributeTop;
        secondAttribute = NSLayoutAttributeBottom;
        firstItem = view;
        secondItem = previousView;
    } else if (directionOptions & NSLayoutFormatDirectionRightToLeft) {
        firstAttribute = NSLayoutAttributeLeft;
        secondAttribute = NSLayoutAttributeRight;
        firstItem = previousView;
        secondItem = view;
    } else if (directionOptions & NSLayoutFormatDirectionLeftToRight) {
        firstAttribute = NSLayoutAttributeLeft;
         secondAttribute = NSLayoutAttributeRight;
         firstItem = view;
         secondItem = previousView;
    } else {
        firstAttribute = NSLayoutAttributeLeading;
        secondAttribute = NSLayoutAttributeTrailing;
        firstItem = view;
        secondItem = previousView;
    }
    
    NSLayoutConstraint *viewSeparatorConstraint = [NSLayoutConstraint constraintWithItem:firstItem attribute:firstAttribute relatedBy:NSLayoutRelationEqual toItem:secondItem attribute:secondAttribute multiplier:1.0 constant:viewSpacingConstant];

    [constraints addObject:viewSeparatorConstraint];
}

-(void)addLeadingSuperviewConstraint: (NSNumber*)spacing
{
    NSLayoutAttribute firstAttribute;
    NSView *firstItem;
    NSView *secondItem;

    NSLayoutFormatOptions directionOptions = self.options & NSLayoutFormatDirectionMask;
    if (isVerticalOrientation) {
        firstAttribute = NSLayoutAttributeTop;
        firstItem = view;
        secondItem = view.superview;
    } else if (directionOptions & NSLayoutFormatDirectionRightToLeft) {
        firstAttribute = NSLayoutAttributeRight;
        firstItem = view.superview;
        secondItem = view;
    } else if (directionOptions & NSLayoutFormatDirectionLeftToRight) {
        firstAttribute = NSLayoutAttributeLeft;
        firstItem = view;
        secondItem = view.superview;
    } else {
        firstAttribute = isVerticalOrientation ? NSLayoutAttributeTop : NSLayoutAttributeLeading;
        firstItem = view;
        secondItem = view.superview;
    }
    
    CGFloat viewSpacingConstant = spacing ? [spacing doubleValue] : GS_DEFAULT_SUPERVIEW_SPACING;

    NSLayoutConstraint *leadingConstraintToSuperview = [NSLayoutConstraint constraintWithItem:firstItem attribute:firstAttribute relatedBy:NSLayoutRelationEqual toItem:secondItem attribute:firstAttribute multiplier:1.0 constant:viewSpacingConstant];
    [constraints addObject:leadingConstraintToSuperview];
}

-(void)addTrailingToSuperviewConstraint: (NSNumber*)spacing
{
    CGFloat viewSpacingConstant = spacing ? [spacing doubleValue] : GS_DEFAULT_SUPERVIEW_SPACING;
    
    NSLayoutFormatOptions directionOptions = self.options & NSLayoutFormatDirectionMask;
    NSLayoutAttribute attribute;
    NSView *firstItem;
    NSView *secondItem;
    
    if (isVerticalOrientation) {
        attribute = NSLayoutAttributeBottom;
        firstItem = view.superview;
        secondItem = view;
    } else if (directionOptions & NSLayoutFormatDirectionRightToLeft) {
        attribute = NSLayoutAttributeLeft;
        firstItem = view;
        secondItem = view.superview;
    } else if (directionOptions & NSLayoutFormatDirectionLeftToRight) {
        attribute = NSLayoutAttributeRight;
        firstItem =  view.superview;
        secondItem = view;
    } else {
        attribute = NSLayoutAttributeTrailing;
        firstItem = view.superview;
        secondItem = view;
    }
    
    NSLayoutConstraint *trailingConstraintToSuperview = [NSLayoutConstraint constraintWithItem: firstItem  attribute:attribute relatedBy:NSLayoutRelationEqual toItem: secondItem attribute:attribute multiplier:1.0 constant:viewSpacingConstant];
    [constraints addObject:trailingConstraintToSuperview];
}

-(NSNumber*)parseLeadingSuperViewConnection
{
    BOOL foundSuperview = [scanner scanString:@"|" intoString:nil];
    if (!foundSuperview) {
        return nil;
    }
    createLeadingConstraintToSuperview = YES;
    return [self parseConnection];
}

-(NSNumber*)parseConnection
{
    BOOL foundConnection = [scanner scanString:@"-" intoString:nil];
    if (!foundConnection) {
        return [NSNumber numberWithDouble:0];
    }

    NSNumber *simplePredicateValue = [self parseSimplePredicate];
    BOOL endConnectionFound = [scanner scanString:@"-" intoString:nil];

    if (simplePredicateValue != nil && !endConnectionFound) {
        [self failParseWithMessage:@"A connection must end with a '-'"];
    } else if (simplePredicateValue == nil && endConnectionFound) {
        [self failParseWithMessage:@"Found invalid connection"];
    }

    return simplePredicateValue;
}

-(NSNumber*)parseSimplePredicate
{
    float constant;
    BOOL scanConstantResult = [scanner scanFloat:&constant];
    if (scanConstantResult) {
        return [NSNumber numberWithDouble:constant];
    } else {
        NSString *metricName = nil;
        NSCharacterSet *simplePredicateTerminatorsCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"-[|"];
        BOOL didParseMetricName = [scanner scanUpToCharactersFromSet:simplePredicateTerminatorsCharacterSet intoString:&metricName];
        if (!didParseMetricName) {
            return nil;
        }
        if (![self isValidIdentifer:metricName]) {
            [self failParseWithMessage:@"Invalid metric identifier. Metric identifiers must be a valid C identifier and may only contain letters, numbers and underscores"];
        }
        
        NSNumber *metric = [self resolveMetricWithIdentifier:metricName];
        return metric;
    }
}

-(NSArray*)parsePredicateList
{
    BOOL startsWithPredicateList = [scanner scanString:@"(" intoString:nil];
    if (!startsWithPredicateList) {
        return [NSArray array];
    }
        
    NSMutableArray *viewPredicateConstraints = [NSMutableArray array];
    BOOL shouldParsePredicate = YES;
    while (shouldParsePredicate) {
        GSObjectOfPredicate *predicate = [self parseObjectOfPredicate];
        [viewPredicateConstraints addObject:[self createConstraintFromParsedPredicate:predicate]];
        [self freeObjectOfPredicate:predicate];
        
        shouldParsePredicate = [scanner scanString:@"," intoString:nil];
    }
    
    if (![scanner scanString:@")" intoString:nil]) {
        [self failParseWithMessage:@"A predicate on a view must end with ')'"];
    }
    
    return viewPredicateConstraints;
}

-(NSLayoutConstraint*)createConstraintFromParsedPredicate: (GSObjectOfPredicate*)predicate
{
    NSLayoutConstraint *constraint = nil;
    NSLayoutAttribute attribute = isVerticalOrientation ? NSLayoutAttributeHeight : NSLayoutAttributeWidth;
    if (predicate->view != nil) {
        constraint = [NSLayoutConstraint constraintWithItem:view attribute:attribute relatedBy:predicate->relation toItem:predicate->view attribute:attribute multiplier:1.0 constant:predicate->constant];
    } else {
        constraint = [NSLayoutConstraint constraintWithItem:view attribute:attribute relatedBy:predicate->relation toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:predicate->constant];
    }

     if (predicate->priority) {
         constraint.priority = [predicate->priority doubleValue];
     }
    
    return constraint;
}

-(GSObjectOfPredicate*)parseObjectOfPredicate
{
    NSLayoutRelation relation = [self parseRelation];
    
    CGFloat parsedConstant;
    NSView *predicatedView = nil;
    BOOL scanConstantResult = [scanner scanDouble:&parsedConstant];
    if (!scanConstantResult) {
        NSString *identiferName = [self parseIdentifier];
        if (![self isValidIdentifer:identiferName]) {
            [self failParseWithMessage:@"Invalid metric or view identifier. Metric/View identifiers must be a valid C identifier and may only contain letters, numbers and underscores"];
        }
        
        NSNumber *metric = [self.metrics objectForKey:identiferName];
        if (metric != nil) {
            parsedConstant = [metric doubleValue];
        } else if ([self.views objectForKey:identiferName]) {
            parsedConstant = 0;
            predicatedView = [self.views objectForKey:identiferName];
        } else {
            NSString *message = [NSString stringWithFormat:@"Failed to find constant or metric for identifier '%@'", identiferName];
            [self failParseWithMessage:message];
        }
    }
    
    NSNumber *priorityValue = [self parsePriority];

    GSObjectOfPredicate *predicate = calloc(1, sizeof(GSObjectOfPredicate));
    predicate->priority = priorityValue;
    predicate->relation = relation;
    predicate->constant = parsedConstant;
    predicate->view = predicatedView;
    
    return predicate;
}

-(NSLayoutRelation)parseRelation
{
    if ([scanner scanString:@"==" intoString:nil]) {
        return NSLayoutRelationEqual;
    } else if ([scanner scanString:@">=" intoString:nil]) {
        return NSLayoutRelationGreaterThanOrEqual;
    } else if ([scanner scanString:@"<=" intoString:nil]) {
        return NSLayoutRelationLessThanOrEqual;
    } else {
        return NSLayoutRelationEqual;
    }
}

-(NSNumber*)parsePriority
{
    NSCharacterSet *priorityMarkerCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"@"];
    BOOL foundPriorityMarker = [scanner scanCharactersFromSet:priorityMarkerCharacterSet intoString:nil];
    if (!foundPriorityMarker) {
        return nil;
    }
    
    return [self parseConstant];
}

-(NSNumber*)resolveMetricWithIdentifier: (NSString*)identifier
{
    NSNumber *metric = [self.metrics objectForKey:identifier];
    if (metric == nil) {
        [self failParseWithMessage:@"Found metric not inside metric dictionary"];
    }
    return metric;
}

-(NSView*)resolveViewWithIdentifier: (NSString*)identifier
{
    NSView *view = [self.views objectForKey:identifier];
    if (view == nil) {
        [self failParseWithMessage:@"Found view not inside view dictionary"];
    }
    return view;
}

-(NSNumber*)parseConstant
{
    CGFloat constant;
    BOOL scanConstantResult = [scanner scanDouble:&constant];
    if (scanConstantResult) {
        return [NSNumber numberWithFloat:constant];
    }
    
    NSString *metricName = [self parseIdentifier];
    if (![self isValidIdentifer:metricName]) {
        [self failParseWithMessage:@"Invalid metric identifier. Metric identifiers must be a valid C identifier and may only contain letters, numbers and underscores"];
    }
    
    return [self resolveMetricWithIdentifier:metricName];
}

-(NSString*)parseIdentifier
{
    NSString *identifierName = nil;
    NSCharacterSet *identifierTerminators = [NSCharacterSet characterSetWithCharactersInString:@"),"];
    BOOL scannedIdentifier = [scanner scanUpToCharactersFromSet:identifierTerminators intoString:&identifierName];
    if (!scannedIdentifier) {
        [self failParseWithMessage:@"Failed to find constant or metric"];
    }
    
    return identifierName;
}

-(void)parseViewOpen
{
    NSCharacterSet *openViewIdentifier = [NSCharacterSet characterSetWithCharactersInString:@"["];
     BOOL scannedOpenBracket = [scanner scanCharactersFromSet:openViewIdentifier intoString:nil];
     if (!scannedOpenBracket) {
         [[NSException exceptionWithName:NSInternalInconsistencyException reason:@"A view must start with a '['" userInfo:nil] raise];
     }
}

-(void)parseViewClose
{
    NSCharacterSet *closeViewIdentifier = [NSCharacterSet characterSetWithCharactersInString:@"]"];
    BOOL scannedCloseBracket = [scanner scanCharactersFromSet:closeViewIdentifier intoString:nil];
    if (!scannedCloseBracket) {
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:@"A view must end with a ']'" userInfo:nil] raise];
    }
}

-(BOOL)isValidIdentifer: (NSString*)identifer
{
    
    NSRegularExpression *cIdentifierRegex = [NSRegularExpression regularExpressionWithPattern:@"^[a-zA-Z_][a-zA-Z0-9_]*$" options:0 error:nil];
    NSArray *matches = [cIdentifierRegex matchesInString:identifer options:0 range:NSMakeRange(0, identifer.length)];
    
    return [matches count] > 0;
}

-(NSArray*)layoutAttributesForLayoutFormatOptions: (NSLayoutFormatOptions)options {
    NSMutableArray *attributes = [NSMutableArray array];
    
    if (options & NSLayoutFormatAlignAllLeft) {
        [attributes addObject:[NSNumber numberWithInteger:NSLayoutAttributeLeft]];
    }
    if (options & NSLayoutFormatAlignAllRight) {
        [attributes addObject:[NSNumber numberWithInteger:NSLayoutAttributeRight]];
    }
    if (options & NSLayoutFormatAlignAllTop) {
        [attributes addObject:[NSNumber numberWithInteger:NSLayoutAttributeTop]];
    }
    if (options & NSLayoutFormatAlignAllBottom) {
        [attributes addObject:[NSNumber numberWithInteger:NSLayoutAttributeBottom]];
    }
    if (options & NSLayoutFormatAlignAllLeading) {
        [attributes addObject:[NSNumber numberWithInteger:NSLayoutAttributeLeading]];
    }
    if (options & NSLayoutFormatAlignAllTrailing) {
        [attributes addObject:[NSNumber numberWithInteger:NSLayoutAttributeTrailing]];
    }
    if (options & NSLayoutFormatAlignAllCenterX) {
        [attributes addObject:[NSNumber numberWithInteger:NSLayoutAttributeCenterX]];
    }
    if (options & NSLayoutFormatAlignAllCenterY) {
        [attributes addObject:[NSNumber numberWithInteger:NSLayoutAttributeCenterY]];
    }
    if (options & NSLayoutFormatAlignAllBaseline) {
        [attributes addObject:[NSNumber numberWithInteger:NSLayoutAttributeBaseline]];
    }
    if (options & NSLayoutFormatAlignAllFirstBaseline) {
        [attributes addObject:[NSNumber numberWithInteger:NSLayoutAttributeFirstBaseline]];
    }
    
    if ([attributes count] == 0) {
        [self failParseWithMessage:@"Unrecognized layout formatting option"];
    }
    
    return attributes;
}

-(void)failParseWithMessage: (NSString*)parseErrorMessage
{
    NSException *parseException = [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Unable to parse constraint format: %@", parseErrorMessage] userInfo:nil];
    [parseException raise];
}


-(void)freeObjectOfPredicate: (GSObjectOfPredicate*)predicate
{
    predicate->view = nil;
    predicate->priority = nil;
    free(predicate);
}

@end
