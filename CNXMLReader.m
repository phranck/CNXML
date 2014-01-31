//
//  CNXMLReader.m
//
//  Created by Frank Gregor on 18.06.13.
//  Copyright (c) 2013 cocoa:naut. All rights reserved.
//

/*
 The MIT License (MIT)
 Copyright © 2013 Frank Gregor, <phranck@cocoanaut.com>

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the “Software”), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */


#import "NSString+CNXMLAdditions.h"
#import "CNXMLReader.h"


@interface CNXMLReader ()
@property (strong) NSXMLParser *XMLparser;
@property (strong) NSMutableString *foundCharacters;
@property (strong) NSMutableArray *elementStack;
@end

@implementation CNXMLReader

- (id)init {
	self = [super init];
	if (self) {
		_XMLparser = nil;
		_elementStack = [[NSMutableArray alloc] init];
		_foundCharacters = [[NSMutableString alloc] init];
		_rootElement = nil;
	}
	return self;
}

- (instancetype)initWithContentsOfFile:(NSString *)xmlFilePath {
	return [self initWithFileURL:[NSURL fileURLWithPath:xmlFilePath]];
}

- (instancetype)initWithContentsOfString:(NSString *)string {
	self = [self init];
	if (self) {
		_XMLparser = [[NSXMLParser alloc] initWithData:[string dataUsingEncoding:NSUTF8StringEncoding]];
		[self configureAndStartParser];
	}
	return self;
}

- (instancetype)initWithFileURL:(NSURL *)theURL {
	self = [self init];
	if (self) {
		_XMLparser = [[NSXMLParser alloc] initWithContentsOfURL:theURL];
		[self configureAndStartParser];
	}
	return self;
}

#pragma mark - XML Document Creation

+ (instancetype)documentWithContentsOfFile:(NSString *)xmlFilePath {
	return [[[self class] alloc] initWithContentsOfFile:xmlFilePath];
}

+ (instancetype)documentWithContentsOfString:(NSString *)string {
	return [[[self class] alloc] initWithContentsOfString:string];
}

+ (instancetype)documentWithFileURL:(NSURL *)theURL {
    return [[[self class] alloc] initWithFileURL:theURL];
}

#pragma mark - Private Helper

- (void)configureAndStartParser {
	[_XMLparser setDelegate:self];
	[_XMLparser setShouldReportNamespacePrefixes:YES];
	[_XMLparser setShouldProcessNamespaces:YES];
	[_XMLparser parse];
}

#pragma mark - Accessors

- (void)setRootElement:(CNXMLElement *)rootElement {
	if (![_rootElement isEqual:rootElement]) {
		_rootElement = rootElement;
		_rootElement.root = YES;
        _rootElement.level = 0;
	}
}

#pragma mark - NSXMLParser Delegate

- (void)parser:(NSXMLParser *)parser didStartMappingPrefix:(NSString *)prefix toURI:(NSString *)namespaceURI {
//    [_documentNamespaces setObject:namespaceURI forKey:prefix];
}

- (void)parser:(NSXMLParser *)parser didEndMappingPrefix:(NSString *)prefix {
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)currentElement namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributes {
	CNXMLElement *element = [CNXMLElement elementWithName:currentElement mappingPrefix:qualifiedName.prefix attributes:attributes];
	CNXMLElement *parent = [self.elementStack lastObject];
    self.foundCharacters = [[NSMutableString alloc] init];

	/// this is our root element
	if ([self.elementStack count] == 0) {
		self.rootElement = element;
		self.rootElement.root = YES;
        self.rootElement.level = 0;
	}
	else {
        element.level = parent.level + 1;
		[parent addChild:element];
	}

	if (![[parent elementName] isEqualToString:currentElement])
		[self.elementStack addObject:element];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	if (![string isEqualToString:CNXMLStringEmpty]) {
        [self.foundCharacters appendString:string];
	}
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)currentElement namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)mappingPrefix {
	CNXMLElement *lastElement = [self.elementStack lastObject];
	if ([[lastElement elementName] isEqualToString:currentElement]) {
		lastElement.value = self.foundCharacters;
		[self.elementStack removeObject:lastElement];
    }
    self.foundCharacters = nil;
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
}

- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validError {
}

@end
