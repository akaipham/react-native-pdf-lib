#include <Foundation/Foundation.h>
#include <React/RCTConvert.h>
#include <stdexcept>
#include "PDFPageFactory.h"

PDFPageFactory::PDFPageFactory (PDFWriter* pdfWriter, AbstractContentContext* context) {
    NSString *fontPath = [[NSBundle mainBundle] pathForResource:@"Times New Roman" ofType:@".ttf"];

    this->pdfWriter = pdfWriter;
    this->context   = context;
    this->font      = pdfWriter->GetFontForFile(fontPath.UTF8String);
}

void PDFPageFactory::createAndWrite (PDFWriter* pdfWriter, NSDictionary* pageActions) {
    PDFPage* page = new PDFPage();
    PageContentContext* context = pdfWriter->StartPageContentContext(page);
    PDFPageFactory factory(pdfWriter, context);

    NumberPair coords = getCoords(pageActions[@"mediaBox"]);
    NumberPair dims   = getDims(pageActions[@"mediaBox"]);
    page->SetMediaBox(PDFRectangle(coords.a.intValue,
                                   coords.b.intValue,
                                   dims.a.intValue,
                                   dims.b.intValue));
    factory.applyActions(pageActions[@"actions"]);
    pdfWriter->EndPageContentContext(context);
    pdfWriter->WritePageAndRelease(page);
}

void PDFPageFactory::modifyAndWrite (PDFWriter* pdfWriter, NSDictionary* pageActions) {
    NSInteger pageIndex = [RCTConvert NSInteger:pageActions[@"pageIndex"]];
    PDFModifiedPage page(pdfWriter, pageIndex);
    AbstractContentContext* context = page.StartContentContext();
    PDFPageFactory factory(pdfWriter, context);

    factory.applyActions(pageActions[@"actions"]);
    page.EndContentContext();
    page.WritePage();
}

void PDFPageFactory::applyActions (NSDictionary* actions) {
    for (NSDictionary *action in actions) {
        NSString *type = [RCTConvert NSString:action[@"type"]];
        if ([type isEqualToString:@"text"]) {
            drawText(action);
        }
        else if([type isEqualToString:@"rectangle"]) {
            drawRectangle(action);
        }
        else if([type isEqualToString:@"image"]) {
            drawImage(action);
        }
        else if([type isEqualToString:@"circle_point"]) {
            drawCirclePoint(action);
        }
        else if([type isEqualToString:@"square_point"]) {
            drawSquarePoint(action);
        }
        else if([type isEqualToString:@"line"]) {
            drawLine(action);
        }
    }
}

void PDFPageFactory::drawText (NSDictionary* textActions) {
    NSString* value    = [RCTConvert NSString:textActions[@"value"]];
    NSInteger fontSize = [RCTConvert NSInteger:textActions[@"fontSize"]];
    NumberPair coords  = getCoords(textActions);
    unsigned hexColor  = hexIntFromString(textActions[@"color"]);

    AbstractContentContext::TextOptions textOptions(font, fontSize, AbstractContentContext::eRGB, hexColor);
    context->WriteText(coords.a.intValue, coords.b.intValue, value.UTF8String, textOptions);
}

void PDFPageFactory::drawRectangle (NSDictionary* rectActions) {
    NumberPair coords = getCoords(rectActions);
    NumberPair dims   = getDims(rectActions);
    unsigned hexColor = hexIntFromString(rectActions[@"color"]);

    AbstractContentContext::GraphicOptions options(AbstractContentContext::eFill,
                                                   AbstractContentContext::eRGB,
                                                   hexColor);
    context->DrawRectangle(coords.a.intValue,
                           coords.b.intValue,
                           dims.a.intValue,
                           dims.b.intValue,
                           options);
}

void PDFPageFactory::drawImage (NSDictionary* imageActions) {
    NSString *imageType = [RCTConvert NSString:imageActions[@"imageType"]];
    NSString *imagePath = [RCTConvert NSString:imageActions[@"imagePath"]];
    NumberPair coords   = getCoords(imageActions);
    NumberPair dims     = getDims(imageActions);
    AbstractContentContext::ImageOptions options;

    if ([imageType isEqualToString:@"jpg"]) {
        if (dims.a && dims.b) {
            options.transformationMethod = AbstractContentContext::EImageTransformation::eFit;
            options.fitPolicy            = AbstractContentContext::EFitPolicy::eAlways;
            options.boundingBoxWidth     = dims.a.intValue;
            options.boundingBoxHeight    = dims.b.intValue;
        }

        NSLog(@"File at path? %d", [[NSFileManager defaultManager] fileExistsAtPath:imagePath]);
        if(![[NSFileManager defaultManager] fileExistsAtPath:imagePath]) {
            NSString *msg = [NSString stringWithFormat:@"%@%@", @"No image found at path: ", imagePath];
            throw std::invalid_argument(msg.UTF8String);
        }
        context->DrawImage(coords.a.intValue, coords.b.intValue, imagePath.UTF8String, options);
    }
}

