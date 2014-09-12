package com.iglesiaintermedia.MobMuPlatEditor.controls;

import java.awt.Color;
import java.awt.Point;
import java.awt.Rectangle;
import java.awt.event.MouseEvent;
import java.awt.geom.Point2D;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;

import javax.swing.BorderFactory;
import javax.swing.JPanel;

public class MMPMultiTouch extends MMPControl{
	static final int BORDER_WIDTH = 3;
	static final int TOUCH_VIEW_RADIUS = 20;
	static final int CURSOR_WIDTH = 2;

	ArrayList<MyTouch> _touchStack;
	ArrayList<MyTouch> _touchByVoxArray;//add, then hold NSNull values for empty voices
	  
	JPanel borderPanel;
	TouchViewGroup _currTouchViewGroup;
	boolean _createdTouchOnMouseDown;
	MyTouch _currMyTouch;
	  
	public MMPMultiTouch(MMPMultiTouch otherMT){
		this(otherMT.getBounds());//normal constructor
		this.setColor(otherMT.color);
		this.setHighlightColor(otherMT.highlightColor);
		this.address=otherMT.address;
	}
	
	public MMPMultiTouch(Rectangle frame){
		super();
		address="/myMultiTouch";
		
		borderPanel = new JPanel();
		borderPanel.setOpaque(false);
		this.add(borderPanel);

	    _touchStack = new ArrayList<MyTouch>();
	    _touchByVoxArray = new ArrayList<MyTouch>();
		
		this.addMouseListener(this);
		this.addMouseMotionListener(this);
		this.setColor(color);
		this.setBounds(frame);
	}
	
	public void setBounds(Rectangle frame){
		super.setBounds(frame);
		borderPanel.setBounds(0,0,this.getWidth(), this.getHeight());
		//removeTouches(_touchStack);TODO
	}
	
	public void setColor(Color inColor){
		super.setColor(inColor);
		borderPanel.setBorder(BorderFactory.createLineBorder(inColor, BORDER_WIDTH));
		this.repaint();
	}
	
	Point clipPoint(Point inPoint) {
		Point outPoint = new Point();
		outPoint.x = Math.min(Math.max(0, inPoint.x), this.getWidth());
		outPoint.y = Math.min(Math.max(0, inPoint.y), this.getHeight());
		return outPoint;
	}
	
	Point2D.Float normAndClipPoint(Point inPoint){
		Point2D.Float outPoint = new Point2D.Float();
		outPoint.x = (float)inPoint.x/this.getWidth();
		outPoint.x = Math.min(1, Math.max(0, outPoint.x));
		outPoint.y = 1-((float)inPoint.y/this.getHeight());
		outPoint.y = Math.min(1, Math.max(0, outPoint.y));
		//System.out.print("norm in "+inPoint.x+" "+inPoint.y+" out "+outPoint.x+" "+outPoint.y);
		return outPoint;
	}
	
