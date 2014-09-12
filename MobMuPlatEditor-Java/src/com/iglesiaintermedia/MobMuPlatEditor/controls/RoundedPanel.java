package com.iglesiaintermedia.MobMuPlatEditor.controls;

import java.awt.*;

import javax.swing.*;

public class RoundedPanel extends JPanel {
	protected Dimension arcs = new Dimension(5, 5);
	
	public RoundedPanel() {
        super();
        setOpaque(false);
    }
	
	public void setCornerRadius(int rad){
		arcs= new Dimension(rad, rad);
		this.repaint();
	}
	
	@Override
    protected void paintComponent(Graphics g) {
        super.paintComponent(g);
        int width = getWidth();
        int height = getHeight();
        
        Graphics2D graphics = (Graphics2D) g;

      
        graphics.setRenderingHint(RenderingHints.KEY_ANTIALIASING, 
    			RenderingHints.VALUE_ANTIALIAS_ON);

        //Draws the rounded opaque panel with borders.
        graphics.setColor(getBackground());
        graphics.fillRoundRect(0, 0, width -1, height -1, arcs.width*2, arcs.height*2);
        graphics.setColor(getForeground());
        //graphics.setStroke(new BasicStroke(strokeSize));
       // graphics.setStroke(arg0)
        //graphics.drawRoundRect(0, 0, width , 
		//height , arcs.width, arcs.height);

        //Sets strokes to default, is better.
        //graphics.setStroke(new BasicStroke());
    }
	
}
