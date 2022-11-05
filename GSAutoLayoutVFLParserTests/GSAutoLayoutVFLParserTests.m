#import <XCTest/XCTest.h>
#import <GSAutoLayoutVFLParser/GSAutoLayoutVFLParser.h>

@interface GSAutoLayoutVFLParserTests : XCTestCase

@end

@implementation GSAutoLayoutVFLParserTests
{
    NSView *view1;
    NSView *view2;
    NSDictionary *twoViewsMap;
    
    NSView *superview;
    NSView *find;
    NSView *findNext;
    NSView *findField;
    
}

- (void)setUp {
    view1 = [[NSView alloc] init];
    view2 = [[NSView alloc] init];
    twoViewsMap = @{
        @"view1": view1,
        @"view2": view2
    };
    
    superview = [[NSView alloc] init];
    find = [[NSView alloc] init];
    findNext = [[NSView alloc] init];
    findField = [[NSView alloc] init];
    [superview addSubview:find];
    [superview addSubview:findNext];
    [superview addSubview:findField];
}

-(void)assertConstraint: (NSLayoutConstraint*)constraint equalsConstraint: (NSLayoutConstraint*)expectedConstraint
{
    XCTAssertEqual([constraint firstAttribute], expectedConstraint.firstAttribute);
    XCTAssertEqual([constraint secondAttribute], expectedConstraint.secondAttribute);
    XCTAssertEqual([constraint firstItem], [expectedConstraint firstItem]);
    XCTAssertEqual([constraint secondItem], [expectedConstraint secondItem]);
    XCTAssertEqual([constraint multiplier], [expectedConstraint multiplier]);
    XCTAssertEqual([constraint constant], [expectedConstraint constant]);
    XCTAssertEqual([constraint priority], [expectedConstraint priority]);
    XCTAssertEqual([constraint relation], [expectedConstraint relation]);
}

-(void)testThrowsExceptionWhenInitializingWithEmptyString
{
    XCTAssertThrowsSpecificNamed([[GSAutoLayoutVFLParser alloc] initWithFormat:@"" options:0 metrics:nil views:nil], NSException, NSInvalidArgumentException);
}

-(void)testCanParseWithView
{
    NSView *view = [[NSView alloc] init];
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:@"[view]" options:0 metrics:@{} views:@{@"view": view}];
    NSArray *constraints = [parser parse];
    XCTAssertEqual([constraints count], 0);
}

-(void)testThrowsExceptionIfViewReferencedInStringIsNotFoundInViewDictionary
{
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:@"[button]" options:0 metrics:@{} views:@{}];
    XCTAssertThrowsSpecificNamed([parser parse], NSException, NSInvalidArgumentException);
}

-(void)testCanParseViewWithWidthPredicate
{
    NSView *view = [[NSView alloc] init];
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:@"[view(50)]" options:0 metrics:@{} views:@{@"view": view}];
    NSArray *constraints = [parser parse];
    XCTAssertEqual([constraints count], 1);
    
    NSLayoutConstraint *expectedWidthConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:50];
    
    [self assertConstraint:constraints[0] equalsConstraint:expectedWidthConstraint];
}

-(void)performRelationTestWithFormat: (NSString*)format expectedRelation: (NSLayoutRelation)relation
{
    NSView *view = [[NSView alloc] init];
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:format options:0 metrics:nil views:@{@"view": view}];
    NSArray *constraints = [parser parse];
    XCTAssertEqual([constraints count], 1);
    
    NSLayoutConstraint *expectedWidthConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:relation toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:50];
    
    [self assertConstraint:constraints[0] equalsConstraint:expectedWidthConstraint];
}

-(void)testCanParseViewWithWidthPredicateAndEqualRelation
{
    [self performRelationTestWithFormat:@"[view(==50)]" expectedRelation:NSLayoutRelationEqual];
}

-(void)testCanParseViewWithWidthPredicateAndGreaterThanOrEqualRelation
{
    [self performRelationTestWithFormat:@"[view(>=50)]" expectedRelation:NSLayoutRelationGreaterThanOrEqual];
}

-(void)testCanParseViewWithWidthPredicateAndLessThanOrEqualRelation
{
    [self performRelationTestWithFormat:@"[view(<=50)]" expectedRelation:NSLayoutRelationLessThanOrEqual];
}