	public void mousePressed(MouseEvent e) {
		super.mousePressed(e);
		
		if(!editingDelegate.isEditing()){
			Point localPoint = e.getPoint();
			Point clippedPoint = clipPoint(localPoint);
			//scan trough touch views. WASTEFUL
			TouchView touchedView = null;
			for(MyTouch myTouch : _touchStack ){
				if(myTouch.touchViewGroup.touchView.getBounds().contains(localPoint) ) {
					//System.out.print("HIT");
					touchedView = myTouch.touchViewGroup.touchView;
				}
			}

			if(touchedView==null){
				//TouchView
				TouchViewGroup tvg = new TouchViewGroup();
				tvg.touchView = new TouchView();
				tvg.touchView.myGroup = tvg;
				tvg.touchView.setBounds(clippedPoint.x-TOUCH_VIEW_RADIUS, clippedPoint.y-TOUCH_VIEW_RADIUS, TOUCH_VIEW_RADIUS*2, TOUCH_VIEW_RADIUS*2);
				tvg.touchView.setCornerRadius(TOUCH_VIEW_RADIUS);
				tvg.touchView.setBackground(Color.BLACK);
				
				tvg.cursorX = new JPanel();
				tvg.cursorX.setBounds(0, clippedPoint.y-CURSOR_WIDTH/2, getWidth(), CURSOR_WIDTH);
				tvg.cursorX.setBackground(this.highlightColor);
				this.add(tvg.cursorX);
				
				tvg.cursorY = new JPanel();
				tvg.cursorY.setBounds(clippedPoint.x-CURSOR_WIDTH/2, 0, CURSOR_WIDTH, getHeight());
				tvg.cursorY.setBackground(this.highlightColor);
				this.add(tvg.cursorY);
				
				this.add(tvg.touchView);
				this.add(tvg.cursorX);
				this.add(tvg.cursorY);
				

				_currTouchViewGroup = tvg;
				_createdTouchOnMouseDown = true;

				//mytouch stack
				MyTouch myTouch = new MyTouch();
				myTouch.point = normAndClipPoint(e.getPoint());

				myTouch.touchViewGroup = tvg;
				tvg.myTouch = myTouch;
				_currMyTouch = myTouch;

				_touchStack.add(myTouch);


				//poly vox
				boolean added = false;
				for(Object element : _touchByVoxArray){
					if (element == null) {
						int index = _touchByVoxArray.indexOf(element);
						myTouch.polyVox = index + 1;
						_touchByVoxArray.set(index, myTouch);
						added = true;
						break;
					}
				}
				if (!added) {
					_touchByVoxArray.add(myTouch);
					int index = _touchByVoxArray.indexOf(myTouch);
					myTouch.polyVox = index + 1;
				}

				Object[] args = new Object[]{
						new String("touch"), 
						new Integer(myTouch.polyVox),
						new Integer(1),
						new Float(myTouch.point.x),
						new Float(myTouch.point.y)
				};
				editingDelegate.sendMessage(address, args);

				sendState();

				if(_touchStack.size()>0)
					borderPanel.setBorder(BorderFactory.createLineBorder(highlightColor, BORDER_WIDTH)); 
				

			}
			else {
				_currTouchViewGroup = touchedView.myGroup;
				_currMyTouch = _currTouchViewGroup.myTouch;
				_createdTouchOnMouseDown = false;
			}
		}
	}
	
	public void mouseDragged(MouseEvent e) {
		super.mouseDragged(e);
		
		if(!editingDelegate.isEditing()){
			Point clippedPoint = clipPoint(e.getPoint());
			
			_currTouchViewGroup.touchView.setBounds(clippedPoint.x-TOUCH_VIEW_RADIUS, clippedPoint.y-TOUCH_VIEW_RADIUS, TOUCH_VIEW_RADIUS*2, TOUCH_VIEW_RADIUS*2);
			_currTouchViewGroup.cursorX.setBounds(0, clippedPoint.y-CURSOR_WIDTH/2, getWidth(), CURSOR_WIDTH);
			_currTouchViewGroup.cursorY.setBounds(clippedPoint.x-CURSOR_WIDTH/2, 0, CURSOR_WIDTH, getHeight());
			_currMyTouch.point = normAndClipPoint(e.getPoint());
			
			Object[] args = new Object[]{
	    			new String("touch"), 
	    			new Integer(_currMyTouch.polyVox),
	    			new Integer(2),
	    			new Float(_currMyTouch.point.x),
	    			new Float(_currMyTouch.point.y)
	    	};
			editingDelegate.sendMessage(address, args);
			sendState();
		}
	}
	
	public void mouseReleased(MouseEvent e) {
		super.mouseReleased(e);
		//System.out.print("\nreleased");
	}
	
    public void mouseClicked(MouseEvent e) {
    	super.mouseClicked(e);
    	//System.out.print("\nclicked");
		if(!editingDelegate.isEditing()){
			if(_createdTouchOnMouseDown==false){
				ArrayList<MyTouch> touchesToRemoveArray = new ArrayList<MyTouch>();
				_currMyTouch.point = normAndClipPoint(e.getPoint());//necc?
				touchesToRemoveArray.add(_currMyTouch);
				removeTouches(touchesToRemoveArray);
				if (_touchStack.size()==0) borderPanel.setBorder(BorderFactory.createLineBorder(color, BORDER_WIDTH)); 
			}
		}	
	}
    
