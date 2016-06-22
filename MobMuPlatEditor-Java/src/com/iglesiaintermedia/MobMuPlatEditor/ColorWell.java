package com.iglesiaintermedia.MobMuPlatEditor;

import javax.swing.*;
import javax.swing.colorchooser.AbstractColorChooserPanel;
import javax.swing.colorchooser.ColorSelectionModel;
import javax.swing.event.*;

import java.awt.Color;
import java.awt.Font;
import java.awt.GridLayout;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;

public class ColorWell extends JButton implements MouseListener, ChangeListener{
	boolean hasAlpha;
	
	 JColorChooser colorChooser;
	 JPanel colorPanel;
	 
	 MMPWindow delegate;
	
	public ColorWell() {
		super();
		colorPanel = new JPanel();
		colorPanel.setSize(50, 20);
		
		this.add(colorPanel);
		
		this.addMouseListener(this);
	}
	
	public void setColor(Color c){
		//System.out.print("\nsetColor");
		colorPanel.setBackground(c);
		this.repaint();
	}
	

	@Override
	public void mouseClicked(MouseEvent arg0) {
		// TODO Auto-generated method stub
		Color currColor = colorPanel.getBackground();
		System.out.print("\ncurrColor "+currColor.getRed()+" "+currColor.getGreen()+" "+currColor.getBlue() );
		colorChooser = new JColorChooser(colorPanel.getBackground());
		if(hasAlpha==true){
			/*AlphaPanel gsp = new AlphaPanel();
			colorChooser.addChooserPanel(gsp);
			gsp.scale.setValue(currColor.getAlpha());
			//System.out.print("\ngsp set alpha slider "+alpha);
			gsp.scale.addChangeListener(this);*/
			//TODO add a transarency slider to the "swatches" page.
		}
		
	    ColorSelectionModel model = colorChooser.getSelectionModel();	      
	    model.addChangeListener(this);
	
	    JDialog dialog = JColorChooser.createDialog(null, "Change Color", true,
	            colorChooser, null, null);
	    dialog.setVisible(true);
	}

	public void stateChanged(ChangeEvent changeEvent) {
		//System.out.print("!");
		Color chooserColor = colorChooser.getColor();
		
		//System.out.print("\nalpha "+ alpha);
		
		Color newColor = new Color(chooserColor.getRed(), chooserColor.getGreen(), chooserColor.getBlue(), hasAlpha ? chooserColor.getAlpha() : 255);
		colorPanel.setBackground(newColor);
		this.repaint();
		if(delegate!=null)delegate.colorWellChanged(this, newColor);
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
	public void mousePressed(MouseEvent arg0) {
		// TODO Auto-generated method stub
		
	}

	@Override
	public void mouseReleased(MouseEvent arg0) {
		// TODO Auto-generated method stub
		
	}

}



/*class AlphaPanel extends AbstractColorChooserPanel  {
	
	public JSlider scale;


	public AlphaPanel() {
		setLayout(new GridLayout(0, 1));

		// create the slider and attach us as a listener
		scale = new JSlider(JSlider.HORIZONTAL, 0, 255, 128);
		scale.setValue(255);
		//scale.addChangeListener(this);

		// Set up our display for the chooser
		add(new JLabel("Choose Transparency:", JLabel.CENTER));
		JPanel jp = new JPanel();
		jp.add(new JLabel("Clear"));
		jp.add(scale);
		jp.add(new JLabel("Opaque"));
		add(jp);

	}

	// We did this work in the constructor so we can skip it here.
	protected void buildChooser() {
	}

// Make sure the slider is in sync with the other panels.
public void updateChooser() {
	//Color c = getColorSelectionModel().getSelectedColor();
	//scale.setValue(toGray(c));
}



// Pick a name for our tab in the chooser
public String getDisplayName() {
	return "Transparency";
}

// No need for an icon.
public Icon getSmallDisplayIcon() {
return null;
}

public Icon getLargeDisplayIcon() {
return null;
}*/

// And lastly, update the selection model as our slider changes.
/*public void stateChanged(ChangeEvent ce) {
	//getColorSelectionModel().setSelectedColor(grays[scale.getValue()]);
	
	value = (100 - (int) Math.round(scale.getValue() / 2.55));
	percentField.setText(""+ (100 - (int) Math.round(scale.getValue() / 2.55)));
}*/

	
/*}*/
