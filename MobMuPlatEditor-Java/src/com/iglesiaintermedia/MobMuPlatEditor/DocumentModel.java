package com.iglesiaintermedia.MobMuPlatEditor;
import java.awt.Color;
import java.awt.Rectangle;
import java.io.BufferedReader;
import java.util.*;
import java.util.ResourceBundle.Control;

import com.google.gson.*;
import com.google.gson.reflect.TypeToken;
import java.lang.reflect.Type;

import com.iglesiaintermedia.MobMuPlatEditor.controls.*;
public class DocumentModel {
	public final static int VERSION = 2;//spec version for incrementing on breaking changes.no longer matching client release version
	public enum CanvasType{ 
		canvasTypeWidePhone,
		canvasTypeTallPhone, 
		canvasTypeWideTablet , 
		canvasTypeTallTablet,
		canvasTypeWatch}
	
	CanvasType canvasType;
	boolean isOrientationLandscape;
	boolean isPageScrollShortEnd;
	Color backgroundColor;
	String pdFile;
	int pageCount;
	int startPageIndex;
	int port;
	int version;
	public boolean preferAndroidFontDisplay;
	
	static Gson gson;
	
	public ArrayList<MMPControl> controlArray;
	
	///
	//keep this for opening old versions of mobmuplat files that use three elements
	static Color colorFromRGBArray(JsonArray rgbArray){
	    return new Color(rgbArray.get(0).getAsFloat(), rgbArray.get(1).getAsFloat(), rgbArray.get(2).getAsFloat()  );
	}

	//get array of NSNumber floats from a color
	static ArrayList<Float> RGBAArrayFromColor(Color color){
	    //System.out.print("\narray from color with red "+color.getRed());
		ArrayList<Float> retval = new ArrayList<Float>();
		retval.add(new Float(color.getRed()/255f));
		retval.add(new Float(color.getGreen()/255f));
		retval.add(new Float(color.getBlue()/255f));
		retval.add(new Float(color.getAlpha()/255f));
		return retval;
		
	}
	//create a color with translucency
	static Color colorFromRGBAArray(JsonArray rgbaArray){
	    return new Color(rgbaArray.get(0).getAsFloat(), rgbaArray.get(1).getAsFloat(), rgbaArray.get(2).getAsFloat(), rgbaArray.get(3).getAsFloat()  );
	}

	
	public DocumentModel(){
		super();
		controlArray = new ArrayList<MMPControl>();
		 if(gson==null)gson = new Gson();
		
		//defaults
	    pageCount = 1;
	    startPageIndex = 0;
	    backgroundColor = new Color(128,128,128);
	    canvasType=CanvasType.canvasTypeTallPhone;
	    port=54321;
	    version=VERSION;
	}
	
