//
//  XMLElement.m
//
//  Created by Frank Gregor on 14.06.13.
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

#import "CNXMLElement.h"
#import "NSString+CNXMLAdditions.h"
#import "NSMutableString+CNXMLAdditions.h"


NSString *const CNXMLEmptyString = @"";
static NSString *const CNXMLStartTagBeginFormatString = @"<%@%@%@";
static NSString *const CNXMLStartTagEndFormatString = @">";
static NSString *const CNXMLStartTagEndSelfClosingFormatString = @"/>";
static NSString *const CNXMLEndTagFormatString = @"</%@>";
static NSString *const CNXMLMappingPrefixFormatString = @"%@:%@";
static NSString *const CNXMLNamespacePrefixFormatString = @"xmlns:%@";
static NSString *const CNXMLAttributePlaceholderFormatString = @" %@=\"%@\"";
static NSString *const CNXMLVersionAndEncodingHeaderString = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>";



@interface CNXMLElement () {
   NSMutableDictionary *_attributes;
   NSMutableArray *_children;
   NSMutableDictionary *_namespaces;
}
@property (strong, nonatomic) NSString *mappingPrefix;
@property (strong, nonatomic) NSString *elementName;
@property (strong, nonatomic) NSString *qualifiedName;
@property (strong, nonatomic) NSString *startTag;
@property (strong, nonatomic) NSString *endTag;
@end

@implementation CNXMLElement
#pragma mark - Inititialization

- (id)init {
   self = [super init];
   if (self) {
      _attributes               = [NSMutableDictionary new];
      _children                 = [NSMutableArray new];
      _namespaces               = nil;

      self.mappingPrefix        = CNXMLEmptyString;
      self.qualifiedName        = CNXMLEmptyString;
      self.startTag             = CNXMLEmptyString;
      self.endTag               = CNXMLEmptyString;

      self.useFormattedXML      = YES;
      self.root                 = NO;
      self.value                = CNXMLEmptyString;
      self.level                = 0;

      self.indentationType      = CNXMLContentIndentationTypeTab;
      self.indentationWidth     = 4;
   }
   return self;
}

#pragma mark - XML Element Creation

+ (instancetype)elementWithName:(NSString *)elementName mappingPrefix:(NSString *)mappingPrefix attributes:(NSDictionary *)attributes {
   return [[[self class] alloc] initWithName:elementName mappingPrefix:mappingPrefix attributes:attributes];
}

- (instancetype)initWithName:(NSString *)theName mappingPrefix:(NSString *)mappingPrefix attributes:(NSDictionary *)attributes {
   self = [self init];
   if (self) {
      self.elementName = theName;
      self.mappingPrefix = (mappingPrefix ?: CNXMLEmptyString);
      self.qualifiedName = ([self.mappingPrefix isEqualToString:CNXMLEmptyString] ? theName : [NSString stringWithFormat:CNXMLMappingPrefixFormatString, self.mappingPrefix, self.elementName]);

      if (attributes) {
         _attributes = [NSMutableDictionary dictionaryWithDictionary:attributes];
      }
   }
   return self;
}

#pragma mark - Managing Namespaces

- (void)addNamespaceWithPrefix:(NSString *)thePrefix namespaceURI:(NSString *)theNamespaceURI {
   NSString *key = [NSString stringWithFormat:CNXMLNamespacePrefixFormatString, thePrefix];
   if (!_namespaces) {
      _namespaces = [NSMutableDictionary new];
   }
   _namespaces[key] = theNamespaceURI;
}

- (NSString *)prefixForNamespaceURI:(NSString *)theNamespaceURI {
   __block NSString *prefix = nil;
   [_namespaces enumerateKeysAndObjectsUsingBlock: ^(NSString *currentPrefix, NSString *currentNamespaceURI, BOOL *stop) {
      if ([currentNamespaceURI isEqualToString:theNamespaceURI]) {
         prefix = currentPrefix;
         *stop = YES;
      }
   }];
   return prefix;
}

