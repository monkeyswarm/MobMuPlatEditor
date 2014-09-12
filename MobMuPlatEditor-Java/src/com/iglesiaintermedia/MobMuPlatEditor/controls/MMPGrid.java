package com.iglesiaintermedia.MobMuPlatEditor.controls;

import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Dimension;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Rectangle;
import java.awt.RenderingHints;
import java.awt.event.MouseEvent;
import java.util.ArrayList;

import javax.swing.JPanel;

public class MMPGrid extends MMPControl {
	static final int EDGE_RADIUS = 2;
	static final Color clearColor = new Color(0,0,0,0);
	
	public int dimX;
	public int dimY;
	public int borderThickness;
	public int cellPadding;
	int mode;
	
	
	public void setMode(int mode){
		this.mode = mode;
	}
	public int getMode(){
		return mode;
	}
	
	ArrayList<TogglePanel> togglePanelArray; 
	
	public MMPGrid(MMPGrid otherGrid){
		this(otherGrid.getBounds());//normal constructor
		this.setColor(otherGrid.color);
		this.setHighlightColor(otherGrid.highlightColor);
		this.address=otherGrid.address;
		
		this.setMode(otherGrid.mode);
		this.setDimX(otherGrid.dimX);
		this.setDimY(otherGrid.dimY);
		this.setBorderThickness(otherGrid.borderThickness);
		this.setCellPadding(otherGrid.cellPadding);
		
		
	}
	
	public MMPGrid(Rectangle frame){
		super();
		//borderThickness=5;
		
		togglePanelArray = new ArrayList<TogglePanel>();
		dimY=2;
		dimX=2;
		address="/myGrid";
		
		
		setCellPadding(2);
		setBorderThickness(3);
		setDimX(4);
		setDimY(3);
		
		
		this.addMouseListener(this);
		this.addMouseMotionListener(this);
		this.setColor(this.color);
		this.setBounds(frame);
		
	}
	
	public void setBounds(Rectangle frame){
		super.setBounds(frame);
		
		int buttonWidth = getWidth()/dimX;
		int buttonHeight = getHeight()/dimY;
		
		for(int j=0;j<dimY;j++){
	        for(int i=0;i<dimX;i++){
			TogglePanel currTogglePanel = togglePanelArray.get(j*dimX+i);
			currTogglePanel.setBounds(new Rectangle(i*buttonWidth, j*buttonHeight, buttonWidth-cellPadding, buttonHeight-cellPadding));
	        }
		}
	}
	
	public void setCellPadding(int inPadding){
		cellPadding = inPadding;
		redrawDim();
	}
	public void setBorderThickness(int inThickness){
		borderThickness = inThickness;
		redrawDim();//ness whole redraw??? just iterate and set thickness
	}
	public void setDimX(int inDimX){
		dimX = inDimX;
		redrawDim();
	}
	public void setDimY(int inDimY){
		dimY = inDimY;
		redrawDim();
	}
	
	void redrawDim(){
		int buttonWidth = getWidth()/dimX;
		int buttonHeight = getHeight()/dimY;
		//System.out.print("\nredraw dim "+ buttonWidth+" "+buttonHeight);
		
		for(TogglePanel tp : togglePanelArray)tp.getParent().remove(tp);
		togglePanelArray.clear();
		
		 for(int j=0;j<dimY;j++){
		        for(int i=0;i<dimX;i++){
		            TogglePanel togglePanel = new TogglePanel();
		            togglePanel.setBorderThickness(borderThickness);
		            togglePanel.addMouseListener(this);
		            togglePanel.addMouseMotionListener(this);
		            togglePanelArray.add(togglePanel);
		            add(togglePanel);
		            //for some reason this only causes refresh if done after adding to panel
		            togglePanel.setBounds(new Rectangle(i*buttonWidth, j*buttonHeight, buttonWidth-cellPadding, buttonHeight-cellPadding));
	        }
		   }
		 
		 this.repaint();//helps...

	}
	
	public void setColor(Color newColor){
		super.setColor(newColor);
		
		
		this.repaint();//repaint border
	}
	
	/*public void mousePressed(MouseEvent e) {
		//System.out.print(e.getClickCount() + " click(s)");
		super.mousePressed(e);
		
		if(!editingDelegate.isEditing()){
	      //setValue(1-value);
	      //sendValue();
			for(TogglePanel tp: togglePanelArray){
				if(tp.getBounds().contains(e.getX(), e.getY())){
					//System.out.print("\nhit togglepanel "+togglePanelArray.indexOf(tp));
					tp.value = 1-tp.value;
					if(tp.value==1)tp.setColor(highlightColor);
					else tp.setColor(clearColor);
					
					int hitViewIndex = togglePanelArray.indexOf(tp);
					
					Object[] args = new Object[]{new Integer(hitViewIndex%dimX), new Integer(hitViewIndex/dimX), new Integer(tp.value)};
					editingDelegate.sendMessage(this.address, args);
				}
			}
	      
	      
	    }
	}*/
	