	public String modelToString(){
	    Map<String, Object> topDict = new HashMap<String, Object>();
	    //doc stuff
	    
	    //bg color
	    if(backgroundColor!=null)topDict.put("backgroundColor", DocumentModel.RGBAArrayFromColor(backgroundColor) );//[topDict setObject:[DocumentModel RGBAArrayfromColor:_backgroundColor] forKey:@"backgroundColor" ];
	    //pd file
	    if(pdFile!=null)topDict.put("pdFile", pdFile);//setObject:_pdFile forKey:@"pdFile"];
	    //canvasType
	    if(canvasType==CanvasType.canvasTypeWidePhone)topDict.put("canvasType", "widePhone"); //setObject:@"iPhone3p5Inch" forKey:@"canvasType"];
	    else if(canvasType==CanvasType.canvasTypeTallPhone)topDict.put("canvasType", "tallPhone");
	    else if(canvasType==CanvasType.canvasTypeWideTablet)topDict.put("canvasType", "wideTablet");
	    else if(canvasType==CanvasType.canvasTypeTallTablet) topDict.put("canvasType", "tallTablet");
	    
	    topDict.put("isOrientationLandscape", new Boolean(isOrientationLandscape)); //setObject:[NSNumber numberWithBool:_isOrientationLandscape] forKey:@"isOrientationLandscape"];
	    topDict.put("isPageScrollShortEnd", new Boolean(isPageScrollShortEnd));
	    topDict.put("pageCount", new Integer(pageCount));
	    topDict.put("startPageIndex", new Integer(startPageIndex));
	    topDict.put("port", new Integer(port));
	    topDict.put("version", new Float(VERSION));
	    topDict.put("preferAndroidFontDisplayInEditor", new Boolean(preferAndroidFontDisplay));
	    
	    
	    ArrayList<Map<String, Object>> jsonControlDictArray = new ArrayList<Map<String, Object>>();//array of dictionaries
	   
	    //step through all gui controls
	    for(MMPControl control:controlArray){
	        Map<String, Object> GUIDict = new HashMap<String, Object>();
	        
	        //common to all MMPControlsublcasses
	        String[] classNameSplit = control.getClass().getName().split("\\.");//double-escape to match the dots in long class name ("iglesia.bla.bla.MMPSlider")
	        
	        GUIDict.put("class", classNameSplit[classNameSplit.length-1]);// setObject:NSStringFromClass([control class]) forKey:@"class"];
	        
	        ArrayList<Float> frameArray = new ArrayList<Float>();
	        frameArray.add(new Float(control.getX())); 
	        frameArray.add(new Float(control.getY()));
	        frameArray.add(new Float(control.getWidth()));
	        frameArray.add(new Float(control.getHeight()));
	        GUIDict.put("frame", frameArray);
	        
	        GUIDict.put("color", DocumentModel.RGBAArrayFromColor(control.getColor()));// setObject:[DocumentModel RGBAArrayfromColor:[control color]] forKey:@"color"];
	        GUIDict.put("highlightColor", DocumentModel.RGBAArrayFromColor(control.getHighlightColor()));
	        
	        GUIDict.put("address", control.getAddress());
	        
	        //slider
	        if(control instanceof MMPSlider){
	        	MMPSlider currSlider = (MMPSlider)control;
	        	GUIDict.put("range", new Integer(currSlider.getRange()));
	        	GUIDict.put("isHorizontal", new Boolean(currSlider.isHorizontal));
	        }
	        
	      //knob
	        else if(control instanceof MMPKnob){
	        	MMPKnob currKnob = (MMPKnob)control;
	        	GUIDict.put("range", new Integer(currKnob.getRange()));
	        	GUIDict.put("indicatorColor", DocumentModel.RGBAArrayFromColor(currKnob.getIndicatorColor()) );
	        }
	        
	      //label
	        else if(control instanceof MMPLabel){
	        	MMPLabel currLabel = (MMPLabel)control;
	        	GUIDict.put("text", new String(currLabel.getStringValue()));
	        	GUIDict.put("textSize", new Integer(currLabel.textSize));
	        	GUIDict.put("textFontFamily", new String(currLabel.fontFamily));
	        	GUIDict.put("textFont", new String(currLabel.fontName));
	        	GUIDict.put("androidFont", new String(currLabel.androidFontFileName));
	        	GUIDict.put("hAlign", new Integer(currLabel.getHorizontalAlignment()));
	        	GUIDict.put("vAlign", new Integer(currLabel.getVerticalAlignment()));
	        }
	        //grid
	        else if(control instanceof MMPGrid){
	        	MMPGrid currGrid = (MMPGrid)control;
	        	ArrayList<Integer> dim = new ArrayList<Integer>(); 
	        	dim.add(new Integer(currGrid.dimX));
	        	dim.add(new Integer(currGrid.dimY));
	        	GUIDict.put("dim", dim);
	        	GUIDict.put("cellPadding", new Integer(currGrid.cellPadding));
	        	GUIDict.put("borderThickness", new Integer(currGrid.borderThickness));
	        	GUIDict.put("mode", new Integer(currGrid.getMode()));
	        }
	        //panel
	        else if(control instanceof MMPPanel){
	        	MMPPanel currPanel = (MMPPanel)control;
	        	if(currPanel.imagePath!=null)
	        		GUIDict.put("imagePath", new String(currPanel.imagePath));
	        	
	        	GUIDict.put("passTouches", new Boolean(currPanel.shouldPassTouches));
	        }
	        //multislider
	        else if(control instanceof MMPMultiSlider){
	        	MMPMultiSlider currMultiSlider = (MMPMultiSlider)control;
	        	GUIDict.put("range", new Integer(currMultiSlider.range));
	        	GUIDict.put("outputMode", new Integer(currMultiSlider.outputMode));
	        }
	        //toggle
	        else if(control instanceof MMPToggle){
	        	MMPToggle currToggle = (MMPToggle)control;
	        	GUIDict.put("borderThickness", new Integer(currToggle.borderThickness));
	        }
	        else if(control instanceof MMPMenu){
	        	MMPMenu currMenu = (MMPMenu)control;
	        	GUIDict.put("title", new String(currMenu.titleString));
	        }
	        else if(control instanceof MMPTable){
	        	MMPTable currTable = (MMPTable)control;
	        	GUIDict.put("mode", new Integer(currTable.getMode()));
	        	GUIDict.put("selectionColor", DocumentModel.RGBAArrayFromColor(currTable.getSelectionColor()));
	        	GUIDict.put("displayMode", currTable.getDisplayMode());
	        	GUIDict.put("displayRangeLo", currTable.getDisplayRangeLo());
	        	GUIDict.put("displayRangeHi", currTable.getDisplayRangeHi());
	        }
	        else if(control instanceof MMPUnknown){
	        	GUIDict = ((MMPUnknown)control).badGUIDict;
	        	 ArrayList<Float> frameArray2 = new ArrayList<Float>();
	 	        frameArray2.add(new Float(control.getX())); 
	 	        frameArray2.add(new Float(control.getY()));
	 	        frameArray2.add(new Float(control.getWidth()));
	 	        frameArray2.add(new Float(control.getHeight()));
	 	        GUIDict.put("frame", frameArray2);
	        	
	        }
	        jsonControlDictArray.add(GUIDict);// addObject:GUIDict];
	    }
	    
	    topDict.put("gui", jsonControlDictArray);// setObject:jsonControlDictArray forKey:@"gui"];//add this array of dictionaries to the top level dictionary
	    
	    return gson.toJson(topDict, Map.class);
	}
	     
	

