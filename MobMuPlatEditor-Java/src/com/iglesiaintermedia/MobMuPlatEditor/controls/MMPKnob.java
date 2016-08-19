package com.iglesiaintermedia.MobMuPlatEditor.controls;

import java.awt.Color;
import java.awt.Dimension;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Point;
import java.awt.Rectangle;
import java.awt.RenderingHints;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.awt.event.MouseMotionListener;
import java.util.ArrayList;

import javax.swing.JPanel;


public class MMPKnob extends MMPControl implements MouseListener, MouseMotionListener{

	final static float ROTATION_PAD_RAD=.7f;
	final static int EXTRA_RADIUS=10;
	final static int TICK_DIM=10;
	
	private RoundedPanel knobPanel;
	private IndicatorPanel indicatorPanel;
	
	private int range;
	private ArrayList<RoundedPanel> tickViewArray;
	float value;
	private Color _indicatorColor, _indicatorDisabledColor;
	
	private float dim;
	private float radius;
	private float indicatorDim;
	private float indicatorThickness;
	private Point centerPoint;
	
	//copy constructor
	public MMPKnob(MMPKnob otherKnob){
		this(otherKnob.getBounds());//normal constructor
		this.setColor(otherKnob.getColor());
		this.setHighlightColor(otherKnob.getHighlightColor());
		this.address=otherKnob.address;
		this.setRange(otherKnob.range);
		this.setIndicatorColor(otherKnob.getIndicatorColor());
	}
	
	public MMPKnob(Rectangle frame){
		super();
		address="/myKnob";
		
		indicatorPanel = new IndicatorPanel();
		this.add(indicatorPanel);
		
		knobPanel = new RoundedPanel();	
		this.add(knobPanel);
		
		setRange(1);
		this.addMouseListener(this);
		this.addMouseMotionListener(this);
		this.setIndicatorColor(Color.WHITE);
		this.setColor(this.getColor());
		
		this.setBounds(frame);
		
		updateIndicator();
		
	}
	
	public Color getIndicatorColor() {
		return _indicatorColor;
	}
	
	public void setIndicatorColor(Color inColor){
		_indicatorColor=inColor;
		_indicatorDisabledColor = new Color(inColor.getRed(), inColor.getGreen(), inColor.getBlue(), (int)(inColor.getAlpha() * .2)); 
		indicatorPanel.setBackground(inColor);
	}
	
	public void setBounds(Rectangle frame){
		
		int newDim = (frame.width>frame.height) ? frame.width : frame.height;
		Rectangle squareFrame = new Rectangle(frame.x, frame.y, newDim, newDim);
		super.setBounds(squareFrame);
		dim = squareFrame.width-((EXTRA_RADIUS+TICK_DIM)*2);//diameter of circle 
		
		 //rounded up to nearest int - for corner radius
	    radius = (float)(int)(dim/2+.5);
	    knobPanel.setBounds(new Rectangle(EXTRA_RADIUS+TICK_DIM, EXTRA_RADIUS+TICK_DIM, (int)dim, (int)dim));
	    knobPanel.setCornerRadius((int)radius);
	   
	    indicatorDim=dim/2+2;
	    indicatorThickness = dim/8;
	    
	    centerPoint=new Point((int)(dim/2+EXTRA_RADIUS+TICK_DIM), (int)(dim/2+EXTRA_RADIUS+TICK_DIM));
	    //indicatorPanel.setBounds(new Rectangle ((int)(centerPoint.x-indicatorThickness/2), (int)(centerPoint.y-indicatorThickness/2), (int)indicatorThickness, (int)indicatorDim));
	    indicatorPanel.setBounds(0,0,getWidth(),getHeight());
	    updateIndicator();
	    
	    
	    for(RoundedPanel dot : tickViewArray){
	    	float angle= (float)((float)tickViewArray.indexOf(dot)/(tickViewArray.size()-1)* (Math.PI*2-ROTATION_PAD_RAD*2)+ROTATION_PAD_RAD+Math.PI/2);
	    	float xPos=(float) ( (dim/2+EXTRA_RADIUS+TICK_DIM/2)*Math.cos(angle) );
	    	float yPos=(float) ( (dim/2+EXTRA_RADIUS+TICK_DIM/2)*Math.sin(angle) );
	    	dot.setBounds(new Rectangle((int)(centerPoint.x+xPos-(TICK_DIM/2) ), (int)(centerPoint.y+yPos-(TICK_DIM/2) ), TICK_DIM, TICK_DIM) );
	    }
	}
	    
	  
	public void setColor(Color newColor){
		super.setColor(newColor);
		knobPanel.setBackground(newColor);
		for(JPanel tick: tickViewArray)tick.setBackground(newColor);
	}
	
	public void setLegacyRange(int range) {
		// translate old range value into new
		if(range == 2) range = 1;
		setRange(range);
	}
	