	void sendValueOfPanel(TogglePanel tp){
		int hitViewIndex = togglePanelArray.indexOf(tp);
		
		Object[] args = new Object[]{new Integer(hitViewIndex%dimX), new Integer(hitViewIndex/dimX), new Integer(tp.value)};
		editingDelegate.sendMessage(this.address, args);
	}
	
	void doOn(TogglePanel tp){
		tp.value=1;
		tp.setColor(highlightColor);
		sendValueOfPanel(tp);
	}
	void doOff(TogglePanel tp){
		tp.value=0;
		tp.setColor(clearColor);
		sendValueOfPanel(tp);
	}
	
	public void mouseDragged(MouseEvent e) {
		super.mouseDragged(e);
		if(!editingDelegate.isEditing() && e.getComponent()!=this){
	    	if(mode==1) {//release button if it was the one that was just pressed
	    		TogglePanel tp = (TogglePanel) e.getComponent();
	    	    if(!tp.contains(e.getPoint()) && tp.value==1) {
	    	      doOff(tp);
	    	    }
	    	  }
	    	}
	}
	
	public void mousePressed(MouseEvent e){
		super.mousePressed(e);
		
		if(!editingDelegate.isEditing() && e.getComponent()!=this){
			//System.out.print("\nhit togglepanel");
			TogglePanel tp = (TogglePanel) e.getComponent();
			if(mode==0){
				if(tp.value==0)doOn(tp);
				else doOff(tp);
			} 
			else if (mode==1){//momentary
		        if(tp.value==0)doOn(tp);
		    }
		    else {//hybrid, on change
		        if(tp.value==0)doOn(tp);
		        else doOff(tp);
		    }
		}
	}
	public void mouseReleased(MouseEvent e) {
		super.mouseReleased(e);
			
		if(!editingDelegate.isEditing() && e.getComponent()!=this){
			TogglePanel tp = (TogglePanel) e.getComponent();
				
			if(mode ==1 && tp.value==1){
				doOff(tp);
			}
			else if (mode ==2 && tp.value==1 && tp.contains(e.getPoint())){//if still within the panel, off
				doOff(tp);
			}
		}
    }

	class TogglePanel extends JPanel{
		RoundedBorderPanel borderPanel;
		RoundedPanel touchPanel;
		int value;
		public TogglePanel(){
			super();
			setLayout(null);
			borderPanel = new RoundedBorderPanel();
			add(borderPanel);
			
			touchPanel = new RoundedPanel();
			touchPanel.setCornerRadius(EDGE_RADIUS);
			touchPanel.setBackground(clearColor);
			add(touchPanel);
		
			setOpaque(false);
		}
		
		public void setColor(Color inColor){
			touchPanel.setBackground(inColor);
		}
		
		
		public void setBounds(Rectangle frame){
			super.setBounds(frame);
			borderPanel.setBounds(new Rectangle(0,0,this.getWidth(), this.getHeight()));
			//touchPanel.setBounds(new Rectangle(0,0,this.getWidth(), this.getHeight()));
			touchPanel.setBounds(borderThickness/2, borderThickness/2, getWidth()-borderThickness, getHeight()-borderThickness);

		}
		
		public void setBorderThickness(int inBorderThickness){
			//borderPanel.setBorderThickness(inBorderThickness);
			this.setBounds(this.getBounds());
		}
	
		
	}
	
	class RoundedBorderPanel extends JPanel{
		//int borderThickness;
		//protected Dimension arcs = new Dimension(EDGE_RADIUS, EDGE_RADIUS);
		
		public RoundedBorderPanel(){
			super();
			setOpaque(false);
			//borderThickness=5;
		}
		
