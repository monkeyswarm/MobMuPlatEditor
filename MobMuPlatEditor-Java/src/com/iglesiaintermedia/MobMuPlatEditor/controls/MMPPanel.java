package com.iglesiaintermedia.MobMuPlatEditor.controls;

import java.awt.Color;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.Rectangle;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;

import javax.imageio.ImageIO;
import javax.swing.ImageIcon;
import javax.swing.JLabel;

public class MMPPanel extends MMPControl{

	JLabel warningLabel;
	BufferedImage myPicture;
	public String imagePath;
	public boolean shouldPassTouches;
	
	public MMPPanel(MMPPanel otherPanel){
		this(otherPanel.getBounds());//normal constructor
		this.setColor(otherPanel.color);
		this.setHighlightColor(otherPanel.highlightColor);
		this.address=otherPanel.address;
		
		
		if(otherPanel.imagePath!=null){
			this.setImagePath(otherPanel.imagePath);
		}

	}

	public MMPPanel(Rectangle frame){
		super();
		address="/myPanel";
		
		warningLabel = new JLabel("File not found");
		warningLabel.setVisible(false);
		add(warningLabel);
	
		this.addMouseListener(this);
		this.addMouseMotionListener(this);
		this.setColor(color);
		this.setBounds(frame);
		
	}
	
	public void setBounds(Rectangle frame){
		super.setBounds(frame);
		warningLabel.setBounds(0,0,getWidth(),getHeight());
		this.repaint();
	}
	
	public void setColor(Color inColor){
		super.setColor(inColor);
		this.setBackground(inColor);
	}
	
	public void setImagePath(String inPath){
		imagePath = inPath;
	}
	
	public void loadImage(){
		changeImage(imagePath);
	}
	
	void changeImage(String newImagePath){
		 //NSString* constructedRelativePath = [[[[self.editingDelegate fileURL] path] stringByDeletingLastPathComponent] stringByAppendingPathComponent:newImagePath];
		String constructedRelativePath="";
		if(editingDelegate.filePath!=null){//if mmp is saved
			File me = new File(editingDelegate.filePath);
			 constructedRelativePath = me.getParent()+System.getProperty("file.separator")+newImagePath;//containing directory+"/"+newimagepath
		}
		//System.out.print("\nnewimagepath "+newImagePath+" \nconstructedrelative "+constructedRelativePath);
		//absolute
		if(new File(newImagePath).exists()){
			try{
				myPicture = ImageIO.read(new File(newImagePath));
				this.repaint();
				warningLabel.setVisible(false);
			}catch(IOException e){}
		}
		else if(new File(constructedRelativePath).exists()){
			try{
				myPicture = ImageIO.read(new File(constructedRelativePath));
				this.repaint();
				warningLabel.setVisible(false);
			}catch(IOException e){}
		}
		else{
			myPicture=null;
			this.repaint();
			warningLabel.setVisible(true);
		}
		/*if([[NSFileManager defaultManager] fileExistsAtPath:newImagePath]){
	        [imageView setImage:[[NSImage alloc]initWithContentsOfFile:newImagePath] ];
	        textField.hidden=YES;
	    }
	    else if ([[NSFileManager defaultManager] fileExistsAtPath:constructedRelativePath]){
	        [imageView setImage:[[NSImage alloc]initWithContentsOfFile:constructedRelativePath] ];
	        textField.hidden=YES;
	    }
	    
	    else{
	        [imageView setImage:nil];
	        textField.hidden=NO;
	    }*/

		
	}
	
	
	protected void paintComponent(Graphics g) {
		
        super.paintComponent(g);
        int width = getWidth();
        int height = getHeight();
        
        Graphics2D graphics = (Graphics2D) g;
        graphics.setColor(getBackground());
        graphics.fillRect(0, 0, width, height);
        if(myPicture!=null)
        	graphics.drawImage(myPicture, 0, 0, width, height, null);
       
	}
	
	public void receiveList(ArrayList<Object> messageArray){
		//System.out.print("\npanel receive");
		//change image
		if (messageArray.size()==2 && (messageArray.get(0) instanceof String) && messageArray.get(0).equals("image") && (messageArray.get(1) instanceof String)){
	    	changeImage((String)messageArray.get(1));
	    }
	    
	    else if (messageArray.size()==2 && (messageArray.get(0) instanceof String) && messageArray.get(0).equals("highlight") && (messageArray.get(1) instanceof Float || messageArray.get(1) instanceof Integer)){
	    	Object ob = messageArray.get(1);
	    	if(ob instanceof Float) {
	   			if (((Float)(ob)).floatValue()>0) this.setBackground(highlightColor);
	   			else this.setBackground(color);
	   		}
	   		else if(ob instanceof Integer){
    			if(((Integer)(ob)).intValue() >0)this.setBackground(highlightColor);
    			else this.setBackground(color);
	    	}
	   	}
	    
	}
	
}
