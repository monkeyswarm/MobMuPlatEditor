package com.iglesiaintermedia.MobMuPlatEditor.controls;

import java.awt.*;
import java.awt.event.*;
import java.util.ArrayList;

import javax.swing.*;

public class MMPSlider extends MMPControl implements MouseListener, MouseMotionListener{
	final static int SLIDER_TROUGH_WIDTH=10;
	final static int SLIDER_TROUGH_TOPINSET=10;
	final static int SLIDER_THUMB_HEIGHT=20;
	
	private RoundedPanel thumbPanel;
	private RoundedPanel troughPanel;
	
	public int range;
	public boolean isHorizontal;
	private ArrayList<JPanel> tickViewArray;
	float value;
	
	//copy constructor
	public MMPSlider(MMPSlider otherSlider){
		this(otherSlider.getBounds());//normal constructor
		this.setColor(otherSlider.getColor());
		this.setHighlightColor(otherSlider.getHighlightColor());
		this.address=otherSlider.address;
		this.setRange(otherSlider.range);
	}
	
	public MMPSlider(Rectangle frame){
		super();
		
		//this.setBackground(Color.PINK);
		thumbPanel = new RoundedPanel();
		//thumbPanel.setBackground(Color.RED);
		//thumbPanel.setLocation(0,0);
		//thumbPanel.setSize(20,20);
		thumbPanel.setCornerRadius(5);
		this.add(thumbPanel);
		
		troughPanel = new RoundedPanel();
		//troughPanel.setBackground(Color.RED);
		//troughPanel.setLocation(20,0);
		//troughPanel.setSize(5,100);
		troughPanel.setCornerRadius(3);
		this.add(troughPanel);
		
		address="/mySlider";
		setRange(2);
		
		this.addMouseListener(this);
		this.addMouseMotionListener(this);
		
		this.setColor(this.getColor()); //necc?
		this.setBounds(frame);
		//this.addHandles();
		
	}
	
	public void setBounds(Rectangle frame){
		super.setBounds(frame);
	    
	    if(!isHorizontal){//vertical
	        for(int i=0;i<tickViewArray.size();i++){
	            JPanel tick = tickViewArray.get(i);
	            tick.setBounds( (getBounds().width-10)/4 , SLIDER_TROUGH_TOPINSET+i*(getBounds().height-SLIDER_TROUGH_TOPINSET*2)/(range-1)-1, (getBounds().width-10)/2+10, 2);
	        }
	    
	        troughPanel.setBounds( (getBounds().width-10)/2, SLIDER_TROUGH_TOPINSET, SLIDER_TROUGH_WIDTH, getBounds().height-(SLIDER_TROUGH_TOPINSET*2) ); //setFrame: CGRectMake((frameRect.size.width-10)/2, SLIDER_TROUGH_TOPINSET, SLIDER_TROUGH_WIDTH, frameRect.size.height-(SLIDER_TROUGH_TOPINSET*2))];
	    }
	    
	    else{//horizontal
	        for(int i=0;i<tickViewArray.size();i++){
	        	JPanel tick = tickViewArray.get(i);
	            //[tick setFrame:CGRectMake(SLIDER_TROUGH_TOPINSET+i*(frameRect.size.width-SLIDER_TROUGH_TOPINSET*2)/(_range-1)-1,  (frameRect.size.height-10)/4, 2, (frameRect.size.height-10)/2+10)];
	            tick.setBounds( SLIDER_TROUGH_TOPINSET+i*(getBounds().width-SLIDER_TROUGH_TOPINSET*2)/(range-1)-1, (getBounds().height-10)/4 , 2, (getBounds().height-10)/2+10);
	        }
	        //[troughView setFrame: CGRectMake(SLIDER_TROUGH_TOPINSET, (frameRect.size.height-10)/2, frameRect.size.width-(SLIDER_TROUGH_TOPINSET*2), SLIDER_TROUGH_WIDTH)];
	        troughPanel.setBounds( SLIDER_TROUGH_TOPINSET, (getBounds().height-10)/2,   getBounds().width-(SLIDER_TROUGH_TOPINSET*2), SLIDER_TROUGH_WIDTH ); //setFrame: CGRectMake((frameRect.size.width-10)/2, SLIDER_TROUGH_TOPINSET, SLIDER_TROUGH_WIDTH, frameRect.size.height-(SLIDER_TROUGH_TOPINSET*2))];
	 	   
	    }
	    
	   updateThumb();
	}
	
	
	public void setRange(int inRange){
	    range=inRange;
	    if(range<2)range=2;
	    
	    //if(tickViewArray)for(NSView* tick in tickViewArray)[tick removeFromSuperview];
	    if(tickViewArray!=null )
	    	for(JPanel tick:tickViewArray)tick.getParent().remove(tick);
	    
	    tickViewArray = new ArrayList<JPanel>();//[[NSMutableArray alloc]init];
	    if(range>2){
	        for(int i=0;i<range;i++){
	           JPanel tick = new JPanel();
	            tick.setBackground(getColor());
	            tickViewArray.add(tick);
	            add(tick);
	            
	        }
	    }
	   setBounds(this.getBounds());
	   this.repaint();
	}

