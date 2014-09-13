package com.iglesiaintermedia.MobMuPlatEditor.controls;

import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Point;
import java.awt.Rectangle;
import java.awt.event.MouseEvent;
import java.awt.geom.Ellipse2D;
import java.awt.geom.GeneralPath;
import java.awt.geom.Line2D;
import java.awt.geom.Point2D;
import java.awt.geom.Rectangle2D;
import java.awt.image.BufferedImage;
import java.util.ArrayList;
import java.util.List;

import javax.swing.BorderFactory;
import javax.swing.JPanel;
import javax.swing.border.Border;

public class MMPLCD extends MMPControl {
	//static final int LINE_WIDTH = 4;
	float fR, fG, fB, fA;
	float penWidth;
	Point2D.Float penPoint;
	
	//
	BufferedImage cacheImage;
	Graphics2D cacheGraphics;
	
	//copy constructor
	public MMPLCD(MMPLCD otherLCD){
		this(otherLCD.getBounds());//normal constructor
		this.setColor(otherLCD.color);
		this.setHighlightColor(otherLCD.highlightColor);
		this.address=otherLCD.address;//not setAddress, since this doesn't have editingDelegate yet
	}
	
	public MMPLCD(Rectangle frame){
		super();
		address="/myLCD";
		penPoint = new Point2D.Float();
		penWidth = 1.0f;
		
		this.addMouseListener(this);
		this.addMouseMotionListener(this);
		
		this.setColor(this.color);
		this.setHighlightColor(this.highlightColor);
		this.setBounds(frame);
		
		
	}
	
	public void setPenWidth(float newWidth){
		penWidth = (int)newWidth;
		cacheGraphics.setStroke(new BasicStroke(penWidth));
	}
	
	public void setBounds(Rectangle frame){
		super.setBounds(frame);
	    //need to redo border?
		createBitmapContext(frame); 
		//??
		this.repaint();
	}
	
	private void createBitmapContext(Rectangle frame){
		cacheImage = new BufferedImage(frame.width, frame.height, BufferedImage.TYPE_INT_ARGB);
		cacheGraphics = cacheImage.createGraphics();
		cacheGraphics.setStroke(new BasicStroke(penWidth));
	}
	
	public void setColor(Color newColor){
		super.setColor(newColor);
		this.setBackground(newColor);
	}
	
	public void setHighlightColor(Color newColor){
		super.setHighlightColor(newColor);
		float[] compArray = new float[4];
		newColor.getComponents(compArray);
		fR=compArray[0];
		fG=compArray[1];
		fB=compArray[2];
		fA=compArray[3];
		
		//this.repaint();//without this, horiz view peeked on top of the edithandle border..
	}
	
	//drawing
	public void clear(){
		cacheGraphics.setBackground(new Color(255, 255, 255, 0));
		cacheGraphics.clearRect(0,0,getWidth(), getHeight());
		this.repaint();
	}
	
	public void paintRect(float x, float y, float x2, float y2, float r, float g, float b, float a){
		cacheGraphics.setColor(new Color(r,g,b,a) );
		Rectangle2D.Float newRect = new Rectangle2D.Float(Math.min(x, x2)*getWidth(), Math.min(y,y2)*getHeight(), Math.abs(x2-x)*getWidth(), Math.abs(y2-y)*getHeight() );
		cacheGraphics.fill(newRect);
		Rectangle newRect2 = new Rectangle((int)(newRect.x-penWidth), (int)(newRect.y-penWidth), (int)(newRect.width+(2*penWidth)), (int)(newRect.height+(2*penWidth)) );
		this.repaint(newRect2);
	}
	
	public void paintRect(float x, float y, float x2, float y2){
		paintRect(x,y,x2,y2,fR,fG,fB,fA);
	}
	
	public void frameRect(float x, float y, float x2, float y2, float r, float g, float b, float a){
		cacheGraphics.setColor(new Color(r,g,b,a) );
		Rectangle2D.Float newRect = new Rectangle2D.Float(Math.min(x, x2)*getWidth(), Math.min(y,y2)*getHeight(), Math.abs(x2-x)*getWidth(), Math.abs(y2-y)*getHeight() );
		cacheGraphics.draw(newRect);
		Rectangle newRect2 = new Rectangle((int)(newRect.x-penWidth), (int)(newRect.y-penWidth), (int)(newRect.width+(2*penWidth)), (int)(newRect.height+(2*penWidth)) );
		this.repaint(newRect2);
	}
	
