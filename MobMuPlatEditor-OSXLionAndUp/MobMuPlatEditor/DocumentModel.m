//
//  DocumentModel.m
//  MobMuPlatEd1
//
//  Created by Daniel Iglesia on 12/26/12.
//  Copyright (c) 2012 Daniel Iglesia. All rights reserved.
//

#import "DocumentModel.h"



@implementation DocumentModel


//@synthesize isCanvasIPad, isOrientationLandscape, isPageScrollShortEnd, backgroundColor, pdFilePath, pageCount, startPageIndex, controlArray;

-(id)init{
    self = [super init];
    _controlArray = [[NSMutableArray alloc]init];
    //[_pageArray addObject:[[NSMutableArray alloc]init]];//single page - add in init or new
    
    //defaults
    _pageCount = 1;
    _startPageIndex = 0;//zero index!
    _backgroundColor = [NSColor colorWithCalibratedRed:.5 green:.5 blue:.5 alpha:1];
    _canvasType=canvasTypeIPhone3p5Inch;
    _port=54321;
    
    _version=[[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] floatValue ];
    
    
    return self;
}

//keep this for opening old versions of mobmuplat files that use three elements
+(NSColor*)colorFromRGBArray:(NSArray*) rgbArray{
    //printf("\ncolor from %.2f %.2f %.2f", [[rgbArray objectAtIndex:0] floatValue], [[rgbArray objectAtIndex:1] floatValue], [[rgbArray objectAtIndex:2] floatValue]);
    return [NSColor colorWithCalibratedRed:[[rgbArray objectAtIndex:0] floatValue] green:[[rgbArray objectAtIndex:1] floatValue] blue:[[rgbArray objectAtIndex:2] floatValue] alpha:1];
}

//get array of NSNumber floats from a color
+(NSArray*)RGBAArrayfromColor:(NSColor*) color{
    return  [NSArray arrayWithObjects:[NSNumber numberWithFloat:[color redComponent]], [NSNumber numberWithFloat:[color greenComponent]], [NSNumber numberWithFloat:[color blueComponent]], [NSNumber numberWithFloat:[color alphaComponent]], nil];
}
//create a color with translucency
+(NSColor*)colorFromRGBAArray:(NSArray*) rgbaArray{
    return [NSColor colorWithCalibratedRed:[[rgbaArray objectAtIndex:0] floatValue] green:[[rgbaArray objectAtIndex:1] floatValue] blue:[[rgbaArray objectAtIndex:2] floatValue] alpha:[[rgbaArray objectAtIndex:3] floatValue] ];
}


