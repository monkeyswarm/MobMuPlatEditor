package com.iglesiaintermedia.MobMuPlatEditor.controls;

import java.awt.Color;
import java.awt.Point;
import java.awt.Rectangle;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.awt.event.MouseMotionListener;

import javax.swing.*;
import javax.swing.border.Border;
import javax.swing.SwingUtilities;

public class EditHandle extends JPanel implements MouseListener, MouseMotionListener{
	private Point startDragPoint;
	
	protected Border border = BorderFactory.createLineBorder(Color.black, 5);
	
	public EditHandle(){
		super();
		setOpaque(false);
		this.setBorder(border);
		this.addMouseListener(this);
		this.addMouseMotionListener(this);
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
		startDragPoint=SwingUtilities.convertPoint(this, e.getPoint(), this.getParent().getParent());
		MMPControl control = (MMPControl)this.getParent();
		control.editingDelegate.updateGuide(control);
	}

	@Override
	public void mouseReleased(MouseEvent arg0) {
		// TODO Auto-generated method stub
		MMPControl control = (MMPControl)this.getParent();
	
		if (control.editingDelegate.snapToGridEnabled == true) {
	      int newWidth = control.getWidth();
	      int newHeight = control.getHeight();
	      int snapToGridXVal = control.editingDelegate.snapToGridXVal;
	      int snapToGridYVal = control.editingDelegate.snapToGridYVal;
	      newWidth = (int)(snapToGridXVal * Math.floor(((float)newWidth/snapToGridXVal)+0.5));
	      newHeight = (int)(snapToGridYVal * Math.floor(((float)newHeight/snapToGridYVal)+0.5));

	      Rectangle newFrame = new Rectangle(control.getBounds().x, control.getBounds().y, newWidth, newHeight);
		    
		    //keep it from getting too small
		    if(newWidth>=40 && newHeight>=40)control.setBounds(newFrame);//[(MMPControl*)[self superview] setFrameObjectUndoable:[NSValue valueWithRect: newFrame]];
		    
	    }

		
		control.editingDelegate.updateGuide(null);
		
	}

	@Override
	public void mouseDragged(MouseEvent e) {
		Point newDragLocation=SwingUtilities.convertPoint(this, e.getPoint(), this.getParent().getParent());
		
	    int newWidth = this.getParent().getBounds().width+(newDragLocation.x-startDragPoint.x);
	    int newHeight = this.getParent().getBounds().height+(newDragLocation.y-startDragPoint.y);
	    Rectangle newFrame = new Rectangle(this.getParent().getBounds().x, this.getParent().getBounds().y, newWidth, newHeight);
	    
	    //keep it from getting too small
	    if(newWidth>=40 && newHeight>=40)this.getParent().setBounds(newFrame);//[(MMPControl*)[self superview] setFrameObjectUndoable:[NSValue valueWithRect: newFrame]];
	    
	    startDragPoint=newDragLocation;
	    
	    MMPControl control = (MMPControl)this.getParent();
		control.editingDelegate.updateGuide(control);
		
	}

	@Override
	public void mouseMoved(MouseEvent arg0) {
		// TODO Auto-generated method stub
		
	}
}