#pragma mark - XML Content Representation

- (NSString *)XMLString {
   return [self _XMLStringFormatted:self.useFormattedXML];
}

- (NSString *)_XMLStringFormatted:(BOOL)useFormattedXML {
   NSMutableString *XMLString = [NSMutableString stringWithString:CNXMLEmptyString];
   NSString *CRLF             = CNXMLEmptyString;
   NSString *TAB              = CNXMLEmptyString;
   NSString *XMLStartTag      = self.startTag;
   NSString *XMLEndTag        = self.endTag;

   if (useFormattedXML) {
      CRLF = @"\n";
      switch (self.indentationType) {
         case CNXMLContentIndentationTypeTab: {
            TAB = [TAB stringByPaddingToLength:self.level withString:@"\t" startingAtIndex:0];
            break;
         }
         case CNXMLContentIndentationTypeSpace: {
            TAB = [TAB stringByPaddingToLength:(self.level * self.indentationWidth) withString:@" " startingAtIndex:0];
            break;
         }
      }
   }

   if (self.isRoot) {
      [XMLString appendString:CNXMLVersionAndEncodingHeaderString];
   }

   if ([self hasChildren]) {
      NSString *valueString = CNXMLEmptyString;

      for (CNXMLElement *child in self.children) {
         child.indentationType      = self.indentationType;
         child.indentationWidth     = self.indentationWidth;
         child.useFormattedXML      = self.useFormattedXML;

         valueString = [valueString stringByAppendingString:[child XMLString]];
      }

      [XMLString appendObjects:@[ CRLF, TAB, XMLStartTag, valueString, CRLF, TAB, XMLEndTag ]];
   }
   else {
      if ([self isSelfClosing]) {
         [XMLString appendObjects:@[ CRLF, TAB, XMLStartTag ]];
      }
      else {
         [XMLString appendObjects:@[ CRLF, TAB, XMLStartTag, self.value.xmlEscapedString, XMLEndTag ]];
      }
   }

   return XMLString;
}

#pragma mark - Managing XML Element Attributes

- (void)setValue:(id)theValue forAttribute:(NSString *)theAttribute {
   if (theAttribute != nil && ![theAttribute isEqualToString:CNXMLEmptyString]) {
      _attributes[theAttribute] = theValue;
   }
}

- (id)valueForAttribute:(NSString *)theAttribute {
   id attributeValue = nil;
   if (_attributes && [_attributes count] > 0 && ![theAttribute isEqualToString:CNXMLEmptyString]) {
      attributeValue = _attributes[theAttribute];
   }
   return attributeValue;
}

- (void)removeAttribute:(NSString *)theAttribute {
   if (theAttribute != nil && ![theAttribute isEqualToString:CNXMLEmptyString] && _attributes[theAttribute]) {
      [_attributes removeObjectForKey:theAttribute];
   }
}

- (NSString *)attributesString {
   __block NSString *attributesString = CNXMLEmptyString;

   // handling namespaces
   if (self.isRoot && _namespaces != nil) {
      [_namespaces enumerateKeysAndObjectsUsingBlock:^(NSString *prefix, NSString *namespaceURI, BOOL *stop) {
         attributesString = [attributesString stringByAppendingFormat:CNXMLAttributePlaceholderFormatString, prefix, namespaceURI];
      }];
   }

   // handling attributes
   if ([_attributes count] > 0) {
      [_attributes enumerateKeysAndObjectsUsingBlock: ^(id attributeName, id attributeValue, BOOL *stop) {
         attributesString = [attributesString stringByAppendingFormat:CNXMLAttributePlaceholderFormatString, attributeName, attributeValue];
      }];
   }
   return attributesString;
}