//-(void)testCanParseMultipleViewPredicates
//{
//    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:@"[view1(>=70,<=100)]" options:0 metrics:nil views:@{@"view1": view1}];
//    NSArray *constraints = [parser parse];
//    XCTAssertEqual([constraints count], 2);
//    
//    NSLayoutConstraint *expectedGTEWidthConstraint = [NSLayoutConstraint constraintWithItem:view1 attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:70];
//    
//    NSLayoutConstraint *expectedLTEWidthConstraint =
//    [NSLayoutConstraint constraintWithItem:view1 attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:100];
//    
//    [self assertConstraint:constraints[0] equalsConstraint:expectedGTEWidthConstraint];
//    [self assertConstraint:constraints[1] equalsConstraint:expectedLTEWidthConstraint];
//}


-(void)testCanParseViewWithWidthMetricPredicate
{
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:@"[view1(viewWidth)]" options:0 metrics:@{
        @"viewWidth": [NSNumber numberWithDouble:50]
    } views:@{@"view1": view1}];
    NSArray *constraints = [parser parse];
    XCTAssertEqual([constraints count], 1);
    
    NSLayoutConstraint *expectedWidthConstraint = [NSLayoutConstraint constraintWithItem:view1 attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:50];
    
    [self assertConstraint:constraints[0] equalsConstraint:expectedWidthConstraint];
}

-(void)testCanParsePredicateWithPriority
{
    NSView *view = [[NSView alloc] init];
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:@"[view(50@500)]" options:0 metrics:@{} views:@{@"view": view}];
    NSArray *constraints = [parser parse];
    XCTAssertEqual([constraints count], 1);
    NSLayoutConstraint *expectedWidthConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:50];
    expectedWidthConstraint.priority = 500;
    [self assertConstraint:constraints[0] equalsConstraint:expectedWidthConstraint];
}

-(void)testCanParsePredicateWithPriorityMetric
{
    NSView *view = [[NSView alloc] init];
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:@"[view(50@priority)]" options:0 metrics:@{
        @"priority": [NSNumber numberWithInt:500]
    } views:@{@"view": view}];
    NSArray *constraints = [parser parse];
    XCTAssertEqual([constraints count], 1);
    NSLayoutConstraint *expectedWidthConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:50];
    expectedWidthConstraint.priority = 500;
    [self assertConstraint:constraints[0] equalsConstraint:expectedWidthConstraint];
}

-(void)testThrowsWhenMetricIsNotInMetricDictionary
{
    NSView *view = [[NSView alloc] init];
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:@"[view(missingMetric)]" options:0 metrics:nil views:@{@"view": view}];
    XCTAssertThrowsSpecificNamed([parser parse],NSException, NSInvalidArgumentException);
}

-(void)testThrowsWithoutViewPredicateCloseBracket
{
    NSView *view = [[NSView alloc] init];
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:@"[view(50]" options:0 metrics:nil views:@{@"view": view}];
    
    XCTAssertThrowsSpecificNamed([parser parse], NSException, NSInvalidArgumentException);
}

-(void)testThrowsWithoutViewPredicateConstantOrMetricKey
{
    NSView *view = [[NSView alloc] init];
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:@"[view()]" options:0 metrics:nil views:@{@"view": view}];
    
    XCTAssertThrowsSpecificNamed([parser parse], NSException, NSInvalidArgumentException);
}

-(void)testCanParseWithFlushViews
{
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:@"[view1][view2]" options:0 metrics:nil views: twoViewsMap];
    NSArray *constraints = [parser parse];
    XCTAssertEqual([constraints count], 1);
    
    NSLayoutConstraint *expectedFlushConstraint = [NSLayoutConstraint constraintWithItem:view2 attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:view1 attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0];
    
    [self assertConstraint:constraints[0] equalsConstraint:expectedFlushConstraint];
}

-(NSArray*)parseFormat: (NSString*)format
{
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:format options:0 metrics:@{} views:twoViewsMap];
    return [parser parse];
}

-(void)testThrowsErrorTryingToParseConnectionWithoutValidSimplePredicate
{
    XCTAssertThrowsSpecificNamed([self parseFormat:@"[view1]--[view2]"], NSException, NSInvalidArgumentException);
}

-(void)testCanParseWithStandardSpaceBetwenViews
{
    NSArray *constraints = [self parseFormat:@"[view1]-[view2]"];
    NSLayoutConstraint *expectedFlushConstraint = [NSLayoutConstraint constraintWithItem:view2 attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:view1 attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:8];
    
    XCTAssertEqual([constraints count], 1);
    [self assertConstraint:constraints[0] equalsConstraint:expectedFlushConstraint];
}