	public void frameRect(float x, float y, float x2, float y2){
		frameRect(x,y,x2,y2,fR,fG,fB,fA);
	}
	
	public void paintOval(float x, float y, float x2, float y2, float r, float g, float b, float a){
		cacheGraphics.setColor(new Color(r,g,b,a) );
		Rectangle2D.Float newRect = new Rectangle2D.Float(Math.min(x, x2)*getWidth(), Math.min(y,y2)*getHeight(), Math.abs(x2-x)*getWidth(), Math.abs(y2-y)*getHeight() );
		Ellipse2D ellipse = new Ellipse2D.Float(newRect.x, newRect.y, newRect.width, newRect.height);
		cacheGraphics.fill(ellipse);
		Rectangle newRect2 = new Rectangle((int)(newRect.x-penWidth), (int)(newRect.y-penWidth), (int)(newRect.width+(2*penWidth)), (int)(newRect.height+(2*penWidth)) );
		this.repaint(newRect2);
	}
	
	public void paintOval(float x, float y, float x2, float y2){
		paintOval(x,y,x2,y2,fR,fG,fB,fA);
	}
	
	public void frameOval(float x, float y, float x2, float y2, float r, float g, float b, float a){
		cacheGraphics.setColor(new Color(r,g,b,a) );
		Rectangle2D.Float newRect = new Rectangle2D.Float(Math.min(x, x2)*getWidth(), Math.min(y,y2)*getHeight(), Math.abs(x2-x)*getWidth(), Math.abs(y2-y)*getHeight() );
		Ellipse2D ellipse = new Ellipse2D.Float(newRect.x, newRect.y, newRect.width, newRect.height);
		cacheGraphics.draw(ellipse);
		Rectangle newRect2 = new Rectangle((int)(newRect.x-penWidth), (int)(newRect.y-penWidth), (int)(newRect.width+(2*penWidth)), (int)(newRect.height+(2*penWidth)) );
		this.repaint(newRect2);
	}
	
	public void frameOval(float x, float y, float x2, float y2){
		frameOval(x,y,x2,y2,fR,fG,fB,fA);
	}
	
	private void framePolyRGBA(List<Object> messageArray, float r, float g, float b, float a){
	
		if(messageArray.size()<4)return;
	    
		float  minX=getWidth(), minY = getHeight(), maxX =0, maxY = 0;
		
		cacheGraphics.setColor(new Color(r,g,b,a) );
		GeneralPath polygon =   new GeneralPath(GeneralPath.WIND_EVEN_ODD);
		float x = ((Float)(messageArray.get(0))).floatValue() * getWidth();
		float y = ((Float)(messageArray.get(1))).floatValue() * getHeight();
		polygon.moveTo(x,y);
		
		if(x<minX)minX=x; if(y<minY)minY=y; if(x>maxX)maxX=x; if(y>maxY)maxY=y;
	    
	    for(int i = 2; i < messageArray.size(); i+=2){
			//CGContextAddLineToPoint(_cacheContext, [[pointArray objectAtIndex:i] floatValue]*self.frame.size.width, [[pointArray objectAtIndex:i+1] floatValue]*self.frame.size.height);
	    	x = ((Float)(messageArray.get(i))).floatValue() * getWidth();
			y = ((Float)(messageArray.get(i+1))).floatValue() * getHeight();
			polygon.lineTo(x,y);
			if(x<minX)minX=x; if(y<minY)minY=y; if(x>maxX)maxX=x; if(y>maxY)maxY=y;
		    
	    }
		
	    polygon.closePath();
	    cacheGraphics.draw(polygon);
	    
	    Rectangle newRect2 = new Rectangle( (int)(minX-penWidth), (int)(minY-penWidth), (int)(Math.abs(maxX-minX)+(2*penWidth)), (int)(Math.abs(maxY-minY)+(2*penWidth)) );
		this.repaint(newRect2);
		
	}
	
	private void framePoly(List<Object> messageArray){//can assume all Float
		framePolyRGBA(messageArray, fR, fG, fB, fA);
	}
	
