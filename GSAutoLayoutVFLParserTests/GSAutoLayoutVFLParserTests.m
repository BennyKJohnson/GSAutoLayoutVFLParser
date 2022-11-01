//
//  GSAutoLayoutVFLParserTests.m
//  GSAutoLayoutVFLParserTests
//
//  Created by Benjamin Johnson on 30/10/22.
//  Copyright © 2022 Benjamin Johnson. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <GSAutoLayoutVFLParser/GSAutoLayoutVFLParser.h>

@interface GSAutoLayoutVFLParserTests : XCTestCase

@end

@implementation GSAutoLayoutVFLParserTests
{
    NSView *view1;
    NSView *view2;
}

- (void)setUp {
    view1 = [[NSView alloc] init];
    view2 = [[NSView alloc] init];
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
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:format options:0 metrics:@{} views:@{@"view": view}];
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

-(void)testCanParseMultipleViewPredicates
{
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:@"[view1(>=70,<=100)]" options:0 metrics:@{} views:@{@"view1": view1}];
    NSArray *constraints = [parser parse];
    XCTAssertEqual([constraints count], 2);
    
    NSLayoutConstraint *expectedGTEWidthConstraint = [NSLayoutConstraint constraintWithItem:view1 attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:70];
    
    NSLayoutConstraint *expectedLTEWidthConstraint =
    [NSLayoutConstraint constraintWithItem:view1 attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationLessThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:100];

    [self assertConstraint:constraints[0] equalsConstraint:expectedGTEWidthConstraint];
     [self assertConstraint:constraints[1] equalsConstraint:expectedLTEWidthConstraint];
}


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
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:@"[view(missingMetric)]" options:0 metrics:@{} views:@{@"view": view}];
    XCTAssertThrowsSpecificNamed([parser parse],NSException, NSInvalidArgumentException);
}

-(void)testThrowsWithoutViewPredicateCloseBracket
{
    NSView *view = [[NSView alloc] init];
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:@"[view(50]" options:0 metrics:@{} views:@{@"view": view}];
    
    XCTAssertThrowsSpecificNamed([parser parse], NSException, NSInvalidArgumentException);
}

-(void)testThrowsWithoutViewPredicateConstantOrMetricKey
{
    NSView *view = [[NSView alloc] init];
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:@"[view()]" options:0 metrics:@{} views:@{@"view": view}];
    
    XCTAssertThrowsSpecificNamed([parser parse], NSException, NSInvalidArgumentException);
}

-(void)testCanParseWithFlushViews
{
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:@"[view1][view2]" options:0 metrics:@{} views:@{
        @"view1": view1,
        @"view2": view2
    }];
    NSArray *constraints = [parser parse];
    XCTAssertEqual([constraints count], 1);

    NSLayoutConstraint *expectedFlushConstraint = [NSLayoutConstraint constraintWithItem:view2 attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:view1 attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0];
    
    [self assertConstraint:constraints[0] equalsConstraint:expectedFlushConstraint];
}

-(NSArray*)parseFormat: (NSString*)format
{
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:format options:0 metrics:@{} views:@{
        @"view1": view1,
        @"view2": view2
    }];
    
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
        
    GSAutoLayoutVFLParser *parser = [[GSAutoLayoutVFLParser alloc] initWithFormat:@"|-[find]-[findNext]-[findField(>=20)]-|" options:0 metrics:@{} views:views];
    NSArray *constraints = [parser parse];
    
    NSLayoutConstraint *superViewToFindConstraint = [NSLayoutConstraint constraintWithItem:find attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:superview attribute:NSLayoutAttributeLeading multiplier:1.0 constant:20];
    
    NSLayoutConstraint *findToFindNextSpacingConstraint = [NSLayoutConstraint constraintWithItem:findNext attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:find attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:8];
    
    NSLayoutConstraint *findNextToFindFieldSpacingConstraint = [NSLayoutConstraint constraintWithItem:findField attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:findNext attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:8];
    
    NSLayoutConstraint *findFieldWidthConstraint = [NSLayoutConstraint constraintWithItem:findField attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:20];
    
    NSLayoutConstraint *findFieldToSuperViewConstraint = [NSLayoutConstraint constraintWithItem:superview attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:findField attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:20];
    
    XCTAssertEqual([constraints count], 5);

    [self assertConstraint:constraints[0] equalsConstraint:superViewToFindConstraint];
    [self assertConstraint:constraints[1] equalsConstraint:findToFindNextSpacingConstraint];
    [self assertConstraint:constraints[2] equalsConstraint:findNextToFindFieldSpacingConstraint];
    [self assertConstraint:constraints[3] equalsConstraint:findFieldWidthConstraint];
    [self assertConstraint:constraints[4] equalsConstraint:findFieldToSuperViewConstraint];
}

@end