- (BOOL)hasAttribute:(NSString *)theAttribute {
   __block BOOL hasAttribute = NO;
   for (NSString *currentAttribute in _attributes) {
      if ([currentAttribute isEqualToString:theAttribute]) {
         hasAttribute = YES;
         break;
      }
   }
   return hasAttribute;
}

#pragma mark - Managing Child Elements

- (void)addChild:(CNXMLElement *)theChild {
   if (theChild != nil) {
      theChild.level = self.level + 1;
      [_children addObject:theChild];
   }
}

- (void)removeChild:(CNXMLElement *)theChild {
   if ([self.children count] > 0) {
      [_children removeObject:theChild];
   }
}

- (void)removeChildWithName:(NSString *)theChildName {
   __block CNXMLElement *childToRemove = nil;
   [self.children enumerateObjectsUsingBlock: ^(CNXMLElement *currentChild, NSUInteger idx, BOOL *stop) {
      if ([currentChild.elementName isEqualToString:theChildName]) {
         childToRemove = currentChild;
         *stop = YES;
      }
   }];

   if (childToRemove) {
      [_children removeObject:childToRemove];
   }
}

- (void)removeChildWithAttributes:(NSDictionary *)attibutes {
   __block CNXMLElement *childToRemove = nil;
   [self.children enumerateObjectsUsingBlock: ^(CNXMLElement *child, NSUInteger idx, BOOL *stop) {
      if ([child.attributes isEqualToDictionary:attibutes]) {
         childToRemove = child;
         *stop = YES;
      }
   }];

   if (childToRemove) {
      [_children removeObject:childToRemove];
   }
}

- (void)removeAllChildren {
   [_children removeAllObjects];
}

- (CNXMLElement *)childWithName:(NSString *)theChildName {
   __block CNXMLElement *searchedChild = nil;
   [self.children enumerateObjectsUsingBlock:^(CNXMLElement *aChild, NSUInteger idx, BOOL *stop) {
      if ([aChild.elementName isEqualToString:theChildName]) {
         searchedChild = aChild;
         *stop = YES;
      }
   }];
   return searchedChild;
}

- (void)enumerateChildrenUsingBlock:(CNXMLEnumerateChildrenBlock)block {
   [self.children enumerateObjectsUsingBlock: ^(CNXMLElement *currentChild, NSUInteger idx, BOOL *stop) {
      block(currentChild, idx, stop);
   }];
}

- (void)enumerateChildWithName:(NSString *)elementName usingBlock:(CNXMLEnumerateChildWithNameBlock)block {
   CNXMLElement *enumElement = [self childWithName:elementName];
   NSInteger lastChildIndex = 0;

   if ([[enumElement children] count] > 0) {
      lastChildIndex = [[enumElement children] count] - 1;
   }

   [enumElement enumerateChildrenUsingBlock:^(CNXMLElement *child, NSUInteger idx, BOOL *stop) {
      block(child, idx, (lastChildIndex == idx), stop);
   }];
}

#pragma mark - Public Custom Accessors

- (BOOL)hasChildren {
   return (self.children && [self.children count] > 0);
}

#pragma mark - Private Custom Accessors

- (NSString *)startTag {
   _startTag = [NSString stringWithFormat:CNXMLStartTagBeginFormatString, _qualifiedName, [self attributesString], ([self isSelfClosing] ? CNXMLStartTagEndSelfClosingFormatString : CNXMLStartTagEndFormatString)];
   return _startTag;
}

- (NSString *)endTag {
   if (![self isSelfClosing]) {
      _endTag = [NSString stringWithFormat:CNXMLEndTagFormatString, _qualifiedName];
   }
   return _endTag;
}

#pragma mark - Private Helper

- (BOOL)isSelfClosing {
   return (![self hasChildren] && ([[self whitespaceAndNewlineTrimmedValue] isEqualToString:CNXMLEmptyString] || self.value == nil));
}

- (NSString *)whitespaceAndNewlineTrimmedValue {
   return [self.value stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
