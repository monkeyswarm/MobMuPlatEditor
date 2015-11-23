package com.iglesiaintermedia.MobMuPlatEditor.controls;

import java.awt.Color;
import java.awt.Rectangle;
import java.awt.Point;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.awt.event.MouseMotionListener;
import java.net.InetAddress;
import java.net.SocketException;
import java.net.UnknownHostException;
import java.util.ArrayList;

import com.iglesiaintermedia.MobMuPlatEditor.*;

import javax.swing.*;
import javax.swing.SwingUtilities.*;
import javax.swing.border.Border;

import com.illposed.osc.*;

public class MMPControl extends JPanel implements MouseListener, MouseMotionListener{
	final static int HANDLE_SIZE = 20; //size of the EditHandle in the lower right corner
	
	String address;
	private Color _color, _disabledColor;
	private Color _highlightColor, _disabledHighlightColor;
	public boolean isSelected;
	public MMPController editingDelegate;
	
	private  boolean dragging;
	private Point clickOffsetInMe;
	private Point lastDragLocation;
	private boolean wasSelectedThisCycle;
	EditHandle handle;
	
	protected Border border = BorderFactory.createLineBorder(Color.black, 5);
	JPanel topPanel;
	
	
		
	public MMPControl(){
		super();
		setLayout(null);
		setOpaque(false);
		_color = Color.BLUE;//new Color(1f,.1f,.1f,.1f);
		_highlightColor = Color.RED;//new Color(0f,.1f,.1f,.1f);
		
		topPanel = new JPanel();
		topPanel.setOpaque(false);
		add(topPanel);
		
		addHandles();//do this first in java, instead of last in osx
		
	}
	
	public void setAddress(String newAddress){
		address = newAddress;
	}
	public String getAddress() {
		return address;
	}
	
	public void setIsSelected(boolean inIsSelected){
		isSelected=inIsSelected;
		if(isSelected){
			topPanel.setBorder(border);// [self.layer setBorderWidth:5];
        	handle.setVisible(true);
    	}
    	else{
    		topPanel.setBorder(null);//orsetBorderPainted(false)//[self.layer setBorderWidth:0];
        	handle.setVisible(false);
    	}
	
	}
	
	public void addHandles(){
		  handle = new EditHandle();
	      handle.setBounds(getBounds().width-HANDLE_SIZE,getBounds().height-HANDLE_SIZE, HANDLE_SIZE, HANDLE_SIZE);
	    handle.setVisible(false);
	   add(handle);
	} 

	public void setBounds(Rectangle bounds){
		super.setBounds(bounds);
		topPanel.setBounds(0,0,bounds.width, bounds.height);
		if(handle!=null)handle.setBounds(getBounds().width-HANDLE_SIZE,getBounds().height-HANDLE_SIZE, HANDLE_SIZE, HANDLE_SIZE);
	}
	
	public void setColor(Color newColor){
		_color = newColor;
		_disabledColor = new Color(newColor.getRed(), newColor.getGreen(), newColor.getBlue(), (int)(newColor.getAlpha() * .2));
	}
	
	public Color getColor() {
		return  _color;
	}
	
	public void setHighlightColor(Color newColor){
		_highlightColor = newColor;
		_disabledHighlightColor = new Color(newColor.getRed(), newColor.getGreen(), newColor.getBlue(), (int)(newColor.getAlpha() * .2));
	}
	
	public Color getHighlightColor() {
		return _highlightColor;
	}
	
	public Color getDisabledColor() {
		return _disabledColor;
	}
	
	public Color getDisabledHighlightColor() {
		return _disabledHighlightColor;
	}
	
	
	public void receiveList(ArrayList<Object> messageArray){
		if (messageArray.size()>=2 && 
				(messageArray.get(0) instanceof String) && 
				messageArray.get(0).equals("enable") && 
				(messageArray.get(1) instanceof Float)) {
			boolean enabled = ((Float)(messageArray.get(1))).floatValue() > 0;
			this.setEnabled(enabled);
			//this.setEnabled(((Float)(messageArray.get(1))).floatValue() > 0);
			//this.setAlpha(this.isEnabled() ? 1.0f : .2f );
			//this.setBackground(this.isEnabled() ? new Color(128, 128 , 128, 128) : new Color(128, 128, 128, 0));
			//this.setColor(new Color(255, 0 , 0, 128));
			//this.setBackground(new Color(128, 0 , 255, 128));
			
		}
	}

