package com.iglesiaintermedia.MobMuPlatEditor.controls;

import java.awt.Color;
import java.awt.Font;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Rectangle;
import java.awt.RenderingHints;
import java.awt.font.FontRenderContext;
import java.awt.font.LineBreakMeasurer;
import java.awt.font.TextAttribute;
import java.awt.font.TextLayout;
import java.text.AttributedCharacterIterator;
import java.text.AttributedString;
import java.util.ArrayList;


import com.iglesiaintermedia.MobMuPlatEditor.MMPController;

public class MMPLabel extends MMPControl {
	static final String DEFAULT_FONT = "HelveticaNeue";
	static final int HORIZONTAL_PAD = 4;
	static final int VERTICAL_PAD = 1;
	public int textSize;
	private String stringValue;
	public String fontName;
	public String fontFamily;
	public String androidFontFileName; //keep track of the file name ("Roboto-Regular"), which is the key to grab the font
	private boolean showAndroidFont;
	private Font visibleFont;
	private int hAlign, vAlign;
	boolean isHighlighted;

	//copy constructor
	public MMPLabel(MMPLabel otherLabel){ //TODO move stuff to super.
		this(otherLabel.getBounds());//normal constructor
		this.setColor(otherLabel.getColor());
		this.setHighlightColor(otherLabel.getHighlightColor());
		this.address=otherLabel.address;
		this.setTextSize(otherLabel.textSize);
		this.setFontFamilyAndName(otherLabel.fontFamily, otherLabel.fontName);
		this.setAndroidFontFileName(otherLabel.androidFontFileName);
		this.setStringValue(otherLabel.stringValue);
		this.visibleFont = otherLabel.visibleFont;
		this.isHighlighted = otherLabel.isHighlighted;
		this.vAlign = otherLabel.vAlign;
		this.hAlign = otherLabel.hAlign;
		this.showAndroidFont = otherLabel.showAndroidFont;
	}
	
	public MMPLabel(Rectangle frame){
		super();
		address="/myLabel";
		fontFamily="Default";
		fontName = "";
		setAndroidFontFileName("Roboto-Regular");
		textSize = 16;
		setLayout(null);
		visibleFont = new Font(DEFAULT_FONT, Font.PLAIN, textSize);
		setStringValue("my text goes here"); //default text
		
		this.setColor(this.getColor());
		this.setBounds(frame);
		this.addMouseListener(this);
		this.addMouseMotionListener(this);
	}
	
	public void setColor(Color newColor){
		super.setColor(newColor);
		this.repaint();
	}
		
	public void setBounds(Rectangle frame){
		super.setBounds(frame);
	}
	
	public void setStringValue(String inString){
		stringValue = inString;
		this.repaint();
	}

	public String getStringValue() {
		return stringValue;
	}
	
	public void setHorizontalAlignment(int hAlign) { //0 -2 
		this.hAlign = hAlign;
		this.repaint();
	}
	
	public int getHorizontalAlignment() {
		return hAlign;
	}
	
	public void setVerticalAlignment(int vAlign) { //0 -2 
		this.vAlign = vAlign;
		this.repaint();
	}
	
	public int getVerticalAlignment() {
		return vAlign;
	}
	
	public void setTextSize(int inSize){
		textSize = inSize;
		if (!showAndroidFont) {
			if(fontFamily.equals("Default")){
				visibleFont = new Font(DEFAULT_FONT, Font.PLAIN, textSize);
			} else {
				visibleFont = new Font(fontName, Font.PLAIN, textSize);
			}
		} else { //android
			visibleFont = MMPController.androidFontFileToFontMap.get(androidFontFileName).deriveFont(Font.PLAIN,  textSize);
		}
		this.repaint();
	}
	
	public void setFontFamilyAndName(String inFontFamily, String inFontName){ //IOS
		fontName = inFontName;
		fontFamily = inFontFamily;
		if(fontFamily.equals("Default")) {
			visibleFont = (new Font(DEFAULT_FONT, Font.PLAIN, textSize));
		} else{
			visibleFont = new Font(fontName, Font.PLAIN, textSize);
		}
		this.repaint();
	}
	
	public void setAndroidFontFileName(String fontFileName) {
		androidFontFileName = fontFileName;
		if (showAndroidFont) { //this is called on patch load...?
			visibleFont = MMPController.androidFontFileToFontMap.get(fontFileName).deriveFont(Font.PLAIN,  textSize);
			this.repaint();
		}
	}
	
	public void showAndroidFont(boolean showAndroidFont) {
		this.showAndroidFont = showAndroidFont;
		
		//TODO package this along with similar logic.
		if (!showAndroidFont) {
			if(fontFamily.equals("Default")) {
				visibleFont = new Font(DEFAULT_FONT, Font.PLAIN, textSize);
			} else {
				visibleFont = new Font(fontName, Font.PLAIN, textSize);
			}
		} else { //android
			visibleFont = MMPController.androidFontFileToFontMap.get(androidFontFileName).deriveFont(Font.PLAIN,  textSize);
			//new Font(androidFontName, Font.PLAIN, textSize));
		}
		this.repaint();
	}
	
	// Ignore touches
	public boolean contains(int x, int y) {
		return editingDelegate.isEditing() ? super.contains(x, y) : false;
	}
	