-(NSString*)modelToString{
    NSMutableDictionary *topDict = [[NSMutableDictionary alloc]init];
    //doc stuff
    
    //bg color
    if(_backgroundColor)[topDict setObject:[DocumentModel RGBAArrayfromColor:_backgroundColor] forKey:@"backgroundColor" ];
    //pd file
    if(_pdFile)[topDict setObject:_pdFile forKey:@"pdFile"];
    //canvasType
    if(_canvasType==canvasTypeIPhone3p5Inch)[topDict setObject:@"iPhone3p5Inch" forKey:@"canvasType"];
    else if(_canvasType==canvasTypeIPhone4Inch)[topDict setObject:@"iPhone4Inch" forKey:@"canvasType"];
    else if(_canvasType==canvasTypeIPad)[topDict setObject:@"iPad" forKey:@"canvasType"];
    
    [topDict setObject:[NSNumber numberWithBool:_isOrientationLandscape] forKey:@"isOrientationLandscape"];
    [topDict setObject:[NSNumber numberWithBool:_isPageScrollShortEnd] forKey:@"isPageScrollShortEnd"];
    [topDict setObject:[NSNumber numberWithInt:_pageCount] forKey:@"pageCount"];
    [topDict setObject:[NSNumber numberWithInt:_startPageIndex] forKey:@"startPageIndex"];
    [topDict setObject:[NSNumber numberWithInt:_port] forKey:@"port"];
    //[topDict setObject:[NSNumber numberWithFloat:_version] forKey:@"version"];
    [topDict setObject:[NSNumber numberWithFloat:_version] forKey:@"version"];//save as Global version, not as this objects version (in case it was loaded from an older version
    
    NSMutableArray* jsonControlDictArray = [[NSMutableArray alloc]init];//array of dictionaries
   
    //step through all gui controls
    for(MMPControl* control in  _controlArray){
        NSMutableDictionary* GUIDict = [[NSMutableDictionary alloc]init];
        
        //common to all MMPControlsublcasses
        [GUIDict setObject:NSStringFromClass([control class]) forKey:@"class"];
        NSArray* frameArray = [NSArray arrayWithObjects:[NSNumber numberWithFloat:control.frame.origin.x], [NSNumber numberWithFloat:control.frame.origin.y ], [NSNumber numberWithFloat:control.frame.size.width], [NSNumber numberWithFloat:control.frame.size.height], nil];
        [GUIDict setObject:frameArray forKey:@"frame"];
        [GUIDict setObject:[DocumentModel RGBAArrayfromColor:[control color]] forKey:@"color"];
        [GUIDict setObject:[DocumentModel RGBAArrayfromColor:[control highlightColor]] forKey:@"highlightColor"];
        [GUIDict setObject:[control address] forKey:@"address"];
            
        //slider
        if([control isKindOfClass:[MMPSlider class]]){
            [GUIDict setObject:[NSNumber numberWithInt:[(MMPSlider*)control range]] forKey:@"range"] ;
            [GUIDict setObject:[NSNumber numberWithBool:[(MMPSlider*)control isHorizontal]] forKey:@"isHorizontal"] ;
        }
        //knob
        else if([control isKindOfClass:[MMPKnob class]]){
            [GUIDict setObject:[NSNumber numberWithInt:[(MMPKnob*)control range]] forKey:@"range"] ;
            [GUIDict setObject:[DocumentModel RGBAArrayfromColor:[(MMPKnob*)control indicatorColor]] forKey:@"indicatorColor"];
        }
        //Label
        else if([control isKindOfClass:[MMPLabel class]]){
            [GUIDict setObject:[(MMPLabel*)control stringValue] forKey:@"text"] ;
            [GUIDict setObject:[NSNumber numberWithInt:[(MMPLabel*)control textSize]] forKey:@"textSize"] ;
            [GUIDict setObject:[(MMPLabel*)control fontFamily] forKey:@"textFontFamily"] ;
            [GUIDict setObject:[(MMPLabel*)control fontName] forKey:@"textFont"] ;
        }
        //grid
        else if([control isKindOfClass:[MMPGrid class]]){
            [GUIDict setObject:[NSArray arrayWithObjects:[NSNumber numberWithInt:[(MMPGrid*)control dimX]], [NSNumber numberWithInt:[(MMPGrid*)control dimY]],nil] forKey:@"dim"] ;
            [GUIDict setObject:[NSNumber numberWithInt:[(MMPGrid*)control cellPadding]] forKey:@"cellPadding"];
            [GUIDict setObject:[NSNumber numberWithInt:[(MMPGrid*)control borderThickness]] forKey:@"borderThickness"];
            [GUIDict setObject:[NSNumber numberWithInt:[(MMPGrid*)control mode]] forKey:@"mode"];
        }
        //panel
        else if([control isKindOfClass:[MMPPanel class]]){
            if([(MMPPanel*)control imagePath])
                [GUIDict setObject:[(MMPPanel*)control imagePath] forKey:@"imagePath"];
          [GUIDict setObject:[NSNumber numberWithBool:((MMPPanel*)control).shouldPassTouches] forKey:@"passTouches"];
        }
        //multislider
        else if([control isKindOfClass:[MMPMultiSlider class]]){
            [GUIDict setObject:[NSNumber numberWithInt:[(MMPMultiSlider*)control range]] forKey:@"range"] ;
        }
        //Toggle
        else if([control isKindOfClass:[MMPToggle class]]){
            [GUIDict setObject:[NSNumber numberWithInt:[(MMPToggle*)control borderThickness]] forKey:@"borderThickness"] ;
        }
        else if([control isKindOfClass:[MMPMenu class]]){
            [GUIDict setObject:[(MMPMenu*)control titleString] forKey:@"title"] ;
        }
        else if([control isKindOfClass:[MMPTable class]]){
          [GUIDict setObject:[DocumentModel RGBAArrayfromColor:[(MMPTable*)control selectionColor]] forKey:@"selectionColor"] ;
          [GUIDict setObject:[NSNumber numberWithInt:[(MMPTable*)control mode]] forKey:@"mode"] ;
        }
        //LCD and Button have no properties
        //pass along original bad class
        else if([control isKindOfClass:[MMPUnknown class]]){
            //[GUIDict setObject:NSStringFromClass([control class]) forKey:@"class"];
            GUIDict = ((MMPUnknown*)control).badGUIDict.mutableCopy;
           NSArray* frameArray = [NSArray arrayWithObjects:[NSNumber numberWithFloat:control.frame.origin.x], [NSNumber numberWithFloat:control.frame.origin.y ], [NSNumber numberWithFloat:control.frame.size.width], [NSNumber numberWithFloat:control.frame.size.height], nil];
           [GUIDict setObject:frameArray forKey:@"frame"];
        }
        
        
        [jsonControlDictArray addObject:GUIDict];
    }
    
    [topDict setObject:jsonControlDictArray forKey:@"gui"];//add this array of dictionaries to the top level dictionary
    
    //return [topDict JSONString];//convert to string
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:topDict
                                                     options:0
                                                       error:nil];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
  return jsonString;
}