	private void paintPolyRGBA(List<Object> messageArray, float r, float g, float b, float a){
		
		if(messageArray.size()<4)return;
	    
		float  minX=getWidth(), minY = getHeight(), maxX =0, maxY = 0;
		
		cacheGraphics.setColor(new Color(r,g,b,a) );
		GeneralPath polygon =   new GeneralPath(GeneralPath.WIND_EVEN_ODD);
		float x = ((Float)(messageArray.get(0))).floatValue() * getWidth();
		float y = ((Float)(messageArray.get(1))).floatValue() * getHeight();
		polygon.moveTo(x,y);
		
		if(x<minX)minX=x; if(y<minY)minY=y; if(x>maxX)maxX=x; if(y>maxY)maxY=y;
	    
	    for(int i = 2; i < messageArray.size(); i+=2){
			//CGContextAddLineToPoint(_cacheContext, [[pointArray objectAtIndex:i] floatValue]*self.frame.size.width, [[pointArray objectAtIndex:i+1] floatValue]*self.frame.size.height);
	    	x = ((Float)(messageArray.get(i))).floatValue() * getWidth();
			y = ((Float)(messageArray.get(i+1))).floatValue() * getHeight();
			polygon.lineTo(x,y);
			if(x<minX)minX=x; if(y<minY)minY=y; if(x>maxX)maxX=x; if(y>maxY)maxY=y;
		    
	    }
		
	    polygon.closePath();
	    cacheGraphics.fill(polygon);
	    
	    Rectangle newRect2 = new Rectangle( (int)(minX), (int)(minY), (int)(Math.abs(maxX-minX)), (int)(Math.abs(maxY-minY)) );
		this.repaint(newRect2);
		
	}

	private void paintPoly(List<Object> messageArray){//can assume all Float
		paintPolyRGBA(messageArray, fR, fG, fB, fA);
	}
	
	private void moveTo(float x, float y){//input normalized floats
		penPoint.x = x*getWidth();
		penPoint.y = y*getHeight();
	}
	
	private void lineTo(float x, float y, float r, float g, float b, float a){//input normalized floats
		x = x*getWidth();
		y = y*getHeight();
		
		cacheGraphics.setColor(new Color(r,g,b,a) );
		GeneralPath path =   new GeneralPath(GeneralPath.WIND_EVEN_ODD);
		path.moveTo(penPoint.x,penPoint.y);
		path.lineTo(x,y);
		cacheGraphics.draw(path);
		
		 Rectangle newRect2 = new Rectangle( (int)(Math.min(penPoint.x, x)-penWidth), (int)(Math.min(penPoint.y, y)-penWidth), (int)(Math.abs(penPoint.x-x)+(2*penWidth)), (int)(Math.abs(penPoint.y-y)+(2*penWidth)) );
			this.repaint(newRect2);
			
			penPoint.x = x;
		    penPoint.y = y;
	}
	
	private void lineTo(float x, float y){
		lineTo(x,y,fR,fG,fB,fA);
	}
	
	//send OSC message out
	public void sendValue(int state, float x, float y){
	   Object[] args = new Object[]{new Integer(state), new Float(x), new Float(y)};
		editingDelegate.sendMessage(address, args);
	}

	
	//mouse
	public void mousePressed(MouseEvent e) {
		//System.out.print(e.getClickCount() + " click(s)");
		super.mousePressed(e);
		
		if(!editingDelegate.isEditing()){
	       
			float valX = (float)e.getX()/this.getWidth();   
		    float valY = (float)e.getY()/this.getHeight();
			if(valX>1)valX=1;if(valX<0)valX=0;
			if(valY>1)valY=1;if(valY<0)valY=0;
		    sendValue(1, valX, valY);	
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
	    	float valX = (float)e.getX()/this.getWidth();   
		    float valY = (float)e.getY()/this.getHeight();
			if(valX>1)valX=1;if(valX<0)valX=0;
			if(valY>1)valY=1;if(valY<0)valY=0;
		    sendValue(0, valX, valY);	
	    }
		
	}

	@Override
	public void mouseDragged(MouseEvent e) {
		super.mouseDragged(e);
		
		if(!editingDelegate.isEditing()){
		    float valX = (float)e.getX()/this.getWidth();   
		    float valY = (float)e.getY()/this.getHeight();
			if(valX>1)valX=1;if(valX<0)valX=0;
			if(valY>1)valY=1;if(valY<0)valY=0;
		    sendValue(2, valX, valY);	
		}
	}

