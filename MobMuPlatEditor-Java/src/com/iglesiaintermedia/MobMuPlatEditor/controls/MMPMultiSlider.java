package com.iglesiaintermedia.MobMuPlatEditor.controls;

import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Rectangle;
import java.awt.RenderingHints;
import java.awt.event.MouseEvent;
import java.util.ArrayList;

import javax.swing.BorderFactory;
import javax.swing.JPanel;

public class MMPMultiSlider extends MMPControl{
	static int SLIDER_HEIGHT=20;
	static int CORNER_RADIUS=4;
	static int BORDER_WIDTH=2;
	
	JPanel boxPanel;
	ArrayList<RoundedPanel> touchPanelArray;
	ArrayList<Float> valueArray;
	float headWidth;
	int currHeadIndex;
	public int range;
	public int outputMode; //0=all values, 1=individual element index+value
	
	public MMPMultiSlider(MMPMultiSlider otherMS){
		//this.MMPMultiSlider(otherMS.getBounds());
		this(otherMS.getBounds());//normal constructor
		this.setColor(otherMS.color);
		this.setHighlightColor(otherMS.highlightColor);
		this.address=otherMS.address;
		this.setRange(otherMS.range);
	}
	
	public MMPMultiSlider(Rectangle frame){
		super();
		address="/myMultiSlider";
		
		boxPanel = new JPanel();
		boxPanel.setOpaque(false);
		add(boxPanel);
		
		setRange(8);
		
		this.addMouseListener(this);
		this.addMouseMotionListener(this);
		this.setColor(color);
		this.setBounds(frame);
	}
	
	public void setRange(int inRange){
		range=inRange;
		
		if(range<=0)range=1;
		if(range>1000)range=1000;

		//remove and remake headViewArray and _valueArray
	    if(touchPanelArray!=null)
	    	for(RoundedPanel head : touchPanelArray) head.getParent().remove(head);
	    
	    touchPanelArray = new ArrayList<RoundedPanel>();
		valueArray = new ArrayList<Float>();    	
		
		headWidth = (float)getWidth()/range;//TODO fractional?
		
	    for(int i=0;i<range;i++){
	    	valueArray.add(new Float(0));
	    	RoundedPanel headPanel = new RoundedPanel();
	    	headPanel.setBounds( (int)(i*headWidth), getHeight()-SLIDER_HEIGHT, (int)headWidth, SLIDER_HEIGHT );
	    	headPanel.setBackground(color);
	    	headPanel.setCornerRadius(CORNER_RADIUS);
	    	touchPanelArray.add(headPanel);
	    	add(headPanel);
	      
	    }
	    
	    //push boxPanel back
	    setComponentZOrder(boxPanel, getComponentCount()-1);

	    this.repaint();
	}
	
	public void setBounds(Rectangle frame){
		super.setBounds(frame);
		headWidth=(float)getWidth()/range;
	    //box.frame=CGRectMake(0, SLIDER_HEIGHT/2, frameRect.size.width, frameRect.size.height-SLIDER_HEIGHT);
	    boxPanel.setBounds(0, SLIDER_HEIGHT/2, getWidth(), getHeight()-SLIDER_HEIGHT);
		for(int i=0;i<touchPanelArray.size();i++){
	        RoundedPanel currHead = touchPanelArray.get(i);// objectAtIndex:i];
	        currHead.setBounds( (int)(i*headWidth), getHeight()-SLIDER_HEIGHT, (int)headWidth, SLIDER_HEIGHT );
	    }
	}
	
	public void setColor(Color inColor){
		super.setColor(inColor);
		boxPanel.setBorder(BorderFactory.createLineBorder(inColor, BORDER_WIDTH));
		for(RoundedPanel rp: touchPanelArray)rp.setBackground(inColor);
	}
	
	void sendValue(){
		int count = valueArray.size();
		Object[] args = new Object[count];
		for(int i=0;i<count;i++)args[i]=valueArray.get(i);
		editingDelegate.sendMessage(address, args);
	}
	