//load DocumentModel from JSON string
+(DocumentModel*)modelFromString:(NSString*)inString{
    DocumentModel* model = [[DocumentModel alloc]init];
    
    //NSDictionary* topDict = [inString objectFromJSONString];
    NSData *data = [inString dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* topDict = [NSJSONSerialization JSONObjectWithData:data options:nil error:nil];
  
    if([topDict objectForKey:@"backgroundColor"]){
        NSArray* colorArray = [topDict objectForKey:@"backgroundColor"];
        if([colorArray count]==4)
            [model setBackgroundColor:[DocumentModel colorFromRGBAArray:colorArray]];
        else if ([colorArray count]==3)
            [model setBackgroundColor:[DocumentModel colorFromRGBArray:colorArray]];
    }
    
    if([topDict objectForKey:@"pdFile"])
        [model setPdFile:[topDict objectForKey:@"pdFile"]];
    if([topDict objectForKey:@"canvasType"]){
        if([[topDict objectForKey:@"canvasType"] isEqualToString:@"iPhone3p5Inch"])[model setCanvasType:canvasTypeIPhone3p5Inch];
         if([[topDict objectForKey:@"canvasType"] isEqualToString:@"iPhone4Inch"])[model setCanvasType:canvasTypeIPhone4Inch];
         if([[topDict objectForKey:@"canvasType"] isEqualToString:@"iPad"])[model setCanvasType:canvasTypeIPad];
    }
        
    if([topDict objectForKey:@"isOrientationLandscape"])
        [model setIsOrientationLandscape:[[topDict objectForKey:@"isOrientationLandscape"] boolValue] ];
    if([topDict objectForKey:@"isPageScrollShortEnd"])
        [model setIsPageScrollShortEnd:[[topDict objectForKey:@"setIsPageScrollShortEnd"] boolValue] ];
    if([topDict objectForKey:@"pageCount"])
        [model setPageCount:[[topDict objectForKey:@"pageCount"] intValue] ];
    if([topDict objectForKey:@"startPageIndex"])
        [model setStartPageIndex:[[topDict objectForKey:@"startPageIndex"] intValue] ];
    if([topDict objectForKey:@"port"])
        [model setPort:[[topDict objectForKey:@"port"] intValue] ];
    if([topDict objectForKey:@"version"])
        [model setVersion:[[topDict objectForKey:@"version"] floatValue] ];
    
    NSArray* controlDictArray;
    
    if([topDict objectForKey:@"gui"])
       controlDictArray = [topDict objectForKey:@"gui"];//array of dictionaries, one for each gui control
       for(NSDictionary* guiDict in controlDictArray){//for each one
           
           MMPControl* control;
            if(![guiDict objectForKey:@"class"])continue;// if doesn't have a class, skip out of loop
        
            NSString* classString = [guiDict objectForKey:@"class"];
           //frame
           //default
            CGRect newFrame = CGRectMake(0, 0, 100, 100);
            if([guiDict objectForKey:@"frame"]){
                NSArray* frameRectArray = [guiDict objectForKey:@"frame"];
                newFrame = CGRectMake([[frameRectArray objectAtIndex:0] floatValue], [[frameRectArray objectAtIndex:1] floatValue], [[frameRectArray objectAtIndex:2] floatValue], [[frameRectArray objectAtIndex:3] floatValue]);
            }
            //color
            NSColor* color = [NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1];
            if([guiDict objectForKey:@"color"]){
                NSArray* colorArray = [guiDict objectForKey:@"color"];
                if([colorArray count]==4)
                    color=[DocumentModel colorFromRGBAArray:colorArray];
                else if ([colorArray count]==3)
                    color=[DocumentModel colorFromRGBArray:colorArray];
                
            }//highlight color
            NSColor* highlightColor = [NSColor grayColor];
            if([guiDict objectForKey:@"highlightColor"]){
                NSArray* highlightColorArray = [guiDict objectForKey:@"highlightColor"];
                if([highlightColorArray count]==4)
                   highlightColor=[DocumentModel colorFromRGBAArray:highlightColorArray];
                else if ([highlightColorArray count]==3)
                    highlightColor=[DocumentModel colorFromRGBArray:highlightColorArray];//stop supporting?
                
            }
            //check by MMPControl subclass, and alloc/init object
            if([classString isEqualToString:@"MMPSlider"]){
                control = [[MMPSlider alloc] initWithFrame:newFrame];
                if([guiDict objectForKey:@"isHorizontal"])
                    [(MMPSlider*)control setIsHorizontal:[[guiDict objectForKey:@"isHorizontal"] boolValue] ];
                if([guiDict objectForKey:@"range"])
                    [(MMPSlider*)control setRange:[[guiDict objectForKey:@"range"] intValue] ];
            }
            else if([classString isEqualToString:@"MMPKnob"]){
                control = [[MMPKnob alloc] initWithFrame:newFrame];
                NSColor* indicatorColor = [NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:1];
                if([guiDict objectForKey:@"indicatorColor"])
                    indicatorColor = [DocumentModel colorFromRGBAArray:[guiDict objectForKey:@"indicatorColor"]];
                [(MMPKnob*)control setIndicatorColor:indicatorColor];
                if([guiDict objectForKey:@"range"])
                    [(MMPKnob*)control setRange:[[guiDict objectForKey:@"range"] intValue] ];
            }
            else if([classString isEqualToString:@"MMPButton"]){
                control = [[MMPButton alloc] initWithFrame:newFrame];
            }
            else if([classString isEqualToString:@"MMPToggle"]){
                control = [[MMPToggle alloc] initWithFrame:newFrame];
                if([guiDict objectForKey:@"borderThickness"])
                    [(MMPToggle*)control setBorderThickness:[[guiDict objectForKey:@"borderThickness"] intValue] ];
            }
            else if([classString isEqualToString:@"MMPLabel"]){
                control = [[MMPLabel alloc] initWithFrame:newFrame];
                if([guiDict objectForKey:@"text"])
                    [(MMPLabel*)control setStringValue:[guiDict objectForKey:@"text"]];
                if([guiDict objectForKey:@"textSize"])
                    [(MMPLabel*)control setTextSize:[[guiDict objectForKey:@"textSize"] intValue]];
                if([guiDict objectForKey:@"textFont"] && [guiDict objectForKey:@"textFontFamily"])
                    [(MMPLabel*)control setFontFamily:[guiDict objectForKey:@"textFontFamily"] fontName:[guiDict objectForKey:@"textFont"]];
            }
            else if([classString isEqualToString:@"MMPXYSlider"]){
                control = [[MMPXYSlider alloc] initWithFrame:newFrame];
            }
            else if([classString isEqualToString:@"MMPGrid"]){
                control = [[MMPGrid alloc] initWithFrame:newFrame];
                if([guiDict objectForKey:@"dim"]){
                    NSArray* dim = [guiDict objectForKey:@"dim"];
                    [(MMPGrid*)control setDimX:[[dim objectAtIndex:0]intValue ]];
                    [(MMPGrid*)control setDimY:[[dim objectAtIndex:1]intValue ]];
                }
                if([guiDict objectForKey:@"borderThickness"])
                    [(MMPGrid*)control setBorderThickness:[[guiDict objectForKey:@"borderThickness"] intValue] ];
                if([guiDict objectForKey:@"cellPadding"])
                    [(MMPGrid*)control setCellPadding:[[guiDict objectForKey:@"cellPadding"] intValue] ];
                if([guiDict objectForKey:@"mode"])
                  [(MMPGrid*)control setMode:[[guiDict objectForKey:@"mode"] intValue] ];

            }
            else if([classString isEqualToString:@"MMPPanel"]){
                control = [[MMPPanel alloc] initWithFrame:newFrame];
                if([guiDict objectForKey:@"imagePath"])[(MMPPanel*)control setImagePath:[guiDict objectForKey:@"imagePath"]];
                if([guiDict objectForKey:@"passTouches"])[(MMPPanel*)control setShouldPassTouches:[guiDict objectForKey:@"passTouches"]];
                    
            }
            else if([classString isEqualToString:@"MMPMultiSlider"]){
                control = [[MMPMultiSlider alloc] initWithFrame:newFrame];
                if([guiDict objectForKey:@"range"])
                    [(MMPMultiSlider*)control setRange:[[guiDict objectForKey:@"range"] intValue] ];
            }
            else if([classString isEqualToString:@"MMPLCD"]){
                control = [[MMPLCD alloc] initWithFrame:newFrame];
            }
            else if([classString isEqualToString:@"MMPMultiTouch"]){
              control = [[MMPMultiTouch alloc] initWithFrame:newFrame];
            }
            else if([classString isEqualToString:@"MMPMenu"]) {
              control = [[MMPMenu alloc] initWithFrame:newFrame];
              if([guiDict objectForKey:@"title"])
                [(MMPMenu*)control setTitleString:[guiDict objectForKey:@"title"] ];
            }
            else if([classString isEqualToString:@"MMPTable"]) {
              control = [[MMPTable alloc] initWithFrame:newFrame];
              if([guiDict objectForKey:@"selectionColor"])
                [(MMPTable*)control setSelectionColor:[DocumentModel colorFromRGBAArray:[guiDict objectForKey:@"selectionColor"]]];
              if([guiDict objectForKey:@"mode"])
                [(MMPTable*)control setMode:[[guiDict objectForKey:@"mode"] intValue]];
            }
            else{//unknown
                control = [[MMPUnknown alloc] initWithFrame:newFrame];
                [(MMPUnknown*)control setBadName:classString];
                [(MMPUnknown*)control setBadGUIDict:guiDict];
            }
           
        //set color
            if([control respondsToSelector:@selector(setColor:)]){//in theory all mecontrol respond to these
                [control setColor:color];
            }
            if([control respondsToSelector:@selector(setHighlightColor:)]){
                    [control setHighlightColor:highlightColor];
            }
        //address
            if([guiDict objectForKey:@"address"])
                [control setAddress:[guiDict objectForKey:@"address"]];
        
            [[model controlArray] addObject:control];
        }
    
    return model;
}

@end