-(void)testCanParseWithSpaceBetweenViews
{
    NSArray *constraints = [self parseFormat:@"[view1]-10-[view2]"];
    XCTAssertEqual([constraints count], 1);
    
    NSLayoutConstraint *expectedFlushConstraint = [NSLayoutConstraint constraintWithItem:view2 attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:view1 attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:10];
    
    [self assertConstraint:constraints[0] equalsConstraint:expectedFlushConstraint];
}

-(void)testCanParseConnectionToSuperview
{
    NSView *superView = [[NSView alloc] init];
    NSView *view1 = [[NSView alloc] init];
    [superView addSubview:view1];
    
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:@"|-60-[view1]-50-|" options:0 metrics:@{} views:@{
        @"view1": view1,
    }];
    
    NSArray *constraints = [parser parse];
    
    NSLayoutConstraint *expectedLeadingConstraint = [NSLayoutConstraint constraintWithItem:view1 attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:superView
                                                                                 attribute:NSLayoutAttributeLeading multiplier:1.0 constant:60];
    
    NSLayoutConstraint *expectedTrailingConstraint = [NSLayoutConstraint constraintWithItem:superView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:view1
                                                                                  attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:50];
    
    XCTAssertEqual([constraints count], 2);
    
    [self assertConstraint:constraints[0] equalsConstraint:expectedLeadingConstraint];
    [self assertConstraint:constraints[1] equalsConstraint:expectedTrailingConstraint];
}

-(void)testCanParseWithVerticalOrientation
{
    NSArray *constraints = [self parseFormat:@"V:[view1]-10-[view2]"];
    XCTAssertEqual([constraints count], 1);
    NSLayoutConstraint *verticalSpacingConstraint = [NSLayoutConstraint constraintWithItem:view2 attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:view1 attribute:NSLayoutAttributeBottom multiplier:1.0 constant:10];
    [self assertConstraint:constraints[0] equalsConstraint:verticalSpacingConstraint];
}

-(void)testCanParseWithVerticalOrientationAndSuperview
{
    NSView *superview = [[NSView alloc] init];
    NSView *view = [[NSView alloc] init];
    [superview addSubview:view];
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:@"V:|-10-[view]-10-|" options:0 metrics:@{} views:@{
        @"view":view
    }];
    
    NSArray *constraints = [parser parse];
    
    XCTAssertEqual([constraints count], 2);
    NSLayoutConstraint *topSuperviewConstraint = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeTop multiplier:1.0 constant:10];
    NSLayoutConstraint *bottomSuperviewConstraint = [NSLayoutConstraint constraintWithItem:superview attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:10];
    
    [self assertConstraint:constraints[0] equalsConstraint:topSuperviewConstraint];
    [self assertConstraint:constraints[1] equalsConstraint:bottomSuperviewConstraint];
}

-(void)testCanParseWithHorizontalOrientation
{
    NSArray *constraints = [self parseFormat:@"H:[view1]-10-[view2]"];
    XCTAssertEqual([constraints count], 1);
    NSLayoutConstraint *verticalSpacingConstraint = [NSLayoutConstraint constraintWithItem:view2 attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:view1 attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:10];
    [self assertConstraint:constraints[0] equalsConstraint:verticalSpacingConstraint];
}

-(void)testCanParseWithEqualWidth
{
    NSArray *constraints = [self parseFormat:@"[view1(==view2)]"];
    XCTAssertEqual([constraints count], 1);
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:view1 attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:view2 attribute:NSLayoutAttributeWidth multiplier:1.0 constant:0];
    
    [self assertConstraint:constraints[0] equalsConstraint:widthConstraint];
}

-(void)testCanParseWithEqualHeight
{
    NSArray *constraints = [self parseFormat:@"V:[view1(==view2)]"];
    XCTAssertEqual([constraints count], 1);
    NSLayoutConstraint *widthConstraint = [NSLayoutConstraint constraintWithItem:view1 attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:view2 attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0];
    
    [self assertConstraint:constraints[0] equalsConstraint:widthConstraint];
}