	void sendSliderIndexAndValue(int index, float value){
		Object[] args = new Object[2];
		args[0]=Integer.valueOf(index);
		args[1]=Float.valueOf(value);
		editingDelegate.sendMessage(address, args);
	}
	
	//on receive a new list into valueArray, redraw the slider positions
	/*void updateThumbs(){
		for(int i=0;i<valueArray.size();i++){
	        Float val = valueArray.get(i);
	        RoundedPanel currHead = touchPanelArray.get(i);
	        currHead.setBounds( (int)(i*headWidth), (int)((1.0f-val.floatValue())*(getHeight()-SLIDER_HEIGHT)), (int)headWidth, SLIDER_HEIGHT);
		}
	}*/
	
	void updateThumbs(int start, int end){//From:(int)start to:(int)end{
		  for(int i=start;i<=end;i++){
		    Float val = valueArray.get(i);
		    RoundedPanel currHead = touchPanelArray.get(i);
		    currHead.setBounds( (int)(i*headWidth), (int)((1.0f-val.floatValue())*(getHeight()-SLIDER_HEIGHT)), (int)headWidth, SLIDER_HEIGHT);
		  }
		}

	void updateThumbs(){
		  this.updateThumbs(0,valueArray.size()-1);
	}
	
	public void mousePressed(MouseEvent e) {
		super.mousePressed(e);
		
	    if(!editingDelegate.isEditing()){
	       int headIndex = (int)(e.getX()/headWidth);//find out which slider is touched
	       headIndex = Math.max(Math.min(headIndex, range-1), 0);//clip to range
	    	
	       float clippedPointY = Math.max(Math.min(e.getY(), getHeight()-SLIDER_HEIGHT/2), SLIDER_HEIGHT/2);
	       float headVal = 1.0f-( (clippedPointY-SLIDER_HEIGHT/2) / (getHeight() - SLIDER_HEIGHT) );

	       valueArray.set(headIndex, Float.valueOf(headVal));
	       
	       if (outputMode==0) {
	    	   sendValue();
	       } else { //touchMode 1
	    	   sendSliderIndexAndValue(headIndex, headVal);
	       }
	       //update position
	       RoundedPanel currHead = touchPanelArray.get(headIndex);
	       currHead.setBounds((int)(headIndex*headWidth), (int)(clippedPointY-SLIDER_HEIGHT/2), (int)headWidth, SLIDER_HEIGHT);
	        currHead.setBackground(highlightColor);
	       currHeadIndex=headIndex;
	        
	    }
	}
	
