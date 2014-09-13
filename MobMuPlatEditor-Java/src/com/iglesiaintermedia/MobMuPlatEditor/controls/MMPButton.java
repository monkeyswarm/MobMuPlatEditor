package com.iglesiaintermedia.MobMuPlatEditor.controls;

import java.awt.Color;
import java.awt.Rectangle;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.util.ArrayList;

import javax.swing.BorderFactory;
import javax.swing.border.Border;

public class MMPButton extends MMPControl implements MouseListener{
	static final int EDGE_RADIUS = 5;
	int value;
	RoundedPanel buttonPanel;
	
	public MMPButton(MMPButton otherButton){//copy constructor
		this(otherButton.getBounds());//normal constructor
		this.setColor(otherButton.color);
		this.setHighlightColor(otherButton.highlightColor);
		this.address=otherButton.address;
		
	}
	
	public MMPButton(Rectangle frame){
		super();
		address = "/myButton";
		buttonPanel = new RoundedPanel();
		buttonPanel.setCornerRadius(EDGE_RADIUS);
		add(buttonPanel);
		
		this.addMouseListener(this);
		this.addMouseMotionListener(this);
		this.setColor(this.color);
		this.setBounds(frame);
	}
	
	public void setBounds(Rectangle frame){
		super.setBounds(frame);
	    buttonPanel.setBounds(0,0,this.getWidth(), this.getHeight());
	}
	
	public void setColor(Color newColor){
		super.setColor(newColor);
		
		buttonPanel.setBackground(newColor);
		
	}
	
	public void setValue(int inValue){
		value=inValue;
		
		Object[] args = new Object[]{new Integer(value)};
		editingDelegate.sendMessage(address, args);
		
	}
	
	
	
	public void mousePressed(MouseEvent e) {
		//System.out.print(e.getClickCount() + " click(s)");
		super.mousePressed(e);
		
		if(!editingDelegate.isEditing()){
	      setValue(1);
	      buttonPanel.setBackground(highlightColor);
	      
	    }
	}


	@Override
	public void mouseReleased(MouseEvent e) {
		super.mouseReleased(e);
	    if(!editingDelegate.isEditing()){
	    	setValue(0);
	    	buttonPanel.setBackground(color);
	    }
		
	}
	
	//receive messages from PureData (via [send toGUI], routed through the PdWrapper.pd patch), routed from Document via the address to this object
	//for button, any message means a instantaneous touch down and touch up
	//it does not respond to "set" anything
	public void receiveList(ArrayList<Object> messageArray){
		if (messageArray.size()>0 && (messageArray.get(0) instanceof Float || messageArray.get(0) instanceof Integer) ){
	       setValue(1);
	       setValue(0);
	    }
	}
	
	
}
