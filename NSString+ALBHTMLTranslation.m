//
//  NSString+ALBHTMLTranslation.m
//
//  Copyright (C) 2013 Collin Donnell (http://collindonnell.com)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
//  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#import "NSString+ALBHTMLTranslation.h"

@implementation NSString (ALBHTMLTranslation)

- (NSString *)alb_stringByDecodingHTMLEntities
{
    NSError *error = nil;
    
    // Load the stored entity info into a dictionary
    NSData *fileData = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ALBHTMLEntityCodes" ofType:@"json" inDirectory:nil]];
    NSDictionary *entitiesInfo = [NSJSONSerialization JSONObjectWithData:fileData options:0 error:&error];
    
    if (error) {
        NSLog(@"Error Reading JSON File: %@", error);
    }
    
    // Use a regex to find all of the entities
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"&(?:[a-z\\d]+|#\\d+|#x[a-f\\d]+);" options:0 error:&error];
    NSArray *results = [regex matchesInString:self options:0 range:NSMakeRange(0, self.length)];
    
    // Create a number formatter that can be reused
    NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
   
    // Create a mutable string copy to work with
    NSMutableString *mutableString = [NSMutableString stringWithString:self];
    
    // Enumerate results in reverse since the string is being changed
    for (NSTextCheckingResult *result in [results reverseObjectEnumerator]) {
        NSRange valueRange = result.range;
        // Adjust the range to remove the & and ; before and after the value 
        valueRange.location += 1;
        valueRange.length -= 2;
        
        NSString *valueString = [mutableString substringWithRange:valueRange];
        unichar characterCode = 0;

        // Check if this is an entity we have a stored code for first
        NSNumber *characterCodeNumber = [entitiesInfo objectForKey:valueString];
        if (characterCodeNumber != nil) {
            characterCode = [characterCodeNumber unsignedShortValue];
        } else {
            // Check for hex and decimal entities
            NSString *hexPrefix = @"#x";
            NSString *decimalPrefix = @"#";

            if ([valueString hasPrefix:hexPrefix]) {
                valueString = [valueString substringFromIndex:hexPrefix.length];
                NSScanner *hexScanner = [NSScanner scannerWithString:valueString];
                [hexScanner scanHexInt:(unsigned *)&characterCode];
            } else {
                valueString = [valueString substringFromIndex:decimalPrefix.length];
                NSNumber *codeNumber = [numberFormatter numberFromString:valueString];
                if (codeNumber) {
                    characterCode = [codeNumber unsignedShortValue];
                }
            }
        }
        
        if (characterCode) {
            NSString *replacementString = [NSString stringWithFormat:@"%C", characterCode];
            [mutableString replaceCharactersInRange:result.range withString:replacementString];
        }
    }
    
    return [mutableString copy];
}

@end