	public void mouseDragged(MouseEvent e){
		super.mouseDragged(e);
		if(!editingDelegate.isEditing()){
		       int headIndex = (int)(e.getX()/headWidth);//find out which slider is touched
		       headIndex = Math.max(Math.min(headIndex, range-1), 0);//clip to range
		    	
		       float clippedPointY = Math.max(Math.min(e.getY(), getHeight()-SLIDER_HEIGHT/2), SLIDER_HEIGHT/2);
		       float headVal = 1.0f-( (clippedPointY-SLIDER_HEIGHT/2) / (getHeight() - SLIDER_HEIGHT) );

		       valueArray.set(headIndex, Float.valueOf(headVal));
		       
		       
		       //update position
		       RoundedPanel currHead = touchPanelArray.get(headIndex);
		       currHead.setBounds((int)(headIndex*headWidth), (int)(clippedPointY-SLIDER_HEIGHT/2), (int)headWidth, SLIDER_HEIGHT);
		        
		       //also set elements between prev touch and move, to avoid "skipping" on fast drag
		       if(Math.abs(headIndex-currHeadIndex)>1){
		         int minTouchIndex = Math.min(headIndex, currHeadIndex);
		         int maxTouchIndex = Math.max(headIndex, currHeadIndex);
		         
		         float minTouchedValue = valueArray.get(minTouchIndex).floatValue();
		         float maxTouchedValue = valueArray.get(maxTouchIndex).floatValue();
		         //NSLog(@"skip within %d (%.2f) to %d(%.2f)", minTouchIndex, [[_valueArray objectAtIndex:minTouchIndex] floatValue], maxTouchIndex, [[_valueArray objectAtIndex:maxTouchIndex] floatValue]);
		         for(int i=minTouchIndex+1;i<maxTouchIndex;i++){
		           float percent = ((float)(i-minTouchIndex))/(maxTouchIndex-minTouchIndex);
		           float interpVal = (maxTouchedValue - minTouchedValue) * percent  + minTouchedValue ;
		           //NSLog(@"%d %.2f %.2f", i, percent, interpVal);
		           valueArray.set(i, Float.valueOf(interpVal));
		           if (outputMode==1) {
		        	   sendSliderIndexAndValue(i, interpVal);
		           }
		         }
		        this.updateThumbs(minTouchIndex+1, maxTouchIndex-1);
		       }
		       
		       if (outputMode==1) {
	        	   sendSliderIndexAndValue(headIndex, headVal);
	           } else {
	        	   sendValue();
	           }
		       
		       if(headIndex!=currHeadIndex){//dragged to new head
		    	   RoundedPanel prevHead = touchPanelArray.get(currHeadIndex);
		            prevHead.setBackground(color);// .layer.backgroundColor=[MMPControl CGColorFromNSColor:self.color];//change prev head back
		            currHead.setBackground(highlightColor);//.layer.backgroundColor=[MMPControl CGColorFromNSColor:self.highlightColor];
		            currHeadIndex=headIndex;
		        }

		       
		    }
	
	}


	@Override
	public void mouseReleased(MouseEvent e) {
		super.mouseReleased(e);
	    if(!editingDelegate.isEditing()){
	    	 for(RoundedPanel rp : touchPanelArray)rp.setBackground(color);//todo: just set currhead?
	    }
		
	}
	
	//receive messages from PureData (via [send toGUI], routed through the PdWrapper.pd patch), routed from Document via the address to this object
	public void receiveList(ArrayList<Object> messageArray){
		boolean sendVal  = true;
		//if message preceded by "set", then set "sendVal" flag to NO, and strip off set and make new messages array without it
	    if (messageArray.size()>0 && (messageArray.get(0) instanceof String) && messageArray.get(0).equals("set") ){
	        messageArray.remove(0);
	        sendVal=false;
	    }
	    
	    if (messageArray.size()>1 && (messageArray.get(0) instanceof String) && messageArray.get(0).equals("allVal")) {
	        
	        float val = ((Float) messageArray.get(1)).floatValue();
	        for(int i=0;i<messageArray.size();i++){
	          messageArray.set(i, new Float(val));
	        }
	        this.updateThumbs();
	        if(sendVal)sendValue();
	      }
	    else if(messageArray.size()>0){
	    	ArrayList<Float> newValueArray = new ArrayList<Float>();
	    	
	    	//get floats
	    	for(int i=0;i<messageArray.size();i++){
	    		Object ob = messageArray.get(i);
	    		if(ob instanceof Float)newValueArray.add((Float)ob);
	    		if(ob instanceof Integer)newValueArray.add(new Float(((Integer)ob).intValue()));
	    	}
	    	if(newValueArray.size()!=range)setRange(newValueArray.size());
	    	valueArray = newValueArray;
	    	//clip
	    	for(int i=0;i<valueArray.size();i++){
	    		Float f = valueArray.get(i);
	    		if(f.floatValue()<0 || f.floatValue()>1 ){
	                float newFloat = Math.max(Math.min(f.floatValue(), 1), 0);//clip
	                valueArray.set(i, new Float(newFloat));
	            }
	    	}
	    	
	    	updateThumbs();
	    	if(sendVal)sendValue();
	    	
	    }
	    
	}

}