-(void)testCanParseCompleteLineOfLayout
{
    NSView *superview = [[NSView alloc] init];
    NSView *find = [[NSView alloc] init];
    NSView *findNext = [[NSView alloc] init];
    NSView *findField = [[NSView alloc] init];
    
    [superview addSubview:find];
    [superview addSubview:findNext];
    [superview addSubview:findField];
    NSDictionary *views = @{
        @"find": find,
        @"findNext": findNext,
        @"findField": findField
    };
    
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:@"|-[find]-[findNext]-[findField(>=20@500)]-|" options:NSLayoutFormatAlignAllTop metrics:@{} views:views];
    NSArray *constraints = [parser parse];
    
    NSLayoutConstraint *superViewToFindConstraint = [NSLayoutConstraint constraintWithItem:find attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeLeading multiplier:1.0 constant:20];
    
    NSLayoutConstraint *findToFindNextSpacingConstraint = [NSLayoutConstraint constraintWithItem:findNext attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:find attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:8];
    
    NSLayoutConstraint *findNextToFindFieldSpacingConstraint = [NSLayoutConstraint constraintWithItem:findField attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:findNext attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:8];
    
    NSLayoutConstraint *findFieldWidthConstraint = [NSLayoutConstraint constraintWithItem:findField attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:20];
    findFieldWidthConstraint.priority = 500;
    
    NSLayoutConstraint *findFieldToSuperViewConstraint = [NSLayoutConstraint constraintWithItem:superview attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:findField attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:20];
    
    NSLayoutConstraint *findNextTopAlignConstraint = [NSLayoutConstraint constraintWithItem:find attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:findNext attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
    
    NSLayoutConstraint *findFieldTopAlignConstraint = [NSLayoutConstraint constraintWithItem:findNext attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:findField attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
    
    XCTAssertEqual([constraints count], 7);
    
    [self assertConstraint:constraints[0] equalsConstraint:superViewToFindConstraint];
    [self assertConstraint:constraints[1] equalsConstraint:findToFindNextSpacingConstraint];
    [self assertConstraint:constraints[2] equalsConstraint:findNextToFindFieldSpacingConstraint];
    [self assertConstraint:constraints[3] equalsConstraint:findFieldWidthConstraint];
    [self assertConstraint:constraints[4] equalsConstraint:findFieldToSuperViewConstraint];
    [self assertConstraint:constraints[5] equalsConstraint:findNextTopAlignConstraint];
    [self assertConstraint:constraints[6] equalsConstraint:findFieldTopAlignConstraint];
}

-(void)testCanParseWithVerticalLayoutOptions
{
    NSDictionary *map = @{
        @(NSLayoutFormatAlignAllTop): @(NSLayoutAttributeTop),
        @(NSLayoutFormatAlignAllBottom): @(NSLayoutAttributeBottom),
        @(NSLayoutFormatAlignAllBaseline): @(NSLayoutAttributeBaseline),
        @(NSLayoutFormatAlignAllLastBaseline): @(NSLayoutAttributeLastBaseline),
        @(NSLayoutFormatAlignAllFirstBaseline): @(NSLayoutAttributeFirstBaseline),
        @(NSLayoutFormatAlignAllCenterY): @(NSLayoutAttributeCenterY)
    };
    
    for (NSNumber *formatOption in map) {
        GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:@"[view1][view2]" options:[formatOption unsignedIntegerValue] metrics:@{} views:twoViewsMap];
        NSArray *constraints = [parser parse];
        NSLayoutAttribute expectedAttribute = [[map objectForKey:formatOption] unsignedIntegerValue];
        NSLayoutConstraint *expectedConstraint = [NSLayoutConstraint constraintWithItem:view1 attribute:expectedAttribute relatedBy:NSLayoutRelationEqual toItem:view2 attribute:expectedAttribute multiplier:1.0 constant:0];
        
        XCTAssertEqual([constraints count], 2);
        [self assertConstraint:constraints[1] equalsConstraint:expectedConstraint];
    }
}

