package com.iglesiaintermedia.MobMuPlatEditor.controls;

import java.awt.Color;
import java.awt.Container;
import java.awt.Font;
import java.awt.Point;
import java.awt.Rectangle;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.awt.event.MouseMotionListener;

import java.util.ArrayList;

import javax.swing.BorderFactory;
import javax.swing.JPanel;
import javax.swing.JTextArea;
import javax.swing.SwingUtilities;

public class MMPLabel extends MMPControl {
	static final String DEFAULT_FONT = "HelveticaNeue";
	static final int PAD = 5;
	JTextArea textView;
	JTextArea androidTextView;
	public int textSize;
	public String stringValue;
	public String fontName;
	public String fontFamily;
	public String androidFontName;
	private boolean _showAndroidFont;
	JPanel overPanel;
	
	MMPControl underControl;
	
	//copy constructor
	public MMPLabel(MMPLabel otherLabel){
		this(otherLabel.getBounds());//normal constructor
		this.setColor(otherLabel.color);
		this.setHighlightColor(otherLabel.highlightColor);
		this.address=otherLabel.address;
		this.setTextSize(otherLabel.textSize);
		this.setFontFamilyAndName(otherLabel.fontFamily, otherLabel.fontName);
		this.setAndroidFontName(otherLabel.androidFontName);
		this.setStringValue(otherLabel.stringValue);
		
		
	}
	
	public MMPLabel(Rectangle frame){
		super();
		address="/myLabel";
		fontFamily="Default";
		fontName = "";
		androidFontName = "Roboto-Regular";
		textSize = 16;
		stringValue = "my text goes here";
		setLayout(null);
		
		overPanel = new JPanel();//hack: textView was sending constant mouse dragged events (on mouse held still while dragging), rather than just one per drag
		overPanel.setOpaque(false);
		add(overPanel);
		
		textView = new JTextArea(stringValue);
		//textView.setBounds(0,0,getWidth(), getHeight());
		textView.setForeground(color);
		textView.setFont(new Font(DEFAULT_FONT, Font.PLAIN, textSize));
		textView.setOpaque(false);
		textView.setBackground(new Color(0,0,0,0));//redundant on aqua, neccesary on nimubs
		textView.setBorder(BorderFactory.createEmptyBorder());//redundant on aqua, neceesary on nimbus
		textView.setWrapStyleWord(true);
		textView.setLineWrap(true);
		textView.setEditable(false);
		for(MouseListener ml: textView.getMouseListeners())textView.removeMouseListener(ml);
		for(MouseMotionListener ml: textView.getMouseMotionListeners())textView.removeMouseMotionListener(ml);
		
		add(textView);
		
		
		
		this.setColor(this.color);
		this.setBounds(frame);
		
		//textview was intercepting mouse, so set its listener to me
		//textView.addMouseListener(this);
		//textView.addMouseMotionListener(this);
		overPanel.addMouseListener(this);
		overPanel.addMouseMotionListener(this);
		
	}
	
	public void setColor(Color newColor){
		super.setColor(newColor);
		textView.setForeground(newColor);
	}
		
	public void setBounds(Rectangle frame){
		super.setBounds(frame);
		textView.setBounds(PAD,0,this.getWidth()-PAD, this.getHeight());
		overPanel.setBounds(0,0,getWidth(), getHeight());
	}
	
	public void setStringValue(String inString){
		stringValue = inString;
		textView.setText(stringValue);
	}
	
	public void setTextSize(int inSize){
		//System.out.print("\nlab setText fam:"+fontFamily);
		textSize = inSize;
		if (!_showAndroidFont) {
			if(fontFamily.equals("Default"))textView.setFont(new Font(DEFAULT_FONT, Font.PLAIN, textSize));
			else textView.setFont(new Font(fontName, Font.PLAIN, textSize));
		} else { //android
			textView.setFont(new Font(androidFontName, Font.PLAIN, textSize));
		}
		
	}
	
	public void setFontFamilyAndName(String inFontFamily, String inFontName){
		fontName = inFontName;
		fontFamily = inFontFamily;
		//System.out.print("\nlab setFontfamandname fam:"+fontFamily);
		if(fontFamily.equals("Default"))textView.setFont(new Font(DEFAULT_FONT, Font.PLAIN, textSize));
		else{
			//System.out.print("\nHERE");
			Font newFont = new Font(fontName, Font.PLAIN, textSize);
			textView.setFont(newFont);
			
			//exists on system
			/*if(newFont!=null) textView.setFont(new Font(fontName, Font.PLAIN, textSize));
			
			else{
				
			
				try{
					InputStream is = this.getClass().getResourceAsStream("Zapfino.ttf");
					System.out.print("\ninputstream nonnull? "+(is!=null));
					Font uniFont=Font.createFont(Font.TRUETYPE_FONT,is);
					Font f = uniFont.deriveFont(24f);
					
					textView.setFont(f);
					System.out.print("\nsucess setting, font object nonnull? "+(f!=null));
				}
				catch(Exception e){
					System.out.print("\nexception setting");
					}
			//}
			 */
			
		}
	}
	
	
	
