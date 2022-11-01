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
            
    NSView *view;
        
    BOOL createLeadingConstraintToSuperview;
    
    BOOL isVerticalOrientation;
}

-(instancetype)initWithFormat: (NSString*)format options: NSLayoutFormatOptions metrics: (NSDictionary*)metrics views: (NSDictionary*)views
{
    if (self = [super init]) {
        if ([format length] == 0) {
            [self failParseWithMessage:@"It's an empty string."];
        }
        
        self.views = views;
        self.metrics = metrics;
        
        scanner = [NSScanner scannerWithString:format];
        constraints = [NSMutableArray array];
    }
    
    return self;
}

-(NSArray*)parse
{
    [self parseOrientation];
    NSNumber *spacingConstant = [self parseLeadingSuperViewConnection];
    NSView *previousView;

    while (![scanner isAtEnd]) {
        NSArray *viewConstraints = [self parseView];
        if (createLeadingConstraintToSuperview) {
            [self addLeadingSuperviewConstraint: spacingConstant];
            createLeadingConstraintToSuperview = NO;
        }
             
        if (previousView) {
            [self addViewSpacingConstraint:spacingConstant previousView:previousView];
        }
        [constraints addObjectsFromArray:viewConstraints];
        
        spacingConstant = [self parseConnection];
        if ([scanner scanString:@"|" intoString:nil]) {
            [self addTrailingToSuperviewConstraint: spacingConstant];
        }
        previousView = view;
    }
    return constraints;
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

-(void)addViewSpacingConstraint: (NSNumber*)spacing previousView: (NSView*)previousView
{
    CGFloat viewSpacingConstant = spacing ? [spacing doubleValue] : GS_DEFAULT_VIEW_SPACING;
    NSLayoutAttribute firstAttribute = isVerticalOrientation ? NSLayoutAttributeTop : NSLayoutAttributeLeading;
    NSLayoutAttribute secondAttribute = isVerticalOrientation ? NSLayoutAttributeBottom : NSLayoutAttributeTrailing;
    NSLayoutConstraint *viewSeparatorConstraint = [NSLayoutConstraint constraintWithItem:view attribute:firstAttribute relatedBy:NSLayoutRelationEqual toItem:previousView attribute:secondAttribute multiplier:1.0 constant:viewSpacingConstant];

    [constraints addObject:viewSeparatorConstraint];
}

-(void)addLeadingSuperviewConstraint: (NSNumber*)spacing
{
    CGFloat viewSpacingConstant = spacing ? [spacing doubleValue] : GS_DEFAULT_SUPERVIEW_SPACING;
    NSLayoutAttribute firstAttribute = isVerticalOrientation ? NSLayoutAttributeTop : NSLayoutAttributeLeading;;

    NSLayoutConstraint *leadingConstraintToSuperview = [NSLayoutConstraint constraintWithItem:view attribute:firstAttribute relatedBy:NSLayoutRelationEqual toItem:view.superview attribute:firstAttribute multiplier:1.0 constant:viewSpacingConstant];
    [constraints addObject:leadingConstraintToSuperview];
}

-(void)addTrailingToSuperviewConstraint: (NSNumber*)spacing
{
    CGFloat viewSpacingConstant = spacing ? [spacing doubleValue] : GS_DEFAULT_SUPERVIEW_SPACING;
    NSLayoutAttribute attribute = isVerticalOrientation ? NSLayoutAttributeBottom : NSLayoutAttributeTrailing;;
    NSLayoutConstraint *trailingConstraintToSuperview = [NSLayoutConstraint constraintWithItem: view.superview  attribute:attribute relatedBy:NSLayoutRelationEqual toItem: view attribute:attribute multiplier:1.0 constant:viewSpacingConstant];
    [constraints addObject:trailingConstraintToSuperview];
}

-(NSNumber*)parseLeadingSuperViewConnection
{
    if (![scanner
         scanString:@"|" intoString:nil]) {
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
    CGFloat constant;
    BOOL scanConstantResult = [scanner scanDouble:&constant];
    if (scanConstantResult) {
        return [NSNumber numberWithDouble:constant];
    } else {
        NSString *metricName = [self parseMetricName];
        if (!metricName) {
            return nil;
        }
        NSNumber *metric = [self resolveMetricWithIdentifier:metricName];
        return metric;
    }
}

-(NSView*)parseViewName
{
    NSString *viewName = [self parseIdentifier];
    if (!viewName) {
        [self failParseWithMessage:@"Failed to parse view name"];
    }
    return [self resolveViewWithIdentifier:viewName];
}

-(NSArray*)parsePredicateList
{
    if (![scanner scanString:@"(" intoString:nil]) {
        return [NSArray array];
    }
    
    BOOL shouldParsePredicate = YES;
    
    NSMutableArray *viewPredicateConstraints = [NSMutableArray array];
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
    NSLayoutConstraint *constraint;
    NSLayoutAttribute attribute = isVerticalOrientation ? NSLayoutAttributeHeight : NSLayoutAttributeWidth;
    if (predicate->view) {
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
    NSView *predicatedView;
    BOOL scanConstantResult = [scanner scanDouble:&parsedConstant];
    if (!scanConstantResult) {
        NSString *identiferName = [self parseIdentifier];
        NSNumber *metric = [self.metrics objectForKey:identiferName];
        if (metric) {
            parsedConstant = [metric doubleValue];
        } else if ([self.views objectForKey:identiferName]) {
            parsedConstant = 0;
            predicatedView = [self.views objectForKey:identiferName];
        } else {
            [self failParseWithMessage:@"Failed to find constant or metric"];
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
    
    CGFloat constant = [self parseConstant];
    return [NSNumber numberWithDouble:constant];
}

-(void)failParseWithMessage: (NSString*)parseErrorMessage
{
    NSException *parseException = [NSException exceptionWithName:NSInvalidArgumentException reason:[NSString stringWithFormat:@"Unable to parse constraint format: %@", parseErrorMessage] userInfo:nil];
    [parseException raise];
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

-(CGFloat)parseConstant
{
    CGFloat constant;
    BOOL scanConstantResult = [scanner scanDouble:&constant];
    if (!scanConstantResult) {
        @try {
            NSString *metricName = [self parseIdentifier];
            NSNumber *metric = [self resolveMetricWithIdentifier:metricName];
            return [metric doubleValue];
        } @catch (id error) {
            [self failParseWithMessage:@"Failed to find constant or metric"];
        }
    }
    return constant;
}

-(NSString*)parseIdentifier
{
    NSString *identifier;
    [scanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&identifier];
    
    return identifier;
}

-(NSString*)parseMetricName
{
    NSString *identifier;
    [scanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&identifier];
    return identifier;
}

-(void)parseViewOpen
{
    NSCharacterSet *openViewIdentifier = [NSCharacterSet characterSetWithCharactersInString:@"["];
    NSString *character;
     BOOL scannedOpenBracket = [scanner scanCharactersFromSet:openViewIdentifier intoString:&character];
     if (!scannedOpenBracket) {
         [[NSException exceptionWithName:NSInternalInconsistencyException reason:@"A view must start with a '['" userInfo:nil] raise];
     }
}

-(void)parseViewClose
{
    NSCharacterSet *closeViewIdentifier = [NSCharacterSet characterSetWithCharactersInString:@"]"];
    NSString *character;
    BOOL scannedCloseBracket = [scanner scanCharactersFromSet:closeViewIdentifier intoString:&character];
    
    if (!scannedCloseBracket) {
        [[NSException exceptionWithName:NSInternalInconsistencyException reason:@"A view must end with a ']'" userInfo:nil] raise];
    }
}

-(void)freeObjectOfPredicate: (GSObjectOfPredicate*)predicate
{
    predicate->view = nil;
    predicate->priority = nil;
    free(predicate);
}

@end