-(void)testCanParseWithHorizontalLayoutOptions
{
    NSDictionary *map = @{
        @(NSLayoutFormatAlignAllLeft): @(NSLayoutAttributeLeft),
        @(NSLayoutFormatAlignAllRight): @(NSLayoutAttributeRight),
        @(NSLayoutFormatAlignAllLeading): @(NSLayoutAttributeLeading),
        @(NSLayoutFormatAlignAllTrailing): @(NSLayoutAttributeTrailing),
        @(NSLayoutFormatAlignAllCenterX): @(NSLayoutAttributeCenterX)
    };
    
    for (NSNumber *formatOption in map) {
        GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:@"V:[view1][view2]" options:[formatOption unsignedIntegerValue] metrics:@{} views:twoViewsMap];
        NSArray *constraints = [parser parse];
        NSLayoutAttribute expectedAttribute = [[map objectForKey:formatOption] unsignedIntegerValue];
        NSLayoutConstraint *expectedConstraint = [NSLayoutConstraint constraintWithItem:view1 attribute:expectedAttribute relatedBy:NSLayoutRelationEqual toItem:view2 attribute:expectedAttribute multiplier:1.0 constant:0];
        
        XCTAssertEqual([constraints count], 2);
        [self assertConstraint:constraints[1] equalsConstraint:expectedConstraint];
    }
}

-(void)testThrowsExceptionWhenUsingHorizontalLayoutOptionInHorizontalLayout
{
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:@"[view1][view2]" options:NSLayoutFormatAlignAllLeft metrics:nil views: twoViewsMap];
    XCTAssertThrowsSpecificNamed([parser parse], NSException, NSInvalidArgumentException);
}

-(void)testThrowsExceptionWhenUsingVerticalLayoutOptionInVerticalLayout
{
    NSDictionary *views = @{
        @"view1": view1,
        @"view2": view2
    };
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:@"V:[view1][view2]" options:NSLayoutFormatAlignAllBottom metrics:nil views: views];
    XCTAssertThrowsSpecificNamed([parser parse], NSException, NSInvalidArgumentException);
}

-(void)testCanParseMultipleFormattingOptionsOrg
{
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[view1][view2]" options:NSLayoutFormatAlignAllBottom | NSLayoutFormatAlignAllTop metrics:nil views:@{
        @"view1": view1,
        @"view2": view2
    }];
    
    NSLayoutConstraint *alignBottomConstraint = [NSLayoutConstraint constraintWithItem:view1 attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:view2 attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
    NSLayoutConstraint *alignTopConstraint = [NSLayoutConstraint constraintWithItem:view1 attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:view2 attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
    
    XCTAssertEqual([constraints count], 3);
    [self assertConstraint:constraints[2] equalsConstraint:alignBottomConstraint];
    [self assertConstraint:constraints[1] equalsConstraint:alignTopConstraint];
}

-(void)testCanParseMultipleFormattingOptions
{
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:@"[view1][view2]" options:NSLayoutFormatAlignAllBottom | NSLayoutFormatAlignAllTop metrics:nil views:@{
        @"view1": view1,
        @"view2": view2
    }];
    
    NSArray *constraints = [parser parse];
    NSLayoutConstraint *alignBottomConstraint = [NSLayoutConstraint constraintWithItem:view1 attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:view2 attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
    NSLayoutConstraint *alignTopConstraint = [NSLayoutConstraint constraintWithItem:view1 attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:view2 attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
    
    
    XCTAssertEqual([constraints count], 3);
    [self assertConstraint:constraints[2] equalsConstraint:alignBottomConstraint];
    [self assertConstraint:constraints[1] equalsConstraint:alignTopConstraint];
}

-(void)testCanParseFormatOptionsDirectionOrg
{
    NSView *superview = [[NSView alloc] init];
    NSView *find = [[NSView alloc] init];
    NSView *findNext = [[NSView alloc] init];
    NSView *findField = [[NSView alloc] init];
    
    [superview addSubview:find];
    [superview addSubview:findNext];
    [superview addSubview:findField];
    NSDictionary *views = @{
        @"find": find,
        @"findNext": findNext,
        @"findField": findField
    };
    
    NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[find]-[findNext]-|" options:NSLayoutFormatDirectionLeftToRight metrics:nil views:views];
    
    NSLayoutConstraint *superViewToFindConstraint = [NSLayoutConstraint constraintWithItem:find attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeTop multiplier:1.0 constant:20];
    
    NSLayoutConstraint *findToFindNextSpacingConstraint = [NSLayoutConstraint constraintWithItem:findNext  attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:find attribute:NSLayoutAttributeBottom multiplier:1.0 constant:8];
    
    NSLayoutConstraint *findNextFieldToSuperViewConstraint = [NSLayoutConstraint constraintWithItem:superview  attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:findNext attribute:NSLayoutAttributeBottom multiplier:1.0 constant:20];
    
    XCTAssertEqual([constraints count], 3);
    
    [self assertConstraint:constraints[0] equalsConstraint:superViewToFindConstraint];
    [self assertConstraint:constraints[1] equalsConstraint:findToFindNextSpacingConstraint];
    [self assertConstraint:constraints[2] equalsConstraint:findNextFieldToSuperViewConstraint];
}

-(void)testCanParseFormatOptionsDirectionRightToLeft
{
    NSDictionary *views = @{
        @"find": find,
        @"findNext": findNext,
    };
    
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:@"|-[find]-[findNext]-|" options:NSLayoutFormatDirectionRightToLeft metrics:nil views:views];
    
    NSArray *constraints = [parser parse];
    
    NSLayoutConstraint *superViewToFindConstraint = [NSLayoutConstraint constraintWithItem:superview attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:find attribute:NSLayoutAttributeRight multiplier:1.0 constant:20];
    
    NSLayoutConstraint *findToFindNextSpacingConstraint = [NSLayoutConstraint constraintWithItem:find attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:findNext attribute:NSLayoutAttributeRight multiplier:1.0 constant:8];
    
    NSLayoutConstraint *findNextFieldToSuperViewConstraint = [NSLayoutConstraint constraintWithItem:findNext attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeLeft multiplier:1.0 constant:20];
    
    XCTAssertEqual([constraints count], 3);
    
    [self assertConstraint:constraints[0] equalsConstraint:superViewToFindConstraint];
    [self assertConstraint:constraints[1] equalsConstraint:findToFindNextSpacingConstraint];
    [self assertConstraint:constraints[2] equalsConstraint:findNextFieldToSuperViewConstraint];
}

-(void)testCanParseFormatOptionsDirectionLeftToRight
{
    NSDictionary *views = @{
        @"find": find,
        @"findNext": findNext,
    };
    
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:@"|-[find]-[findNext]-|" options:NSLayoutFormatDirectionLeftToRight metrics:nil views:views];
    
    NSArray *constraints = [parser parse];
    
    NSLayoutConstraint *superViewToFindConstraint = [NSLayoutConstraint constraintWithItem:find attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeLeft multiplier:1.0 constant:20];
    
    NSLayoutConstraint *findToFindNextSpacingConstraint = [NSLayoutConstraint constraintWithItem:findNext  attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:find attribute:NSLayoutAttributeRight multiplier:1.0 constant:8];
    
    NSLayoutConstraint *findNextFieldToSuperViewConstraint = [NSLayoutConstraint constraintWithItem:superview  attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:findNext attribute:NSLayoutAttributeRight multiplier:1.0 constant:20];
    
    XCTAssertEqual([constraints count], 3);
    
    [self assertConstraint:constraints[0] equalsConstraint:superViewToFindConstraint];
    [self assertConstraint:constraints[1] equalsConstraint:findToFindNextSpacingConstraint];
    [self assertConstraint:constraints[2] equalsConstraint:findNextFieldToSuperViewConstraint];
}