	//load DocumentModel from JSON string
	static DocumentModel modelFromString(String inString){
		DocumentModel model = new DocumentModel();
		//Map topDict = gson.fromJson(inBr, Map.class);
		JsonParser parser = new JsonParser();
	    JsonObject topDict = parser.parse(inString).getAsJsonObject();//top dict

		
		 if(topDict.getAsJsonArray("backgroundColor")!=null){
		        JsonArray colorArray = topDict.getAsJsonArray("backgroundColor");
		        if(colorArray.size()==4)
		            model.backgroundColor=DocumentModel.colorFromRGBAArray(colorArray);
		        else if (colorArray.size()==3)
		        	model.backgroundColor=DocumentModel.colorFromRGBArray(colorArray);
		    }
		 
		 if(topDict.get("pdFile")!=null) 
		    model.pdFile=topDict.get("pdFile").getAsString();// objectForKey:@"pdFile"]];
		 if(topDict.get("canvasType")!=null){
		    	String canvasTypeString = topDict.get("canvasType").getAsString();
		        if(canvasTypeString.equals("iPhone3p5Inch") ||
		           canvasTypeString.equals("widePhone")) {
		        	model.canvasType=CanvasType.canvasTypeWidePhone;
		        }
		        if(canvasTypeString.equals("iPhone4Inch") || 
		           canvasTypeString.equals("tallPhone")) {
		        	model.canvasType=CanvasType.canvasTypeTallPhone;
		        }
		        if(canvasTypeString.equals("iPad") || 
		        	canvasTypeString.equals("wideTablet")) {
		        	model.canvasType=CanvasType.canvasTypeWideTablet;
		        }
		        if(canvasTypeString.equals("android7Inch")|| 
		           canvasTypeString.equals("tallTablet")) { 
		        	model.canvasType=CanvasType.canvasTypeTallTablet;
		        }
		    }
		        
		    if(topDict.get("isOrientationLandscape")!=null)
		    	model.isOrientationLandscape= topDict.get("isOrientationLandscape").getAsBoolean();
		    if(topDict.get("isPageScrollShortEnd")!=null)
		    	model.isPageScrollShortEnd=topDict.get("isPageScrollShortEnd").getAsBoolean();
		    if(topDict.get("pageCount")!=null)
		    	model.pageCount=topDict.get("pageCount").getAsInt();
		    if(topDict.get("startPageIndex")!=null)
		    	model.startPageIndex=topDict.get("startPageIndex").getAsInt();
		    if(topDict.get("port")!=null)
		    	model.port=topDict.get("port").getAsInt();
		    int version = VERSION;
		    if(topDict.get("version")!=null) {
		    	version = topDict.get("version").getAsInt();
		    	model.version=version;
		    }
		    if(topDict.get("preferAndroidFontDisplayInEditor")!=null) {
		    	model.preferAndroidFontDisplay = topDict.get("preferAndroidFontDisplayInEditor").getAsBoolean();
		    }
		    
		    JsonArray controlDictArray;//array of dictionaries, one for each gui element
		    
		    if(topDict.get("gui")!=null){
		       controlDictArray = topDict.get("gui").getAsJsonArray();//[topDict objectForKey:@"gui"];//array of dictionaries, one for each gui control
		       //for(JsonObject guiDict : controlDictArray){//for each one
		       for(int i=0;i<controlDictArray.size();i++){    
		           JsonObject guiDict = controlDictArray.get(i).getAsJsonObject();//???
		    	   MMPControl control;
		            if(guiDict.get("class")==null)continue;// if doesn't have a class, skip out of loop
		        
		            String classString = guiDict.get("class").getAsString();// objectForKey:@"class"];
		           //frame
		           //default
		            Rectangle newFrame = new Rectangle(0, 0, 100, 100);
		            if(guiDict.get("frame")!=null){
		            	JsonArray frameRectArray = guiDict.getAsJsonArray("frame");
		                //newFrame = CGRectMake([[frameRectArray objectAtIndex:0] floatValue], [[frameRectArray objectAtIndex:1] floatValue], [[frameRectArray objectAtIndex:2] floatValue], [[frameRectArray objectAtIndex:3] floatValue]);
		            	//System.out.print("\nframearray size "+frameRectArray.size());
		            	//System.out.print("\nframe "+frameRectArray.get(0).getAsFloat()+" "+frameRectArray.get(1).getAsFloat() );
		            	newFrame = new Rectangle((int)frameRectArray.get(0).getAsFloat(), (int)frameRectArray.get(1).getAsFloat(), (int)frameRectArray.get(2).getAsFloat(), (int)frameRectArray.get(3).getAsFloat());
		            }
		            //color
		            Color color = new Color(1f, 1f, 1f, 1f);
		            if(guiDict.getAsJsonArray("color")!=null){
				        JsonArray colorArray = guiDict.getAsJsonArray("color");
				        if(colorArray.size()==4)
				            color=DocumentModel.colorFromRGBAArray(colorArray);
				        else if (colorArray.size()==3)
				        	color=DocumentModel.colorFromRGBArray(colorArray);
				    }
		           
		            //highlight color
		            Color highlightColor = Color.RED;
		            if(guiDict.getAsJsonArray("highlightColor")!=null){
				        JsonArray highlightColorArray = guiDict.getAsJsonArray("highlightColor");
				        if(highlightColorArray.size()==4)
				        	highlightColor=DocumentModel.colorFromRGBAArray(highlightColorArray);
				        else if (highlightColorArray.size()==3)
				        	highlightColor=DocumentModel.colorFromRGBArray(highlightColorArray);
				    }
		            //check by MMPControl subclass, and alloc/init object
		            if(classString.equals("MMPSlider")){
		                control = new MMPSlider(newFrame);
		                if(guiDict.get("isHorizontal")!=null) 
		                    ((MMPSlider)control).setIsHorizontal( guiDict.get("isHorizontal").getAsBoolean() );
		                if(guiDict.get("range")!=null) {
		                	int range = guiDict.get("range").getAsInt();
		                	if (version < 2) {
		                		 ((MMPSlider)control).setLegacyRange(range);
		                	} else {
		                		 ((MMPSlider)control).setRange(range);
		                	}
		                }
		            }
		            else if(classString.equals("MMPKnob")){
		                control = new MMPKnob(newFrame);
		                Color indicatorColor = Color.WHITE;
		                if(guiDict.get("indicatorColor")!=null){
		                	indicatorColor = DocumentModel.colorFromRGBAArray(guiDict.get("indicatorColor").getAsJsonArray());
		                    ((MMPKnob)control).setIndicatorColor(indicatorColor);
		                }
		                if(guiDict.get("range")!=null) {
		                	int range = guiDict.get("range").getAsInt();
		                	if (version < 2) {
		                		 ((MMPKnob)control).setLegacyRange(range);
		                	} else {
		                		 ((MMPKnob)control).setRange(range);
		                	}
		                }
		            }
		            else if(classString.equals("MMPButton")){
		                control = new MMPButton(newFrame);
		            }
		            else if(classString.equals("MMPToggle")){
		                control = new MMPToggle(newFrame);
		                if(guiDict.get("borderThickness")!=null)
		                    ((MMPToggle)control).setBorderThickness( guiDict.get("borderThickness").getAsInt()  );
		            }
		            else if(classString.equals("MMPLabel")){
		                control = new MMPLabel(newFrame);
		                if(guiDict.get("text")!=null) 
		                    ((MMPLabel)control).setStringValue( guiDict.get("text").getAsString() );
		                if(guiDict.get("textSize")!=null)
		                    ((MMPLabel)control).setTextSize( guiDict.get("textSize").getAsInt()  );
		                if(guiDict.get("textFont")!=null && guiDict.get("textFontFamily")!=null) 
		                    ((MMPLabel)control).setFontFamilyAndName( guiDict.get("textFontFamily").getAsString(), guiDict.get("textFont").getAsString() );
		                if(guiDict.get("androidFont")!=null) 
		                    ((MMPLabel)control).setAndroidFontFileName( guiDict.get("androidFont").getAsString());
		                if(guiDict.get("hAlign") != null) {
		                	((MMPLabel)control).setHorizontalAlignment(guiDict.get("hAlign").getAsInt());
		                }
		                if(guiDict.get("vAlign") != null) {
		                	((MMPLabel)control).setVerticalAlignment(guiDict.get("vAlign").getAsInt());
		                }
		            }
		            else if(classString.equals("MMPXYSlider")){
		                control = new MMPXYSlider(newFrame);
		            }
		            else if(classString.equals("MMPGrid")){
		                control = new MMPGrid(newFrame);
		                if(guiDict.get("dim")!=null){
		                	JsonArray dim = guiDict.get("dim").getAsJsonArray();
		                    ((MMPGrid)control).setDimX( dim.get(0).getAsInt() );
		                    ((MMPGrid)control).setDimY( dim.get(1).getAsInt() );
		                }
		                if(guiDict.get("borderThickness")!=null)
		                    ((MMPGrid)control).setBorderThickness( guiDict.get("borderThickness").getAsInt()  );
		                if(guiDict.get("cellPadding")!=null)
		                    ((MMPGrid)control).setCellPadding( guiDict.get("cellPadding").getAsInt()  );
		                if(guiDict.get("mode")!=null) {
		                	((MMPGrid)control).setMode(guiDict.get("mode").getAsInt());
		                }
		                
		            }
		            else if(classString.equals("MMPPanel")){
		                control = new MMPPanel(newFrame);
		                if(guiDict.get("imagePath")!=null)
		                    ((MMPPanel)control).setImagePath( guiDict.get("imagePath").getAsString() );
		                if(guiDict.get("passTouches")!=null)
		                    ((MMPPanel)control).shouldPassTouches = ( guiDict.get("passTouches").getAsBoolean() );
		                
		            }
		            else if(classString.equals("MMPMultiSlider")){
		                control = new MMPMultiSlider(newFrame);
		                if(guiDict.get("range")!=null)
		                    ((MMPMultiSlider)control).setRange( guiDict.get("range").getAsInt()  );
		                if(guiDict.get("outputMode")!=null)
		                    ((MMPMultiSlider)control).outputMode = ( guiDict.get("outputMode").getAsInt()  );
		            }
		            else if(classString.equals("MMPLCD")){
		                control = new MMPLCD(newFrame);
		            }
		            else if (classString.equals("MMPMultiTouch")) {
		            	control = new MMPMultiTouch(newFrame);
		            }
		            else if (classString.equals("MMPMenu")) {
		            	control = new MMPMenu(newFrame);
		            	if(guiDict.get("title")!=null)
		                    ((MMPMenu)control).setTitleString( guiDict.get("title").getAsString()  );
		            }
		            else if (classString.equals("MMPTable")) {
		            	control = new MMPTable(newFrame);
		            	if(guiDict.get("mode")!=null)
		            		((MMPTable)control).setMode( guiDict.get("mode").getAsInt()  );
		            	if(guiDict.get("selectionColor")!=null) {
		            		Color selectionColor = DocumentModel.colorFromRGBAArray(guiDict.get("selectionColor").getAsJsonArray());
		            		((MMPTable)control).setSelectionColor( selectionColor );
		            	}
		            	if(guiDict.get("displayMode")!=null) {
		            		((MMPTable)control).setDisplayMode(guiDict.get("displayMode").getAsInt()); 
		            	}
		            	if(guiDict.get("displayRangeLo")!=null) {
		            		((MMPTable)control).setDisplayRangeLo(guiDict.get("displayRangeLo").getAsFloat()); 
		            	}
		            	if(guiDict.get("displayRangeHi")!=null) {
		            		((MMPTable)control).setDisplayRangeHi(guiDict.get("displayRangeHi").getAsFloat()); 
		            	}
		            }
		            //no class
		            else { 
		            	control = new MMPUnknown(newFrame);
		            	((MMPUnknown)control).setBadName(classString);
		            	Type collectionType = new TypeToken<Map<String,Object>>(){}.getType();
		            	((MMPUnknown)control).badGUIDict = gson.fromJson(guiDict, collectionType);
		            }
		       
		     //set color
	            // all mecontrol respond to these
	               control.setColor(color);
                   control.setHighlightColor(highlightColor);
	           
	        //address
	            if(guiDict.get("address")!=null){
	                control.setAddress( guiDict.get("address").getAsString() );
	        
	            model.controlArray.add(control);
	        }
		   }
		  }
	    
		return model;
	}
}