		/*public void setBorderThickness(int inBorderThickness){
			borderThickness = inBorderThickness;
		}*/
		
		
		protected void paintBorder(Graphics g) {
	        //System.out.print("\npaintBorder w h "+getWidth()+" "+this.getHeight());
			if(borderThickness>0){//added this because on borderthickness=0 it was still drawing a border...
	        Graphics2D g2 = (Graphics2D)g.create();
	        g2.setColor(color);
	        g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
	        g2.setStroke(new BasicStroke(borderThickness,BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
	        g2.drawRoundRect(borderThickness/2, borderThickness/2, getWidth()-borderThickness-1, this.getHeight()-borderThickness-1, EDGE_RADIUS*2, EDGE_RADIUS*2);
			}
		}
		
		
		
	}
	
	//receive messages from PureData (via [send toGUI], routed through the PdWrapper.pd patch), routed from Document via the address to this object
	public void receiveList(ArrayList<Object> messageArray){
		//System.out.print("receive size "+messageArray.size()+" element 1 int? "+(messageArray.get(1) instanceof Integer));
		boolean sendVal  = true;
		//if message preceded by "set", then set "sendVal" flag to NO, and strip off set and make new messages array without it
	    if (messageArray.size()>0 && (messageArray.get(0) instanceof String) && messageArray.get(0).equals("set") ){
	        //messageArray.remove(0);bad!
	    	messageArray = new ArrayList<Object>(messageArray.subList(1, messageArray.size() ) );
	        sendVal=false;
	    }
	    
	    //if message is three numbers, look at message and set my value, outputting value if required
	    if (messageArray.size()==3 && (messageArray.get(0) instanceof Float || messageArray.get(0) instanceof Integer) && (messageArray.get(1) instanceof Float || messageArray.get(1) instanceof Integer) && (messageArray.get(2) instanceof Float || messageArray.get(2) instanceof Integer)){
	 	   int indexX =0;
	 	   if(messageArray.get(0) instanceof Float)  indexX= (int) ((Float)(messageArray.get(0))).floatValue() ;
	 	   else indexX=  ((Integer)(messageArray.get(0))).intValue() ;
	 	   
	 	  int indexY =0;
	 	   if(messageArray.get(1) instanceof Float)  indexY= (int) ((Float)(messageArray.get(0))).floatValue() ;
	 	   else indexY=  ((Integer)(messageArray.get(1))).intValue() ;
	 	   
	 	  int val =0;
	 	   if(messageArray.get(2) instanceof Float)  val= (int) ((Float)(messageArray.get(0))).floatValue() ;
	 	   else val=  ((Integer)(messageArray.get(2))).intValue() ;
	 	   
	 	 if(indexX<dimX && indexY<dimY){
	 		 TogglePanel currTogglePanel = togglePanelArray.get(indexX+indexY*dimX);
	 		if(val>0)val=1;if(val<0)val=0;
	 		currTogglePanel.value=val;
	 		if(val==1)currTogglePanel.setColor(highlightColor);
			else currTogglePanel.setColor(clearColor);
	 		
	 		if(sendVal){
	 			Object[] args = new Object[]{new Integer(indexX), new Integer(indexY), new Integer(val)};
				editingDelegate.sendMessage(this.address, args);
	 		}
	 	 }
	    }
	 	 
	 	//else if message starts with "getColumn", spit out array of that column's values
	 	 else if (messageArray.size()==2 && (messageArray.get(0) instanceof String) && (messageArray.get(0).equals("getcolumn")) && (messageArray.get(1) instanceof Float || messageArray.get(1) instanceof Integer) ) {
		 	   int colIndex =0;
		 	  if(messageArray.get(1) instanceof Float)  colIndex= (int) ((Float)(messageArray.get(1))).floatValue() ;
		 	   else colIndex=  ((Integer)(messageArray.get(1))).intValue() ;
		 	  
		 	   if(colIndex>=0 && colIndex<dimX){
		 		   Object[] args = new Object[dimY];
		 		  for(int i=0;i<dimY;i++){
		 			  int currValue = togglePanelArray.get(colIndex+dimX*i).value;
		 			  args[i]=new Integer(currValue);
		 		  }
		 		 editingDelegate.sendMessage(this.address, args);
		 	   }
	 	 }
	 	//else if message starts with "getRow", spit out array of that row's values
	 	else if (messageArray.size()==2 && (messageArray.get(0) instanceof String) && (messageArray.get(0).equals("getrow")) && (messageArray.get(1) instanceof Float || messageArray.get(1) instanceof Integer) ) {
	 		 int rowIndex =0;
		 	  if(messageArray.get(1) instanceof Float)  rowIndex= (int) ((Float)(messageArray.get(1))).floatValue() ;
		 	   else rowIndex=  ((Integer)(messageArray.get(1))).intValue() ;
		 	  
		 	  if(rowIndex>=0 && rowIndex<dimY){
		 		   Object[] args = new Object[dimY];
		 		  for(int i=0;i<dimX;i++){
		 			  int currValue = togglePanelArray.get(i+dimX*rowIndex).value;
		 			  args[i]=new Integer(currValue);
		 		  }
		 		 editingDelegate.sendMessage(this.address, args);
		 	   }
	 	 }
	 	//clear
	 	else if (messageArray.size()==1 && (messageArray.get(0) instanceof String) && (messageArray.get(0).equals("clear")) ) {
			for(TogglePanel tp : togglePanelArray){
				if(tp.value==1){
					tp.value=0;
					tp.setColor(clearColor);
				}
			}
			//this.repaint();
	 	}
	    
	    
	    

	}
}