	public void setAndroidFontName(String fontName) {
		androidFontName = fontName;
		if (_showAndroidFont) { //this is called on patch load...
			Font newFont = new Font(fontName, Font.PLAIN, textSize);
			textView.setFont(newFont);
		}
	}
	
	public void showAndroidFont(boolean showAndroidFont) {
		_showAndroidFont = showAndroidFont;
		
		Font newFont = new Font(_showAndroidFont ? androidFontName : fontName, Font.PLAIN, textSize);
		textView.setFont(newFont);
	}
	
	public void mouseClicked(MouseEvent e) {
    	super.mouseClicked(e);
    	mouseHelper(e);
    	
	}
	
	public void mousePressed(MouseEvent e) {
		//System.out.print(e.getClickCount() + " click(s)");
		super.mousePressed(e);
		mouseHelper(e);
	}
	
	void mouseHelper(MouseEvent e){
		if(!editingDelegate.isEditing()){
			Point labelPoint = e.getPoint();
	        Container container = getParent();
	        Point containerPoint = SwingUtilities.convertPoint(this,
	        		labelPoint, container);
	        //System.out.print("\ncontainerPoint "+containerPoint.x+" "+containerPoint.y );
	       
	        //awful, scroll through all controls...SO WASTEFUL
	        //also, do it in REVERSE order in order to get the view that is underneath...
	        //for(MMPControl control : editingDelegate.documentModel.controlArray){
	        int len = editingDelegate.documentModel.controlArray.size();
	        for (int i = len-1; i >= 0; i--) {
	        	MMPControl control = editingDelegate.documentModel.controlArray.get(i);
	         	if(control==this)continue;//ignore me
	        	//System.out.print("\nother bounds "+control.getX()+" "+control.getY()+" "+control.getWidth()+" "+control.getHeight());
	        	if(control.getBounds().contains(containerPoint)){
	        		//System.out.print("\nfind control "+control.address);
	        		Point componentPoint = SwingUtilities.convertPoint(
	                        container, containerPoint, control);
	                control.dispatchEvent(new MouseEvent(control, e
	                        .getID(), e.getWhen(), e.getModifiers(),
	                        componentPoint.x, componentPoint.y, e
	                                .getClickCount(), e.isPopupTrigger()));
	                underControl=control;
	                break;
	        	}
	        }
	        
		}
	}
	
	public void mouseDragged(MouseEvent e) {
		//System.out.print(e.getClickCount() + " click(s)");
		//System.out.print("\nlabel drag src "+e.getSource().getClass().getName());
		super.mouseDragged(e);
		
		if(!editingDelegate.isEditing()){
			if(underControl!=null){
			Point labelPoint = e.getPoint();
	        Container container = getParent();
	        Point containerPoint = SwingUtilities.convertPoint(this,
	        		labelPoint, container);
	        //System.out.print("\ncontainerPoint "+containerPoint.x+" "+containerPoint.y );
	       
	        //awful, scroll through all controls...SO WASTEFUL
	        		//System.out.print("\nfind control "+control.address);
	        		Point componentPoint = SwingUtilities.convertPoint(
	                        container, containerPoint, underControl);
	        		underControl.dispatchEvent(new MouseEvent(underControl, e
	                        .getID(), e.getWhen(), e.getModifiers(),
	                        componentPoint.x, componentPoint.y, e
	                                .getClickCount(), e.isPopupTrigger()));
	        	}
		}
	        
	        
		
	}
	
	public void mouseReleased(MouseEvent e) {
		//System.out.print(e.getClickCount() + " click(s)");
		super.mouseReleased(e);
		
		if(!editingDelegate.isEditing()){
			if(underControl!=null){
			Point labelPoint = e.getPoint();
	        Container container = getParent();
	        Point containerPoint = SwingUtilities.convertPoint(this,
	        		labelPoint, container);
	       
	        	Point componentPoint = SwingUtilities.convertPoint(
	                        container, containerPoint, underControl);
	        	underControl.dispatchEvent(new MouseEvent(underControl, e
	                        .getID(), e.getWhen(), e.getModifiers(),
	                        componentPoint.x, componentPoint.y, e
	                                .getClickCount(), e.isPopupTrigger()));
	        	}
	        
	        
		}
		underControl=null;
	}
	
	public void receiveList(ArrayList<Object> messageArray){
		//System.out.print("label rec on edt? "+SwingUtilities.isEventDispatchThread());
		
		//if message preceded by "set", then set "sendVal" flag to NO, and strip off set and make new messages array without it
	    if (messageArray.size()==2 && (messageArray.get(0) instanceof String) && messageArray.get(0).equals("highlight")){
	    	
	    	if(messageArray.get(1) instanceof Float ){
	    		float val = ((Float)(messageArray.get(1))).floatValue();
	    		if(val>0)textView.setForeground(highlightColor);
	    		else textView.setForeground(color);
	    	}
	    	else if (messageArray.get(1) instanceof Integer){
	    		int val = ((Integer)(messageArray.get(1))).intValue();
	    		if(val>0)textView.setForeground(highlightColor);
	    		else textView.setForeground(color);
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
	    	//System.out.print("\n"+newString);
	    	setStringValue(newString);
	    }
	}
}
