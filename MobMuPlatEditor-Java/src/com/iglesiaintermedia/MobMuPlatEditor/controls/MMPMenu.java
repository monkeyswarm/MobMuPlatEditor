package com.iglesiaintermedia.MobMuPlatEditor.controls;
import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Component;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.util.ArrayList;
import java.util.List;
import java.awt.Rectangle;
import java.awt.RenderingHints;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.awt.event.MouseMotionListener;

import javax.swing.AbstractListModel;
import javax.swing.BorderFactory;
import javax.swing.DefaultListCellRenderer;
import javax.swing.JButton;
import javax.swing.JList;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JTextField;
import javax.swing.ListSelectionModel;
import javax.swing.SwingConstants;
import javax.swing.event.ListSelectionEvent;
import javax.swing.event.ListSelectionListener;

//import com.iglesiaintermedia.MobMuPlatEditor.controls.MMPToggle.RoundedBorderPanel;

public class MMPMenu extends MMPControl implements ListSelectionListener, ActionListener{
	public static final int EDGE_RADIUS = 5;
	static final String DEFAULT_FONT = "HelveticaNeue";
	//#define DEFAULT_FONT @"HelveticaNeue"
	//#define DEFAULT_FONTSIZE 18
	public static final int TAB_WIDTH = 30;
	
	public String titleString;

	RoundedBorderPanel borderPanel, downPanel;
	JTextField textField;
	JScrollPane listScroller;
	JPanel topPanel;
	
	//data
	List<String> stringList;
	JList list;
	
	public MMPMenu(MMPMenu otherMenu){
		this(otherMenu.getBounds());//normal constructor
		this.setColor(otherMenu.color);
		this.setHighlightColor(otherMenu.highlightColor);
		this.address=otherMenu.address;
		this.setTitleString(otherMenu.titleString);
	}
	
	public MMPMenu(Rectangle frame){
		super();
		address="/myMenu";
		titleString = "Menu";
		stringList = new ArrayList<String>();
		
		borderPanel = new RoundedBorderPanel();
		add(borderPanel);
		downPanel = new RoundedBorderPanel();
		add(downPanel);
		
		textField = new JTextField(titleString);
		textField.addMouseListener(this);
		textField.addMouseMotionListener(this);
		
		add(textField);
		
		textField.setForeground(this.color);
		textField.setHorizontalAlignment(SwingConstants.CENTER);
		textField.setFont(new Font(DEFAULT_FONT, Font.PLAIN, 18));
		textField.setOpaque(false);
		textField.setBackground(new Color(0,0,0,0));//redundant on aqua, neccesary on nimubs
		textField.setBorder(BorderFactory.createEmptyBorder());//redundant on aqua, neceesary on nimbus
		//textView.setWrapStyleWord(true);
		//textView.setLineWrap(true);
		textField.setEditable(false);
		//textField.setEnabled(false);
		
		this.addMouseListener(this);
		this.addMouseMotionListener(this);
		this.setColor(this.color);
		this.setBounds(frame);
	}
	
	public void setTitleString(String newTitleString){
		titleString = newTitleString;
		textField.setText(newTitleString);
	}

	public void setBounds(Rectangle frame){
		super.setBounds(frame);
		borderPanel.setBounds(0,0,this.getWidth(), this.getHeight());
		downPanel.setBounds(0,0,TAB_WIDTH,this.getHeight());
		textField.setBounds(TAB_WIDTH,0,this.getWidth()-TAB_WIDTH, this.getHeight());
		//togglePanel.setBounds(borderThickness/2, borderThickness/2, getWidth()-borderThickness, getHeight()-borderThickness);
	}
	
	public void setColor(Color newColor){
		super.setColor(newColor);
		textField.setForeground(newColor);
		/*Border border = BorderFactory.createLineBorder(newColor, BORDER_WIDTH);
		borderView.setBorder(border);*/
		//togglePanel.setBackground(newColor);
		
		this.repaint();//repaint border
	}
	
	public void mousePressed(MouseEvent e) {
		//System.out.print(e.getClickCount() + " click(s)");
		super.mousePressed(e);
		
		if(!editingDelegate.isEditing()){
	      showTable();
	      //buttonPanel.setBackground(highlightColor);
	      
	    }
	}


