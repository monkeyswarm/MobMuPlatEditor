package com.iglesiaintermedia.MobMuPlatEditor;

import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

import javax.swing.event.DocumentEvent;
import javax.swing.event.DocumentListener;



public class JTextFieldDirty extends javax.swing.JTextField {
	public boolean dirty;
	//when lose focus, check if dirty
	public JTextFieldDirty(){
		super();
		getDocument ().addDocumentListener (new DocumentListener(){ //type into it
            public void changedUpdate (DocumentEvent e) 
            { 
                dirty = true; 
            }

            public void insertUpdate (DocumentEvent e) 
            { 
                dirty = true; 
            }

            public void removeUpdate (DocumentEvent e) 
            { 
                dirty = true; 
            }
        });
		this.addActionListener(new ActionListener() {//enter
	        public void actionPerformed(ActionEvent e) {
	        	dirty=false;
	        }
		});
	}

}