void PDFPageFactory::drawCirclePoint (NSDictionary* circlePointAction) {
    NumberPair coords = getCoords(circlePointAction);
    NSNumber* radius   = getRadius(circlePointAction);
    unsigned hexColor = hexIntFromString(circlePointAction[@"color"]);

    AbstractContentContext::GraphicOptions options(AbstractContentContext::eFill,
                                                   AbstractContentContext::eRGB,
                                                   hexColor);
    context->DrawCircle(coords.a.intValue,
                           coords.b.intValue,
                           radius.intValue,
                           options);
}

void PDFPageFactory::drawSquarePoint (NSDictionary* squarePointAction) {
    NumberPair coords = getCoords(squarePointAction);
    NSNumber* edge   = getEdge(squarePointAction);
    unsigned hexColor = hexIntFromString(squarePointAction[@"color"]);

    AbstractContentContext::GraphicOptions options(AbstractContentContext::eFill,
                                                   AbstractContentContext::eRGB,
                                                   hexColor);
    context->DrawSquare(coords.a.intValue,
                          coords.b.intValue,
                          edge.intValue,
                          options);
}

void PDFPageFactory::drawLine (NSDictionary* lineAction) {
    NSNumber* strokeWidth   = getStrokeWidth(lineAction);
    DoubleAndDoublePairList pathPoints   = getDoubleAndDoublePairList(lineAction, @"points");
    unsigned hexColor = hexIntFromString(lineAction[@"color"]);

    AbstractContentContext::GraphicOptions pathStrokeOptions(AbstractContentContext::eStroke,
															AbstractContentContext::eRGB,
															hexColor,
															strokeWidth.intValue);
    context->DrawPath(pathPoints,
                        pathStrokeOptions);
}

NumberPair PDFPageFactory::getCoords (NSDictionary* coordsMap) {
    return PDFPageFactory::getNumberKeyPair(coordsMap, @"x", @"y");
}

NumberPair PDFPageFactory::getDims (NSDictionary* dimsMap) {
    return PDFPageFactory::getNumberKeyPair(dimsMap, @"width", @"height");
}

NSNumber* PDFPageFactory::getRadius (NSDictionary* radiusMap) {
    return PDFPageFactory::getNumberSingleKey(radiusMap, @"radius");
}

NSNumber* PDFPageFactory::getEdge (NSDictionary* edgeMap) {
    return PDFPageFactory::getNumberSingleKey(edgeMap, @"edge");
}

NSNumber* PDFPageFactory::getStrokeWidth (NSDictionary* strokeMap) {
    return PDFPageFactory::getNumberSingleKey(strokeMap, @"strokeWidth");
}

NSNumber* PDFPageFactory::getNumberSingleKey (NSDictionary* map, NSString* key1) {
    NSNumber *a = nil;

    if (map[key1]) {
        a = [RCTConvert NSNumber:map[key1]];
    }

    return a;
}

NumberPair PDFPageFactory::getNumberKeyPair (NSDictionary* map, NSString* key1, NSString* key2) {
    NSNumber *a = nil;
    NSNumber *b = nil;

    if (map[key1] && map[key2]) {
        a = [RCTConvert NSNumber:map[key1]];
        b = [RCTConvert NSNumber:map[key2]];
    }

    return NumberPair { a, b };
}

DoubleAndDoublePairList PDFPageFactory::getDoubleAndDoublePairList (NSDictionary* map, NSString* key1) {
    double x, y;
    DoubleAndDoublePairList pathPoints;

    if (map[key1]) {
        for (id point in map[key1]) {
            x = [RCTConvert double:point[@"x"]];
            y = [RCTConvert double:point[@"y"]];
            pathPoints.push_back(DoubleAndDoublePair(x,y));
        }
    }

    return pathPoints;
}

unsigned PDFPageFactory::hexIntFromString (NSString* hexStr) {
    unsigned hexColor = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexStr];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&hexColor];
    return hexColor;
}
