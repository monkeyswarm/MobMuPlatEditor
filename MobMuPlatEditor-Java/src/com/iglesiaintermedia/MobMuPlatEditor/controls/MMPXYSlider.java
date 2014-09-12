package com.iglesiaintermedia.MobMuPlatEditor.controls;

import java.awt.Color;
import java.awt.Rectangle;
import java.awt.event.MouseEvent;
import java.util.ArrayList;

import javax.swing.BorderFactory;
import javax.swing.JPanel;
import javax.swing.border.Border;

public class MMPXYSlider extends MMPControl {
	static final int LINE_WIDTH = 4;
	
	private float valueX, valueY;
	
	private JPanel borderView;
	private JPanel cursorHorizView, cursorVertView;
	//protected Border border;// = BorderFactory.createLineBorder(Color.black, 5);
	
	public int range;
	public boolean isHorizontal;
	private ArrayList<JPanel> tickViewArray;
	float value;
	
	//copy constructor
	public MMPXYSlider(MMPXYSlider otherXYSlider){
		this(otherXYSlider.getBounds());//normal constructor
		this.setColor(otherXYSlider.color);
		this.setHighlightColor(otherXYSlider.highlightColor);
		this.address=otherXYSlider.address;
	}
	
	public MMPXYSlider(Rectangle frame){
		super();
		address="/myXYSlider";
		
		borderView = new JPanel();
		borderView.setOpaque(false);
		this.add(borderView);
		
		cursorHorizView = new JPanel();
		this.add(cursorHorizView);
		cursorVertView = new JPanel();
		this.add(cursorVertView);
		
		
		this.addMouseListener(this);
		this.addMouseMotionListener(this);
		
		this.setColor(this.color);
		this.setBounds(frame);
		this.setValue(.5f,.5f);
		
	}
	
	public void setBounds(Rectangle frame){
		super.setBounds(frame);
	    //need to redo border?
		
		borderView.setBounds(0,0,this.getWidth(), this.getHeight());
	    cursorHorizView.setBounds(0, (int)(valueY*this.getHeight()-LINE_WIDTH/2), this.getWidth(), LINE_WIDTH);
	    cursorVertView.setBounds((int)(valueX*this.getWidth()-LINE_WIDTH/2), 0, LINE_WIDTH, this.getHeight() );   
	    
	}
	
	public void setColor(Color newColor){
		super.setColor(newColor);
		Border border = BorderFactory.createLineBorder(newColor, LINE_WIDTH);
		borderView.setBorder(border);
		cursorHorizView.setBackground(newColor);
		cursorVertView.setBackground(newColor);
		
		this.repaint();//without this, horiz view peeked on top of the edithandle border..
	}
	
	public void setValue(float inX, float inY){
		valueX = inX;
		valueY = inY;
		
		cursorHorizView.setBounds(0, (int)((1.0-valueY)*this.getHeight()-LINE_WIDTH/2), this.getWidth(), LINE_WIDTH);
		cursorVertView.setBounds((int)(valueX*this.getWidth()-LINE_WIDTH/2), 0, LINE_WIDTH, this.getHeight()); 
		
	}
	
	

	
	//send OSC message out
	public void sendValue(){
	   Object[] args = new Object[]{new Float(valueX), new Float(valueY)};
		editingDelegate.sendMessage(address, args);
	}

	
	
	public void mousePressed(MouseEvent e) {
		//System.out.print(e.getClickCount() + " click(s)");
		super.mousePressed(e);
		
		if(!editingDelegate.isEditing()){
	       borderView.setBorder(BorderFactory.createLineBorder(highlightColor, LINE_WIDTH)); 
	        cursorHorizView.setBackground(highlightColor);
	        cursorVertView.setBackground(highlightColor);  
	        this.mouseDragged(e);
	    }
	}

	@Override
	public void mouseClicked(MouseEvent e) {
	
		
	}

	@Override
	public void mouseEntered(MouseEvent e) {
		// TODO Auto-generated method stub
		
	}

	@Override
	public void mouseExited(MouseEvent e) {
		// TODO Auto-generated method stub
		
	}

	@Override
	public void mouseReleased(MouseEvent e) {
		super.mouseReleased(e);
	    if(!editingDelegate.isEditing()){
	    	 borderView.setBorder(BorderFactory.createLineBorder(color, LINE_WIDTH)); 
		     cursorHorizView.setBackground(color);
		     cursorVertView.setBackground(color);  
	    	
	    }
		
	}

	@Override
	public void mouseDragged(MouseEvent e) {
		super.mouseDragged(e);
		
		if(!editingDelegate.isEditing()){
		    float valX = (float)e.getX()/this.getWidth();   
		    float valY = 1.0f-((float)e.getY()/this.getHeight());
			if(valX>1)valX=1;if(valX<0)valX=0;
			if(valY>1)valY=1;if(valY<0)valY=0;
		    setValue(valX, valY);
		    sendValue();	
		}
	}

	@Override
	public void mouseMoved(MouseEvent arg0) {
		// TODO Auto-generated method stub
		
	}
	
	//receive messages from PureData (via [send toGUI], routed through the PdWrapper.pd patch), routed from Document via the address to this object
	public void receiveList(ArrayList<Object> messageArray){
		boolean sendVal  = true;
		//if message preceded by "set", then set "sendVal" flag to NO, and strip off set and make new messages array without it
	    if (messageArray.size()>0 && (messageArray.get(0) instanceof String) && messageArray.get(0).equals("set") ){
	    	messageArray = new ArrayList<Object>(messageArray.subList(1, messageArray.size() ) );
	    	sendVal=false;
	    }
	    //set new value
	    if (messageArray.size()>0 && (messageArray.get(0) instanceof Float) && (messageArray.get(1) instanceof Float) ){
	        setValue( ((Float)(messageArray.get(0))).floatValue(), ((Float)(messageArray.get(1))).floatValue() );
	        if(sendVal)sendValue();
	    }

	}

}