	@Override
	public void mouseReleased(MouseEvent e) {
		super.mouseReleased(e);
	    if(!editingDelegate.isEditing()){
	    	
	    	//buttonPanel.setBackground(color);
	    }
		
	}
   void showTable(){
	   JPanel canvasPanel = this.editingDelegate.windowDelegate.canvasOuterPanel;
	   
	   topPanel = new JPanel();
	   topPanel.setBounds(0,0,canvasPanel.getWidth(), 60);
	   topPanel.setBackground(Color.DARK_GRAY);  
	   topPanel.setLayout(null);
	   canvasPanel.add(topPanel);
	   
	   JButton doneButton = new JButton("Done");
	   doneButton.setBounds(0,0,80,60);
	   doneButton.setFont(new Font(DEFAULT_FONT, Font.PLAIN, 18));
	   doneButton.setBackground(new Color(0,0,0,0));
	   //No way to set button BG on Mac L&F :(
	   //doneButton.setOpaque(false);
	   //doneButton.setBorderPainted(false);
	   doneButton.setForeground(new Color(0.0f, 0.2f, 1.0f));
	   topPanel.add(doneButton);
		doneButton.addActionListener(this);
		doneButton.setActionCommand("done");
		
		//title
		JTextField textField = new JTextField(titleString);
		textField.setForeground(Color.WHITE);
		textField.setFont(new Font(DEFAULT_FONT, Font.PLAIN, 24));
		textField.setOpaque(false);
		textField.setBackground(new Color(0,0,0,0));//redundant on aqua, neccesary on nimubs
		textField.setBorder(BorderFactory.createEmptyBorder());//redundant on aqua, neceesary on nimbus
		textField.setEditable(false);
		textField.setBounds(80,0,canvasPanel.getWidth()-80,60);
		textField.setHorizontalAlignment(SwingConstants.CENTER);
		topPanel.add(textField);
	   
	   //Object[] stringList = new Object[100];
	   //for(int i=0;i<100;i++)stringList[i]="hi";
		
	   list = new JList(stringList.toArray()); //data has type Object[]
	   list.setSelectionMode(ListSelectionModel.SINGLE_INTERVAL_SELECTION);
	   list.setLayoutOrientation(JList.VERTICAL);
	   list.setVisibleRowCount(-1);
	   list.setFixedCellHeight(44);
	   list.addListSelectionListener(this);
	   list.setFont(new Font(DEFAULT_FONT, Font.PLAIN, 18));
	   //list.setAlignmentX(CENTER_ALIGNMENT);
	   //list.setAlignmentY(CENTER_ALIGNMENT);
	   list.setBackground(this.editingDelegate.patchBackgroundColor());
	   MyCellRenderer rend = new MyCellRenderer();
	   MyCellRenderer.color = this.editingDelegate.patchBackgroundColor();
	   MyCellRenderer.textColor = this.color;
	   list.setCellRenderer(rend); 
	   
	   listScroller = new JScrollPane(list);
	   listScroller.setBounds(0,60, canvasPanel.getWidth(), canvasPanel.getHeight()-60 );
	   listScroller.setBackground(editingDelegate.patchBackgroundColor());//affects slim border around edge?
	   //listScroller.setPreferredSize(new Dimension(250, 80));
	   
	   
	   System.out.print("Canvas bounds"+this.editingDelegate.windowDelegate.canvasPanel.getBounds().width);
	   canvasPanel.add(listScroller);
	   canvasPanel.setComponentZOrder(listScroller, 0);
	   canvasPanel.setComponentZOrder(topPanel, 0);
	   canvasPanel.repaint();
	   canvasPanel.revalidate();
   }

   public void valueChanged(ListSelectionEvent arg0) {//Selection
		// TODO Auto-generated method stub
	//System.out.print("HERE:"+arg0.getFirstIndex());
	   int index = arg0.getFirstIndex();
	   String stringVal = stringList.get(index);
	   Object[] args = new Object[]{new Integer(index), stringVal};
	   editingDelegate.sendMessage(address, args);
	   
	   removeListFromCanvas();
   }
   
   void removeListFromCanvas(){
	   JPanel canvasPanel = this.editingDelegate.windowDelegate.canvasOuterPanel;   
		canvasPanel.remove(listScroller);
		canvasPanel.remove(topPanel);
		canvasPanel.repaint();
   }
   
   public void actionPerformed(ActionEvent arg0) {
		// TODO Auto-generated method stub
	   removeListFromCanvas();
	}
   
   public void receiveList(ArrayList<Object> messageArray){
		List<String> newDataArray = new ArrayList<String>();
		
	 //put all elements in list into a string array
    	
	   	for(Object ob: messageArray){
	    	if(ob instanceof String) newDataArray.add((String)ob);
	   		else if(ob instanceof Float) newDataArray.add(String.format("%.3f",((Float)(ob)).floatValue()) );
	   		else if(ob instanceof Integer) newDataArray.add(String.format("%d",((Integer)(ob)).intValue()) );
	   	}
    	
	   	stringList = newDataArray;
	   	
	   	//reload table
	   	//when I made list a class variable, stuff got very unhappy...so it doesn't reload in java
	   	/*JPanel canvasPanel = this.editingDelegate.windowDelegate.canvasPanel;
	   	canvasPanel.repaint();
		canvasPanel.revalidate();*/
   }
   
   class RoundedBorderPanel extends JPanel{
		
		public RoundedBorderPanel(){
			super();
			setOpaque(false);
		}
		
		protected void paintBorder(Graphics g) {
			//int borderThickness=1;
	        //System.out.print("\npaintBorder "+borderThickness);
			int borderThickness = 2;
			Graphics2D g2 = (Graphics2D)g.create();
	        g2.setColor(color);
	        g2.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
	        g2.setStroke(new BasicStroke(borderThickness,BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
	        g2.drawRoundRect(borderThickness/2, borderThickness/2, getWidth()-borderThickness-1, getHeight()-borderThickness-1, EDGE_RADIUS*2, EDGE_RADIUS*2);
	   
			
		}		
	}
   
   private static class MyCellRenderer extends DefaultListCellRenderer {  
	   static Color color;
	   static Color textColor;
	   
       public Component getListCellRendererComponent( JList list, Object value, int index, boolean isSelected, boolean cellHasFocus ) {  
    	   this.setHorizontalAlignment(SwingConstants.CENTER);
    	   Component c = super.getListCellRendererComponent( list, value, index, isSelected, cellHasFocus );  
           //if ( index % 2 == 0 ) {  
               c.setBackground( color );  
               c.setForeground(textColor);
           /*}  
           else {  
               c.setBackground( Color.white );  
           } */ 
           return c;  
       }  
   } 

   
}