	public void setIsHorizontal(boolean inIsHoriz){
		isHorizontal = inIsHoriz;
		this.setBounds(this.getBounds());
	}
	
	//send OSC message out
	public void sendValue(){
	   Object[] args = new Object[]{new Float(value)};
		editingDelegate.sendMessage(address, args);
	}

	public void setColor(Color newColor){
		super.setColor(newColor);
		troughPanel.setBackground(newColor);
		thumbPanel.setBackground(newColor);
		for(JPanel tick: tickViewArray)tick.setBackground(newColor);
	}
	
	void updateThumb(){
		Rectangle newFrame;
	    
	    if(!isHorizontal)
	        newFrame = new Rectangle( 0, (int)((1.0-(value/(range-1)))*(getBounds().height-(SLIDER_TROUGH_TOPINSET*2))), getBounds().width, SLIDER_THUMB_HEIGHT );
	    else  newFrame = new Rectangle( (int)((value/(range-1))*(getBounds().width-(SLIDER_TROUGH_TOPINSET*2))),0, SLIDER_THUMB_HEIGHT, getBounds().height  );
	    //System.out.print("\nnewFrame "+newFrame.getY()+" "+ (1.0-(value/(range-1))) );
		thumbPanel.setBounds(newFrame);
	
	}
	
	void setValue(float inVal){
		//System.out.print("\nsetval "+inVal);
	    if(range==2){//clip 0.-1.
	        if(inVal>1)inVal=1;
	        if(inVal<0)inVal=0;
	    }
	    else{
	        if((inVal % 1.0)!=0.0)inVal=(float)(int)inVal;//round down to integer
	        if (inVal>=range) {
	            inVal=(float)(range-1);//clip if necessary
	        }
	    }
	    value=inVal;
		updateThumb();
		//System.out.print(" setval "+value);
	}
	
	public void mousePressed(MouseEvent e) {
		//System.out.print(e.getClickCount() + " click(s)");
		super.mousePressed(e);
		/*if(!editingDelegate.isEditing()){
			thumbPanel.setLocation(e.getX(), e.getY());
		}*/
		
		
	    if(!editingDelegate.isEditing()){
	       // CGPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
	        float tempFloatValue;
	        if(!isHorizontal) tempFloatValue=1.0f-(((float)e.getY()-SLIDER_TROUGH_TOPINSET)/(getBounds().height-(SLIDER_TROUGH_TOPINSET*2)));//0-1
	        else tempFloatValue=(((float)e.getX()-SLIDER_TROUGH_TOPINSET)/(getBounds().width-(SLIDER_TROUGH_TOPINSET*2)));//0-1
	        
	        if(range==2 && tempFloatValue<=range-1 && tempFloatValue>=0  && tempFloatValue!=value){
	            setValue(tempFloatValue);
	           sendValue();
	        }
	        float tempValue = (float)(int)((tempFloatValue*(range-1))+.5);//round to 0-4
	        if(range>2 && tempValue<=range-1 && tempValue>=0  && tempValue!=value){
	        	setValue(tempValue);
		           sendValue();
	        }
	        
	        thumbPanel.setBackground(getHighlightColor());
	        troughPanel.setBackground(getHighlightColor());
	        if(tickViewArray!=null)
	        	for (JPanel tick : tickViewArray)tick.setBackground(getHighlightColor());
	        
	    }
		
	}