	@Override
	public void mouseMoved(MouseEvent arg0) {
		// TODO Auto-generated method stub
		
	}
	
	protected void paintComponent(Graphics g) {
		
        super.paintComponent(g);
        int width = getWidth();
        int height = getHeight();
        
        Graphics2D graphics = (Graphics2D) g;
        graphics.setColor(getBackground());
        graphics.fillRect(0, 0, width, height);
        graphics.drawImage(cacheImage, 0, 0, null);
        
	}
	
	//receive messages from PureData (via [send toGUI], routed through the PdWrapper.pd patch), routed from Document via the address to this object
	public void receiveList(ArrayList<Object> messageArray){
	    //preprocess integers into float - java OSC library mixes the two even though PD just sends floats
		for(int i=1;i<messageArray.size();i++){
			if (messageArray.get(i) instanceof Integer){
				Integer val = (Integer)(messageArray.get(i));
				messageArray.set(i, new Float(val));
			}
			//if it isn't a float/int, insert zero
			if (! (messageArray.get(i) instanceof Float) ){
				messageArray.set(i, new Float(0));
				//System.out.print("!");
			}
		}
		
	   if(messageArray.size()==5 && (messageArray.get(0) instanceof String) && messageArray.get(0).equals("paintrect") ){
		   paintRect(((Float)(messageArray.get(1))).floatValue(), ((Float)(messageArray.get(2))).floatValue(), ((Float)(messageArray.get(3))).floatValue(), ((Float)(messageArray.get(4))).floatValue());
		}
	   else if (messageArray.size()==9 && (messageArray.get(0) instanceof String) && messageArray.get(0).equals("paintrect")  ){
		   paintRect(((Float)(messageArray.get(1))).floatValue(), ((Float)(messageArray.get(2))).floatValue(), ((Float)(messageArray.get(3))).floatValue(), ((Float)(messageArray.get(4))).floatValue(), ((Float)(messageArray.get(5))).floatValue(), ((Float)(messageArray.get(6))).floatValue(), ((Float)(messageArray.get(7))).floatValue(), ((Float)(messageArray.get(8))).floatValue());
		}
	   if(messageArray.size()==5 && (messageArray.get(0) instanceof String) && messageArray.get(0).equals("framerect")  ){
		   frameRect( ((Float)(messageArray.get(1))).floatValue(), ((Float)(messageArray.get(2))).floatValue(), ((Float)(messageArray.get(3))).floatValue(), ((Float)(messageArray.get(4))).floatValue());
	   }
	   else if (messageArray.size()==9 && (messageArray.get(0) instanceof String) && messageArray.get(0).equals("framerect")  ){
		   frameRect(((Float)(messageArray.get(1))).floatValue(), ((Float)(messageArray.get(2))).floatValue(), ((Float)(messageArray.get(3))).floatValue(), ((Float)(messageArray.get(4))).floatValue(), ((Float)(messageArray.get(5))).floatValue(), ((Float)(messageArray.get(6))).floatValue(), ((Float)(messageArray.get(7))).floatValue(), ((Float)(messageArray.get(8))).floatValue());
		}
	   
	   else if(messageArray.size()==5 && (messageArray.get(0) instanceof String) && messageArray.get(0).equals("paintoval")  ){
		   paintOval(((Float)(messageArray.get(1))).floatValue(), ((Float)(messageArray.get(2))).floatValue(), ((Float)(messageArray.get(3))).floatValue(), ((Float)(messageArray.get(4))).floatValue());
		}
	   else if (messageArray.size()==9 && (messageArray.get(0) instanceof String) && messageArray.get(0).equals("paintoval")  ){
		   paintOval(((Float)(messageArray.get(1))).floatValue(), ((Float)(messageArray.get(2))).floatValue(), ((Float)(messageArray.get(3))).floatValue(), ((Float)(messageArray.get(4))).floatValue(), ((Float)(messageArray.get(5))).floatValue(), ((Float)(messageArray.get(6))).floatValue(), ((Float)(messageArray.get(7))).floatValue(), ((Float)(messageArray.get(8))).floatValue());
		}
	   if(messageArray.size()==5 && (messageArray.get(0) instanceof String) && messageArray.get(0).equals("frameoval")  ){
		   frameOval( ((Float)(messageArray.get(1))).floatValue(), ((Float)(messageArray.get(2))).floatValue(), ((Float)(messageArray.get(3))).floatValue(), ((Float)(messageArray.get(4))).floatValue());
	   }
	   else if (messageArray.size()==9 && (messageArray.get(0) instanceof String) && messageArray.get(0).equals("frameoval")  ){
		   frameOval( ((Float)(messageArray.get(1))).floatValue(), ((Float)(messageArray.get(2))).floatValue(), ((Float)(messageArray.get(3))).floatValue(), ((Float)(messageArray.get(4))).floatValue(), ((Float)(messageArray.get(5))).floatValue(), ((Float)(messageArray.get(6))).floatValue(), ((Float)(messageArray.get(7))).floatValue(), ((Float)(messageArray.get(8))).floatValue());
		}
	   
	   else if (messageArray.size()%2==1 && (messageArray.get(0) instanceof String) && messageArray.get(0).equals("framepoly")  ){
		   List<Object> coordinatesArray =  messageArray.subList(1, messageArray.size()); //just coordinates
		   framePoly(coordinatesArray);
	   }
	   
	   else if (messageArray.size()%2==1 && (messageArray.get(0) instanceof String) && messageArray.get(0).equals("framepolyRGBA")  ){ 
		   List<Object> coordinatesArray =  messageArray.subList(1, messageArray.size()-4); //just coordinates
		   int RGBAStartIndex = messageArray.size()-4;
		   framePolyRGBA(coordinatesArray, ((Float)(messageArray.get(RGBAStartIndex))).floatValue(),  ((Float)(messageArray.get(RGBAStartIndex+1))).floatValue(), ((Float)(messageArray.get(RGBAStartIndex+2))).floatValue(), ((Float)(messageArray.get(RGBAStartIndex+3))).floatValue());
	   }
	   else if (messageArray.size()%2==1 && (messageArray.get(0) instanceof String) && messageArray.get(0).equals("paintpoly")  ){
		   List<Object> coordinatesArray =  messageArray.subList(1, messageArray.size()); //just coordinates
		   paintPoly(coordinatesArray);
	   }
	   else if (messageArray.size()%2==1 && (messageArray.get(0) instanceof String) && messageArray.get(0).equals("paintpolyRGBA")  ){ 
		   List<Object> coordinatesArray = messageArray.subList(1, messageArray.size()-4); //just coordinates
		   int RGBAStartIndex = messageArray.size()-4;
		   paintPolyRGBA(coordinatesArray, ((Float)(messageArray.get(RGBAStartIndex))).floatValue(),  ((Float)(messageArray.get(RGBAStartIndex+1))).floatValue(), ((Float)(messageArray.get(RGBAStartIndex+2))).floatValue(), ((Float)(messageArray.get(RGBAStartIndex+3))).floatValue());
	   }
	   
	   else if (messageArray.size()==7 && (messageArray.get(0) instanceof String) && messageArray.get(0).equals("lineto")  ){
		   lineTo( ((Float)(messageArray.get(1))).floatValue(), ((Float)(messageArray.get(2))).floatValue(), ((Float)(messageArray.get(3))).floatValue(), ((Float)(messageArray.get(4))).floatValue(), ((Float)(messageArray.get(5))).floatValue(), ((Float)(messageArray.get(6))).floatValue() );
		}
	   else if (messageArray.size()==3 && (messageArray.get(0) instanceof String) && messageArray.get(0).equals("lineto")  ){
		   lineTo( ((Float)(messageArray.get(1))).floatValue(), ((Float)(messageArray.get(2))).floatValue() );
		}
	   else if (messageArray.size()==3 && (messageArray.get(0) instanceof String) && messageArray.get(0).equals("moveto")  ){
		   moveTo(((Float)(messageArray.get(1))).floatValue(), ((Float)(messageArray.get(2))).floatValue() );
	   }
	   
	   else if (messageArray.size()==2 && (messageArray.get(0) instanceof String) && messageArray.get(0).equals("penwidth")){
		   setPenWidth( ((Float)(messageArray.get(1))).floatValue());
	   }
	
	   else if (messageArray.size()==1 && (messageArray.get(0) instanceof String) && messageArray.get(0).equals("clear")){
		   clear();
	   }

	}
	

}