-(void)testFormatOptionsDirectionHasNoEffectOnVerticalOrientations
{
    NSDictionary *views = @{
        @"find": find,
        @"findNext": findNext,
    };
    
    NSLayoutConstraint *superViewToFindConstraint = [NSLayoutConstraint constraintWithItem:find attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeTop multiplier:1.0 constant:20];
    
    NSLayoutConstraint *findToFindNextSpacingConstraint = [NSLayoutConstraint constraintWithItem:findNext  attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:find attribute:NSLayoutAttributeBottom multiplier:1.0 constant:8];
    
    NSLayoutConstraint *findNextFieldToSuperViewConstraint = [NSLayoutConstraint constraintWithItem:superview  attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:findNext attribute:NSLayoutAttributeBottom multiplier:1.0 constant:20];
    
    NSArray *options = @[
        @(NSLayoutFormatDirectionLeadingToTrailing),
        @(NSLayoutFormatDirectionLeftToRight),
        @(NSLayoutFormatDirectionRightToLeft)
    ];
    
    for (NSNumber *option in options) {
        GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:@"V:|-[find]-[findNext]-|" options:[option unsignedIntegerValue] metrics:nil views:views];
        
        NSArray *constraints = [parser parse];
        
        XCTAssertEqual([constraints count], 3);
        
        [self assertConstraint:constraints[0] equalsConstraint:superViewToFindConstraint];
        [self assertConstraint:constraints[1] equalsConstraint:findToFindNextSpacingConstraint];
        [self assertConstraint:constraints[2] equalsConstraint:findNextFieldToSuperViewConstraint];
    }
}

@end