	public void setRange(int inRange){
	    range=inRange;
	    if(range<1)range=1;
	    if(range>1000)range=1000;
	    
	    if(tickViewArray!=null )
	    	for(JPanel tick:tickViewArray)tick.getParent().remove(tick);
	    
	    tickViewArray = new ArrayList<RoundedPanel>();
	    
	  int effectiveRange = range == 1 ? 2 : range; 
      for(int i=0;i<effectiveRange;i++){
    	  RoundedPanel tick = new RoundedPanel();
	      tick.setBackground(this.getColor());
	      tick.setCornerRadius((int)(TICK_DIM/2));
	      tickViewArray.add(tick);
	      add(tick);            
	   }
	    
	   this.setBounds(this.getBounds());
	   this.repaint();
	}

	public int getRange() {
		return range;
	}
	
	void setValue(float inVal){
		if(inVal!=value){
			if(range==1){//clip 0.-1.
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
		    //System.out.println(value);
		    updateIndicator();
			
		}
	}
	
	//send OSC message out
	public void sendValue(){
	   Object[] args = new Object[]{new Float(value)};
		editingDelegate.sendMessage(address, args);
	}

	
	void updateIndicator(){
		double newRad=0;
		if(range==1)
	        newRad= value*(Math.PI*2-ROTATION_PAD_RAD*2)+ROTATION_PAD_RAD;
		
		 else if (range>1)
		     newRad=(value/(range-1))*(Math.PI*2-ROTATION_PAD_RAD*2)+ROTATION_PAD_RAD;
		
	    indicatorPanel.setRotation(newRad);
	  
	}
	
	
	
	public void mousePressed(MouseEvent e) {
		//System.out.print(e.getClickCount() + " click(s)");
		super.mousePressed(e);
			
	    if(!editingDelegate.isEditing()){
	      knobPanel.setBackground(this.getHighlightColor());
	      // TODO handle enable/disable changes with color/highlightcolor changes
	      for(JPanel tick: tickViewArray)tick.setBackground(this.getHighlightColor());
	      mouseDragged(e);
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
	    	 knobPanel.setBackground(getColor());
	    	 for(JPanel tick: tickViewArray)tick.setBackground(getColor());
		       // indicatorColor.setBackground(indicatorColor);
		       
	    }
		
	}

	@Override
	public void mouseDragged(MouseEvent e) {
		super.mouseDragged(e);
		
		if(!editingDelegate.isEditing()){
			
	        float touchX = e.getX()-centerPoint.x;
	        float touchY = e.getY()-centerPoint.y;
	        double theta = Math.atan2(touchY, touchX);//raw theta (-pi to pi) =0 starting at 3 o'clock and going potive clockwise
	        
	        double updatedTheta = (theta-Math.PI/2+(Math.PI*2)) % (Math.PI*2) ;//theta (0 to 2pi) =0 at 6pm going positive clockwise
	        //System.out.print("\ntheta "+theta+" update "+updatedTheta);
	        if(range==1){
	            if(updatedTheta<ROTATION_PAD_RAD)setValue(0);
	            else if(updatedTheta>(Math.PI*2-ROTATION_PAD_RAD)) setValue(1);
	            else  setValue( (float)( (updatedTheta-ROTATION_PAD_RAD)/(Math.PI*2-2*ROTATION_PAD_RAD) ));
	        
	        }
	        else if (range>1){
	            if(updatedTheta<ROTATION_PAD_RAD)setValue(0);
	            else if(updatedTheta>(Math.PI*2-ROTATION_PAD_RAD)) setValue(range-1);
	            else setValue( (float) (  (int)((updatedTheta-ROTATION_PAD_RAD)/(Math.PI*2-2*ROTATION_PAD_RAD)*(range-1)+.5)  ) );//round to nearest tick!
	        }
	         sendValue();
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
		Color c = enabled ? getColor() : getDisabledColor();
		knobPanel.setBackground(c);
		for(JPanel tick: tickViewArray)tick.setBackground(c);
		indicatorPanel.setBackground(enabled ? _indicatorColor : _indicatorDisabledColor);
	}


	class IndicatorPanel extends JPanel{
	private double theta;
	protected Dimension arcs = new Dimension(5, 5);
	
	public IndicatorPanel(){
		super();
		setOpaque(false);
	}
	
	public void setCornerRadius(int rad){
		arcs= new Dimension(rad, rad);
		this.repaint();
	}
	
	public void setRotation(double inTheta){
		//System.out.print("\n"+inTheta);
		theta = inTheta;
		this.repaint();
	}
	public void paintComponent(Graphics g) {
        super.paintComponent(g);

        Graphics2D graphics = (Graphics2D) g;

        int width = getWidth();
        int height = getHeight();
        
        graphics.setRenderingHint(RenderingHints.KEY_ANTIALIASING, 
    			RenderingHints.VALUE_ANTIALIAS_ON);

        //Draws the rounded opaque panel with borders.
        graphics.setColor(getBackground());
        graphics.translate(centerPoint.x-Math.cos(theta)*(indicatorThickness/2), centerPoint.y-Math.sin(theta)*(indicatorThickness/2));
        graphics.rotate(theta);
        graphics.fillRoundRect(0, 0, (int)indicatorThickness, (int)indicatorDim,  arcs.width*2, arcs.height*2);
        //graphics.setColor(getForeground());

    }

}
	

}