	@Override
	public void mouseClicked(MouseEvent e) {//just selection, no motion or interaction
		//calls pressed and released
	}

	@Override
	public void mouseEntered(MouseEvent arg0) {
		// TODO Auto-generated method stub
		
	}

	@Override
	public void mouseExited(MouseEvent arg0) {
		// TODO Auto-generated method stub
		
	}

	@Override
	public void mousePressed(MouseEvent e) {
		//System.out.print("\nmp "+this.address);
		if(editingDelegate.isEditing()){
			wasSelectedThisCycle=false;
	        boolean wasAlreadySelected = isSelected;
	        if(!isSelected){
	        	this.setIsSelected(true);//toggle
	            wasSelectedThisCycle=true;
	        }
	        
	        //System.out.print("\ncontrolclick isshift "+e.isShiftDown()+" was "+wasAlreadySelected);
			editingDelegate.controlEditClicked(this, e.isShiftDown(), wasAlreadySelected); 
	        //MOVEMENT
	        lastDragLocation=SwingUtilities.convertPoint(this, e.getPoint(), this.getParent());//e.getPoint();//[[self superview] convertPoint:[event locationInWindow]fromView:nil];
	        clickOffsetInMe=e.getPoint();//[self convertPoint:[event locationInWindow] fromView:nil];
	        //System.out.println("lastdrag in canvas "+lastDragLocation.getX()+" "+lastDragLocation.getY()+" offsetinwidget "+clickOffsetInMe.getX()+" "+clickOffsetInMe.getY());
	        editingDelegate.updateGuide(this);
		}
	}

	@Override
	public void mouseReleased(MouseEvent e) {
		//System.out.print("mr");
		if(editingDelegate.isEditing()){
			if(dragging){
				dragging = false;
				editingDelegate.controlEditReleased(this, e.isShiftDown(), true);
			}
			//wasn't a drag, just a click+release, and if has shift
			else{
				if( e.isShiftDown() && isSelected && !wasSelectedThisCycle)setIsSelected(false);//allow shift toggle off
				editingDelegate.controlEditReleased( this, e.isShiftDown(), false);//:self withShift:([theEvent modifierFlags] & NSShiftKeyMask)!=0 hadDrag:NO];
				
			}
			editingDelegate.updateGuide(null);
		}
	}

	@Override
	public void mouseDragged(MouseEvent e) {
		if(editingDelegate.isEditing()){
	        if(dragging==false){//first drag
	           // [[self undoManager] beginUndoGrouping];
	        }
	        dragging=true;
	        
	       // [[NSCursor closedHandCursor] push];
	        Point newDragLocation=SwingUtilities.convertPoint(this, e.getPoint(), this.getParent());//[[self superview] convertPoint:[event locationInWindow] fromView:nil];
	  //      Point newOrigin = new Point((int)(newDragLocation.getX()-clickOffsetInMe.getX()), (int)(newDragLocation.getY()-clickOffsetInMe.getY()));//CGPointMake(newDragLocation.x-clickOffsetInMe.x, newDragLocation.y-clickOffsetInMe.y);
	        
	    //    this.setLocation(newOrigin);//[self setFrameOriginObjectUndoable:[NSValue valueWithPoint:newOrigin]];
	        
	        editingDelegate.controlEditMoved(this, new Point(newDragLocation.x-lastDragLocation.x, newDragLocation.y-lastDragLocation.y));
	        editingDelegate.updateGuide(this);
	        lastDragLocation=newDragLocation;
	    }	
	}

	@Override
	public void mouseMoved(MouseEvent arg0) {
		// TODO Auto-generated method stub
		
	}
	
	// Ignore and pass through mouse events if not editing and widget is disabled.
	public boolean contains(int x, int y) {
		if (!this.isEnabled() && !editingDelegate.isEditing()) {
			return false;
		}
		return super.contains(x, y);
	}
}