    void removeTouches(ArrayList<MyTouch> touchesToRemove) {
    	for(MyTouch myTouch : touchesToRemove) {
    		_touchStack.remove(myTouch);
    	
    		this.remove(myTouch.touchViewGroup.touchView);
    		this.remove(myTouch.touchViewGroup.cursorX);
    		this.remove(myTouch.touchViewGroup.cursorY);
    		
    		Object[] args = new Object[]{
	    			new String("touch"), 
	    			new Integer(myTouch.polyVox),
	    			new Integer(0),
	    			new Float(myTouch.point.x),
	    			new Float(myTouch.point.y)
	    	};
    		editingDelegate.sendMessage(address, args);
    		
    		_touchByVoxArray.set(_touchByVoxArray.indexOf(myTouch), null);
    	}
    	sendState();
    	borderPanel.repaint();
    	
    }
    
    void sendState(){
    	
    	ArrayList<MyTouch> valArray = new ArrayList<MyTouch>(_touchStack.size());
    	for(MyTouch touch : _touchStack){
    		valArray.add(touch.clone());
    	}
    	
    	//send as is.
    	ArrayList<Object> msgArray = new ArrayList<Object>(3*valArray.size()+1);
    	msgArray.add(new String("touchesByTime"));
    	for(MyTouch touch : valArray){
    		msgArray.add(new Integer(touch.polyVox));
    		msgArray.add(new Float(touch.point.x));
    		msgArray.add(new Float(touch.point.y));
    	}
    	editingDelegate.sendMessage(address, msgArray.toArray());
    	
    	//sort via vox
    	Collections.sort(valArray, new Comparator<MyTouch>() {
    	    public int compare(MyTouch a, MyTouch b) {
    	    	if(a.polyVox < b.polyVox) return -1;
    	        else if (a.polyVox > b.polyVox) return 1;
    	        else return 0;
    	    }
    	});
    	
    	msgArray.clear();
    	msgArray.add(new String("touchesByVox"));
    	for(MyTouch touch : valArray){
    		msgArray.add(new Integer(touch.polyVox));
    		msgArray.add(new Float(touch.point.x));
    		msgArray.add(new Float(touch.point.y));
    	}
    	editingDelegate.sendMessage(address, msgArray.toArray());
    	
    	//sort via X
    	Collections.sort(valArray, new Comparator<MyTouch>() {
    	    public int compare(MyTouch a, MyTouch b) {
    	    	if(a.point.x < b.point.x) return -1;
    	        else if (a.point.x > b.point.x) return 1;
    	        else return 0;
    	    }
    	});
    	
    	msgArray.clear();
    	msgArray.add(new String("touchesByX"));
    	for(MyTouch touch : valArray){
    		msgArray.add(new Integer(touch.polyVox));
    		msgArray.add(new Float(touch.point.x));
    		msgArray.add(new Float(touch.point.y));
    	}
    	editingDelegate.sendMessage(address, msgArray.toArray());
    	
    	//sort via Y
    	Collections.sort(valArray, new Comparator<MyTouch>() {
    	    public int compare(MyTouch a, MyTouch b) {
    	    	if(a.point.y < b.point.y) return -1;
    	        else if (a.point.y > b.point.y) return 1;
    	        else return 0;
    	    }
    	});
    	
    	msgArray.clear();
    	msgArray.add(new String("touchesByY"));
    	for(MyTouch touch : valArray){
    		msgArray.add(new Integer(touch.polyVox));
    		msgArray.add(new Float(touch.point.x));
    		msgArray.add(new Float(touch.point.y));
    	}
    	editingDelegate.sendMessage(address, msgArray.toArray());
    	
    }
	
}

class MyTouch{
	Point2D.Float point;
	TouchViewGroup touchViewGroup;
	int polyVox;
	
	public MyTouch clone(){
		MyTouch newTouch = new MyTouch();
		newTouch.point = (Point2D.Float)this.point.clone();
		newTouch.polyVox = this.polyVox;
		return newTouch;
	}
}

class TouchView extends RoundedPanel{
	TouchViewGroup myGroup;
}

class TouchViewGroup{
	MyTouch myTouch;
	TouchView touchView;
	JPanel cursorX;
	JPanel cursorY;
	
	
}


