package com.iglesiaintermedia.MobMuPlatEditor.controls;

import java.awt.Color;
import java.awt.Font;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Rectangle;
import java.awt.event.MouseListener;
import java.awt.event.MouseMotionListener;
import java.util.Map;

import javax.swing.BorderFactory;
import javax.swing.JPanel;
import javax.swing.JTextArea;

public class MMPUnknown extends MMPControl {

	String badName;
	JTextArea textView;
	JPanel overPanel;
	public Map<String, Object> badGUIDict;
	
	public MMPUnknown(Rectangle frame){
		super();
		address = "/myUnknownObject";
		this.setBackground(Color.GRAY);
		
		overPanel = new JPanel();//hack: textView was sending constant mouse dragged events (on mouse held still while dragging), rather than just one per drag
		overPanel.setOpaque(false);
		add(overPanel);
		
		textView = new JTextArea();
		//textView.setBounds(0,0,getWidth(), getHeight());
		textView.setForeground(Color.WHITE);
		textView.setFont(new Font("HelveticaNeue", Font.PLAIN, 12));
		textView.setOpaque(false);
		textView.setBackground(new Color(0,0,0,0));//redundant on aqua, neccesary on nimubs
		textView.setBorder(BorderFactory.createEmptyBorder());//redundant on aqua, neceesary on nimbus
		textView.setWrapStyleWord(true);
		textView.setLineWrap(true);
		textView.setEditable(false);
		
		for(MouseListener ml: textView.getMouseListeners())textView.removeMouseListener(ml);
		for(MouseMotionListener ml: textView.getMouseMotionListeners())textView.removeMouseMotionListener(ml);
		
		add(textView);
		
		overPanel.addMouseListener(this);
		overPanel.addMouseMotionListener(this);
		
		this.setBounds(frame);
	}
	
	public void setBadName(String inBadName){
	    badName = inBadName;
	    textView.setText("interface object "+badName+" not found");
	}
	
	public void setBounds(Rectangle frame){
		super.setBounds(frame);
	    textView.setBounds(0,0,this.getWidth(), this.getHeight());
	    overPanel.setBounds(0,0,this.getWidth(), this.getHeight());
	}
	
	protected void paintComponent(Graphics g) {
		
        super.paintComponent(g);
        int width = getWidth();
        int height = getHeight();
        
        Graphics2D graphics = (Graphics2D) g;
        graphics.setColor(getBackground());
        graphics.fillRect(0, 0, width, height);

       
	}
}