	@Override
	public void mouseClicked(MouseEvent e) {
		/*super.mouseClicked(e);
		if(!editingDelegate.isEditing()){
			thumbPanel.setLocation(e.getX(), e.getY());
		}*/
		
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
	    	 thumbPanel.setBackground(getColor());
		        troughPanel.setBackground(getColor());
		        if(tickViewArray!=null)
		        	for (JPanel tick : tickViewArray)tick.setBackground(getColor());
		        
	    }
	    
	    //necc only if color is translucent
	    this.repaint();
		
	}

	@Override
	public void mouseDragged(MouseEvent e) {
		super.mouseDragged(e);
		//System.out.print("\n"+e.getY());
		/*if(!editingDelegate.isEditing()){
			thumbPanel.setLocation(e.getX(), e.getY());
			this.sendValue();
		}*/
		
		if(!editingDelegate.isEditing()){
		       // CGPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
		        float tempFloatValue;
		        if(!isHorizontal) tempFloatValue=1.0f-(((float)e.getY()-SLIDER_TROUGH_TOPINSET)/(getBounds().height-(SLIDER_TROUGH_TOPINSET*2)));//0-1
		        else tempFloatValue=(((float)e.getX()-SLIDER_TROUGH_TOPINSET)/(getBounds().width-(SLIDER_TROUGH_TOPINSET*2)));//0-1
		        
		        if(range==2 && tempFloatValue<=range-1 && tempFloatValue>=0  && tempFloatValue!=value){
		            setValue(tempFloatValue);
		           sendValue();
		        }
		        float tempValue = (float)(int)((tempFloatValue*(range-1))+.5);//round to 0-4
		        //System.out.("\ntempval "+tempValue);
		        if(range>2 && tempValue<=range-1 && tempValue>=0  && tempValue!=value){
		        	setValue(tempValue);
			           sendValue();
		        }
		        
		}
		
	}

	@Override
	public void mouseMoved(MouseEvent arg0) {
		// TODO Auto-generated method stub
		
	}
	
	//receive messages from PureData (via [send toGUI], routed through the PdWrapper.pd patch), routed from Document via the address to this object
	public void receiveList(ArrayList<Object> messageArray){
		super.receiveList(messageArray);
		boolean sendVal  = true;
		//if message preceded by "set", then set "sendVal" flag to NO, and strip off set and make new messages array without it
	    if (messageArray.size()>0 && (messageArray.get(0) instanceof String) && messageArray.get(0).equals("set") ){
	    	messageArray = new ArrayList<Object>(messageArray.subList(1, messageArray.size() ) );
	        sendVal=false;
	    }
	    //set new value
	    //System.out.print("\nms size "+messageArray.size()+" "+messageArray.get(0));
	    if (messageArray.size()>0 && (messageArray.get(0) instanceof Integer) ){
	        setValue( ((Integer)(messageArray.get(0))).intValue() );
	        if(sendVal)sendValue();
	    }
	    if (messageArray.size()>0 && (messageArray.get(0) instanceof Float) ){
	        setValue( ((Float)(messageArray.get(0))).floatValue() );
	        if(sendVal)sendValue();
	    }

	}
	
	 public void setEnabled(boolean enabled){
			super.setEnabled(enabled);
			Color c = this.isEnabled() ? getColor() : getDisabledColor();
			troughPanel.setBackground(c);
			thumbPanel.setBackground(c);
			for(JPanel tick: tickViewArray)tick.setBackground(c);
	 }
}
