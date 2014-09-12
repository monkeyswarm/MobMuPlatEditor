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
import javax.swing.border.Border;

public class MMPToggle extends MMPControl {
	static final int EDGE_RADIUS = 5;
	//static final int BORDER_WIDTH = 4;
	static final Color clearColor = new Color(0,0,0,0);
	int value;
	RoundedPanel togglePanel;
	RoundedBorderPanel borderPanel;
	public int borderThickness;
	
	public MMPToggle(MMPToggle otherToggle){//copy constructor
		this(otherToggle.getBounds());//normal constructor
		this.setColor(otherToggle.color);
		this.setHighlightColor(otherToggle.highlightColor);
		this.address=otherToggle.address;
		this.setBorderThickness(otherToggle.borderThickness);
	}
	
	public MMPToggle(Rectangle frame){
		super();
		address = "/myToggle";
		borderThickness=4;
		borderPanel = new RoundedBorderPanel();
		add(borderPanel);
		
		togglePanel = new RoundedPanel();
		togglePanel.setCornerRadius(EDGE_RADIUS);
		//togglePanel.setOpaque(false);//clear
		togglePanel.setBackground(clearColor);
		add(togglePanel);
		
		this.addMouseListener(this);
		this.addMouseMotionListener(this);
		this.setColor(this.color);
		this.setBounds(frame);
	}
	
	public void setBounds(Rectangle frame){
		super.setBounds(frame);
		borderPanel.setBounds(0,0,this.getWidth(), this.getHeight());
		togglePanel.setBounds(borderThickness/2, borderThickness/2, getWidth()-borderThickness, getHeight()-borderThickness);
	}
	
	public void setColor(Color newColor){
		super.setColor(newColor);
		/*Border border = BorderFactory.createLineBorder(newColor, BORDER_WIDTH);
		borderView.setBorder(border);*/
		//togglePanel.setBackground(newColor);
		
		this.repaint();//repaint border
	}
	
	public void setBorderThickness(int inThick){
		System.out.print("\nsetbt "+inThick);
		borderThickness = inThick;
		//borderPanel.repaint();
		this.setBounds(this.getBounds());
		this.repaint();
	}
	
	public void setValue(int inValue){
		value=inValue;
		
		if(value==1)togglePanel.setBackground(highlightColor);//setOpaque(true);
	      else togglePanel.setBackground(clearColor);
		//this.repaint();
		
	}
	
	public void sendValue(){
		Object[] args = new Object[]{new Integer(value)};
		editingDelegate.sendMessage(address, args);
	}
	
	
	
	
	public void mousePressed(MouseEvent e) {
		//System.out.print(e.getClickCount() + " click(s)");
		super.mousePressed(e);
		
		if(!editingDelegate.isEditing()){
	      setValue(1-value);
	      sendValue();
	      
	      
	    }
	}

	class RoundedBorderPanel extends JPanel{
		
		public RoundedBorderPanel(){
			super();
			setOpaque(false);
		}
		
		protected void paintBorder(Graphics g) {
			//int borderThickness=1;
	        //System.out.print("\npaintBorder "+borderThickness);
			if(borderThickness>0){
	        Graphics2D g2 = (Graphics2D)g.create();
	        g2.setColor(color);
	        g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
	        g2.setStroke(new BasicStroke(borderThickness,BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
	        g2.drawRoundRect(borderThickness/2, borderThickness/2, getWidth()-borderThickness-1, getHeight()-borderThickness-1, EDGE_RADIUS*2, EDGE_RADIUS*2);
	   
			}
		}
			
	}
	
	//receive messages from PureData (via [send toGUI], routed through the PdWrapper.pd patch), routed from Document via the address to this object
	public void receiveList(ArrayList<Object> messageArray){
		boolean sendVal  = true;
		//if message preceded by "set", then set "sendVal" flag to NO, and strip off set and make new messages array without it
	    if (messageArray.size()>0 && (messageArray.get(0) instanceof String) && messageArray.get(0).equals("set") ){
	    	messageArray = new ArrayList<Object>(messageArray.subList(1, messageArray.size() ) );//todo just get List and use, rather than make arraylist<obj>
	    	sendVal=false;
	    }
	    //set new value
	    //System.out.print("\nms size "+messageArray.size()+" "+messageArray.get(0));
	    if (messageArray.size()>0 && (messageArray.get(0) instanceof Integer) ){
	    	int newVal = ((Integer)(messageArray.get(0))).intValue();
	        if(newVal>0)setValue(1);
	        else setValue(0);
	        if(sendVal)sendValue();
	    }
	    if (messageArray.size()>0 && (messageArray.get(0) instanceof Float) ){
	    	float newVal = ((Float)(messageArray.get(0))).floatValue() ;
	    	if(newVal>0)setValue(1);
	    	else setValue(0);
	        if(sendVal)sendValue();
	    }

	}
}

	