	public void receiveList(ArrayList<Object> messageArray){
		super.receiveList(messageArray);

		// Ignore "enable"
		if (messageArray.size()>=2 && 
				(messageArray.get(0) instanceof String) && 
				messageArray.get(0).equals("enable") && 
				(messageArray.get(1) instanceof Float)) {
			return;
		}
		if (messageArray.size()==2 && (messageArray.get(0) instanceof String) && messageArray.get(0).equals("highlight")){
	    	
	    	if(messageArray.get(1) instanceof Float ){
	    		float val = ((Float)(messageArray.get(1))).floatValue();
	    		isHighlighted = (val > 0);
	    		this.repaint();
	    	}
	    	else if (messageArray.get(1) instanceof Integer){
	    		int val = ((Integer)(messageArray.get(1))).intValue();
	    		isHighlighted = (val > 0);
	    		this.repaint();
	    	} 
	    }
	    
	    else{ //otherwise it is a new text...concatenate all elements in list into a string
	    	String newString = "";
	    	for(Object ob: messageArray){
	    		if(ob instanceof String) newString = newString+(String)ob;
	    		else if(ob instanceof Float) newString+=(String.format("%.3f",((Float)(ob)).floatValue()) );
	    		else if(ob instanceof Integer) newString+=(String.format("%d",((Integer)(ob)).intValue()) );
	    		newString = newString+" ";
	    	}
	    	setStringValue(newString);
	    }
	}
	
	public void paint(Graphics g) {
	    AttributedString attributedString = new AttributedString(stringValue);
	    attributedString.addAttribute(TextAttribute.FONT, visibleFont);
	    // color based on enabled, highlight state
	    Color color = this.isEnabled() ? 
	    			(isHighlighted ? this.getHighlightColor() : this.getColor()) :
	    			(isHighlighted ? this.getDisabledHighlightColor() : this.getDisabledColor());
	    attributedString.addAttribute(TextAttribute.FOREGROUND, color);

	    super.paint(g);
	    Graphics2D g2d = (Graphics2D) g;
	    
	    g2d.setRenderingHint( //todo move?
	            RenderingHints.KEY_ANTIALIASING,
	            RenderingHints.VALUE_ANTIALIAS_ON);
	    g2d.setRenderingHint(
	            RenderingHints.KEY_TEXT_ANTIALIASING,
	            RenderingHints.VALUE_TEXT_ANTIALIAS_ON);

	    int width = getSize().width - (2*HORIZONTAL_PAD);
	    
	    FontRenderContext fontRenderContext = g2d.getFontRenderContext();
	    //derive height
	    float totalHeight = 0;
	    AttributedCharacterIterator characterIterator;
    	LineBreakMeasurer measurer;
 
	    if (vAlign > 0) { //derive total height if vAlign is center or bottom.
	    	characterIterator = attributedString.getIterator();
	    	measurer = new LineBreakMeasurer(characterIterator, fontRenderContext);
	    	while (measurer.getPosition() < characterIterator.getEndIndex()) {
	    		// check for newline
	    		int next = measurer.nextOffset(width);
	    		int limit = next;
	    		boolean didEndInSpace = false;
	    		if (limit <= stringValue.length()) {
	    			for (int i = measurer.getPosition(); i < next; ++i) {
	    				char c = stringValue.charAt(i);
	    				if (c == '\n') {
	    					limit = i + 1;
	    					break;
	    				}
	    			}
	    		}
	    		// if last character is a space, strip it off.
		    	  if (stringValue.charAt(next-1)==' ') {
		    		  limit--;
		    		  didEndInSpace = true;
		    	  }
		    	  
	    		// get layout for next line
	    		TextLayout textLayout = measurer.nextLayout(width, limit, false);
	    		if (didEndInSpace) measurer.setPosition(measurer.getPosition()+1); // consume space
	    		totalHeight += textLayout.getAscent() + textLayout.getDescent() + textLayout.getLeading();
	    	}
	    }
	  
		//actual layout
	    float currentY = VERTICAL_PAD;
	    switch(vAlign) {
	    case 0: currentY=VERTICAL_PAD;break; //top
	    case 1: currentY=(getHeight()-(2*VERTICAL_PAD)-totalHeight)/2.0f + VERTICAL_PAD; break; //center
	    case 2: currentY=getHeight()-VERTICAL_PAD-totalHeight;break; //bottom
	    }
	    // if placed above top, clip to top.
	    if (currentY < VERTICAL_PAD )currentY = VERTICAL_PAD;
	    
	    characterIterator = attributedString.getIterator();
	    measurer = new LineBreakMeasurer(characterIterator, fontRenderContext);
	    while (measurer.getPosition() < characterIterator.getEndIndex()) {
	    	// check for newline
	    	int next = measurer.nextOffset(width);
	    	int limit = next;
	    	boolean didEndInSpace = false;
	    	if (limit <= stringValue.length()) {
	    	  for (int i = measurer.getPosition(); i < next; ++i) {
	    	    char c = stringValue.charAt(i);
	    	    if (c == '\n') {
	    	      limit = i + 1;
	    	      break;
	    	    }
	    	  }
	    	  // if last character is a space, strip it off.
	    	  if (stringValue.charAt(next-1)==' ') {
	    		  limit--;
	    		  didEndInSpace = true;
	    	  }
	    	}
	    	
	     // get layout for next line
	      TextLayout textLayout = measurer.nextLayout(width, limit, false);
	      if (didEndInSpace) measurer.setPosition(measurer.getPosition()+1); // consume space
	      currentY += textLayout.getAscent();
	      float x = HORIZONTAL_PAD;
	      switch(hAlign) {
	      	case 0: x = HORIZONTAL_PAD; break; //left
	      	case 1: x = (width - textLayout.getAdvance())/2 + HORIZONTAL_PAD; break; //center
	      	case 2: x = width - textLayout.getAdvance() + HORIZONTAL_PAD; break; //right
	      }
	      textLayout.draw(g2d, x, currentY);
	      currentY += textLayout.getDescent() + textLayout.getLeading();
	    }
	  }
}
