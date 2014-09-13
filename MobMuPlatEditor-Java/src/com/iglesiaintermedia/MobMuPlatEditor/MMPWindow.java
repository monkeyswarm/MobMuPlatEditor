package com.iglesiaintermedia.MobMuPlatEditor;
import com.iglesiaintermedia.MobMuPlatEditor.controls.*;

import java.awt.EventQueue;

import javax.swing.JFrame;
import javax.swing.UIManager.LookAndFeelInfo;
import javax.swing.event.*;
import javax.swing.text.DefaultCaret;
import javax.swing.text.Document;

import java.awt.BorderLayout;
import java.awt.Color;
import java.awt.Component;
import java.awt.FlowLayout;
import java.awt.GraphicsEnvironment;
import java.awt.Rectangle;
import java.awt.Dimension;
import java.awt.Toolkit;
import java.awt.event.*;

import javax.swing.AbstractAction;
import javax.swing.BoxLayout;
import javax.swing.DefaultListCellRenderer;
import javax.swing.JComponent;
import javax.swing.JDialog;
import javax.swing.JFileChooser;
import javax.swing.JList;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JMenuBar;
import javax.swing.JMenu;
import javax.swing.JMenuItem;
import javax.swing.JTabbedPane;
import javax.swing.JComboBox;
import javax.swing.DefaultComboBoxModel;
import javax.swing.JButton;
import javax.swing.JTextField;
import javax.swing.KeyStroke;
import javax.swing.ListCellRenderer;
import javax.swing.UIManager;
import javax.swing.filechooser.FileNameExtensionFilter;

import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.FocusEvent;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.ListIterator;
import java.util.Map;
import java.util.prefs.Preferences;

import javax.swing.JLabel;

import java.awt.Font;

import javax.swing.JTextArea;
import javax.swing.JSlider;
import javax.swing.SwingConstants;
import javax.swing.JCheckBox;

public class MMPWindow implements ChangeListener, ActionListener, FocusListener, DocumentListener{
	static final int CANVAS_LEFT  = 250;
	static final int CANVAS_TOP = 8;
	static int openWindows;
	static final boolean forceNimbus=false;
	
	JFrame frame;
	private JScrollPane scrollPane;
	private JPanel scrollContentPanel;
	
	MMPController controller;
	
	private JTabbedPane tabbedPane;
	private static JFileChooser fc;
	private static JFileChooser pdfc;
	
	public CanvasPanel canvasPanel;
	public JPanel canvasOuterPanel;
	JLabel pageIndexLabel;
	JLabel controlGuideLabel;
	
	JMenuBar menuBar;
	JComboBox docCanvasTypeMenu;
	JComboBox docOrientationMenu;
	 JTextFieldDirty docPageCountField;
	 JTextFieldDirty docStartPageField;
	 JTextFieldDirty portTextField;
	 JTextFieldDirty docFileTextField;
	ColorWell docBGColorWell;
	
	ColorWell propColorWell; 
	ColorWell propHighlightColorWell; 
	JTextFieldDirty propAddressTextField;
	
	JPanel propVarPanel;
	JPanel propVarSliderPanel;
	JPanel propVarKnobPanel;
	JPanel propVarLabelPanel;
	JPanel propVarGridPanel;
	JPanel propVarPanelPanel;
	JPanel propVarMultiSliderPanel;
	JPanel propVarTogglePanel;
	JPanel propVarMenuPanel;
	JPanel propVarTablePanel;
	JTextFieldDirty propVarSliderRangeTextField;
	JComboBox propVarSliderOrientationBox;
	JTextFieldDirty propVarKnobRangeTextField;
	ColorWell propVarKnobIndicatorColorWell;
	
	JTextArea propLabelTextField;
	JTextFieldDirty propLabelSizeTextField;
	JTabbedPane propLabelTabbedPane;
	JPanel propLabeliOSPanel;
	JPanel propLabelAndroidPanel;
	JComboBox propLabelFontBox;
	JComboBox propLabelFontTypeBox;
	JComboBox propLabelAndroidFontTypeBox;
	JTextFieldDirty propToggleThicknessTextField;
	
	JTextFieldDirty propGridDimXTextField;
	JTextFieldDirty propGridDimYTextField;
	JTextFieldDirty propGridBorderThicknessTextField;
	JTextFieldDirty propGridCellPaddingTextField;
	JComboBox propGridModeBox;
	JTextFieldDirty propPanelFileTextField;
	JCheckBox propPanelShouldPassTouchesCheckBox;
	JTextFieldDirty propMultiCountTextField;
	JTextFieldDirty propMenuTitleTextField;
	
	JComboBox propTableModeBox;
	ColorWell propTableSelectionColorWell;
	
	JTextArea consoleTextArea;
	
	JSlider fakeXSlider, fakeYSlider;
	
	static ArrayList<MMPControl> copyArrayList;
	String[] systemFontList;
	//public JPanel getCanvasPanel(){return canvasPanel;}
	
	JTextField snapToGridXTextField;
	JTextField snapToGridYTextField;
	JDialog layoutDialog;
	
	/**
	 * Launch the application.
	 */
	public static void main(String[] args) {
		EventQueue.invokeLater(new Runnable() {
			public void run() {
				try {
					
					//for (LookAndFeelInfo info : UIManager.getInstalledLookAndFeels()) System.out.print("\nlaf: "+info.getClassName()+" "+info.getName());
					String systemLAF = UIManager.getSystemLookAndFeelClassName();
					//System.out.print("\nsystem laf:"+UIManager.getSystemLookAndFeelClassName());
					if(systemLAF.equals("com.apple.laf.AquaLookAndFeel") && forceNimbus==false){}
					else{
						for (LookAndFeelInfo info : UIManager.getInstalledLookAndFeels()) {
					
			            if ("Nimbus".equals(info.getName())) {
			                UIManager.setLookAndFeel(info.getClassName());
			                break;
			            }
			        	//System.out.print("\nlaf: "+info.getClassName()+" "+info.getName());
						}
					}
					
					MMPWindow window = new MMPWindow();
					window.frame.setVisible(true);
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
		});
	}

	/**
	 * Create the application.
	 */
	public MMPWindow() {
		initialize();
	}

	/**
	 * Initialize the contents of the frame.
	 */
	private void initialize() {
		
		//ugly - shutdown hook on mac command-q
		if (System.getProperty("os.name").startsWith("Mac OS")) {
			Runnable runner = new Runnable() {
				public void run() {
					exitHelper();
				}
			};

			Runtime.getRuntime().addShutdownHook(new Thread(runner, "Window Prefs Hook"));
		}
		
		 systemFontList = GraphicsEnvironment.getLocalGraphicsEnvironment().getAvailableFontFamilyNames();
		
		//made these static so that it remembers folder across different windows
		if(fc==null){
			fc = new JFileChooser();
		
			fc.setAcceptAllFileFilterUsed(false);
			fc.setFileFilter(new FileNameExtensionFilter("MobMuPlat interface (.mmp)", "mmp"));
		}
		if(pdfc==null){
			pdfc = new JFileChooser();
			pdfc.setAcceptAllFileFilterUsed(false);
			pdfc.setFileFilter(new FileNameExtensionFilter("Pure Data patches (.pd)", "pd"));
		}
		
		 controller = new MMPController();
		controller.setIsEditing(true);
		controller.windowDelegate=this;
		
		
		if(copyArrayList==null)copyArrayList = new ArrayList<MMPControl>();
		
		
		frame = new JFrame();
		frame.setBounds(100, 100, 620, 552+22);
		frame.setResizable(false);
		frame.setTitle("Untitled.mmp");
		controller.filename = "Untitled.mmp";
		//frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		//frame.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
		frame.setDefaultCloseOperation(JFrame.DO_NOTHING_ON_CLOSE);
		frame.getContentPane().setLayout(null);
		openWindows++;
		/*frame.addWindowListener(new java.awt.event.WindowAdapter() {
		    public void windowClosing(java.awt.event.WindowEvent e) {
		    	System.out.print("\nWINDOW CLOSING EVENT");
		    	closeWindowHelper();
		    }
		});*/

		
		scrollPane = new JScrollPane();
		scrollPane.setBounds(0, 22, 620, 552);
		scrollPane.setHorizontalScrollBarPolicy(JScrollPane.HORIZONTAL_SCROLLBAR_NEVER);
		frame.getContentPane().add(scrollPane);
		
		
		
		
		scrollContentPanel = new JPanel();
		scrollContentPanel.setBounds(0, 0, 620, 552);
		scrollContentPanel.setPreferredSize(new Dimension(620, 552));
		scrollPane.setViewportView(scrollContentPanel);
		scrollContentPanel.setLayout(null);
		
		tabbedPane = new JTabbedPane(JTabbedPane.TOP);
		scrollContentPanel.add(tabbedPane);
		tabbedPane.setLocation(4, 10);
		tabbedPane.setSize(238, 374);
		tabbedPane.addChangeListener(this);
	       
		canvasOuterPanel = new JPanel();
		canvasOuterPanel.setSize(320, 480);
		canvasOuterPanel.setLocation(250, 10);
		canvasOuterPanel.setLayout(null);
		scrollContentPanel.add(canvasOuterPanel);
		
		canvasPanel = new CanvasPanel();
		canvasPanel.setSize(320, 480);
		canvasPanel.setLocation(0, 0);
		//canvasPanel.setFocusable(true);
		//canvasPanel.setPreferredSize(new Dimension(300, 1000));
		canvasPanel.editingDelegate=controller;
		canvasPanel.setLayout(null);
		canvasOuterPanel.add(canvasPanel);
		
		//key hits
		scrollPane.getInputMap(JComponent.WHEN_ANCESTOR_OF_FOCUSED_COMPONENT).put(KeyStroke.getKeyStroke("BACK_SPACE"),"delete");
		scrollPane.getActionMap(). put("delete",new MMPKeyAction("delete"));
		
		/*scrollPane.getInputMap(JComponent.WHEN_ANCESTOR_OF_FOCUSED_COMPONENT).put(KeyStroke.getKeyStroke(KeyEvent.VK_C, Toolkit.getDefaultToolkit().getMenuShortcutKeyMask()),"copy");
		scrollPane.getActionMap(). put("copy",new MMPKeyAction("copy"));
		*/
		
		//DOC Panel
		JPanel docPanel = new JPanel();
		//docPanel.setBackground(Color.LIGHT_GRAY);
		tabbedPane.addTab("Doc", null, docPanel, null);
		docPanel.setLayout(null);
		
		JLabel lblNewLabel = new JLabel("Screen Size");
		lblNewLabel.setBounds(6, 10, 87, 16);
		docPanel.add(lblNewLabel);
		
		docCanvasTypeMenu = new JComboBox();
		docCanvasTypeMenu.setModel(new DefaultComboBoxModel(new String[] {"iPhone - 3.5\"", "iPhone - 4\"", "iPad", "Android 7\""}));
		docCanvasTypeMenu.setBounds(97, 6, 122, 26);
		docCanvasTypeMenu.setActionCommand("canvasType");
		docCanvasTypeMenu.addActionListener(this);
		docPanel.add(docCanvasTypeMenu);
		
		JLabel lblNewLabel_1 = new JLabel("Orientation");
		lblNewLabel_1.setBounds(6, 36, 101, 16);
		docPanel.add(lblNewLabel_1);
		
		docOrientationMenu = new JComboBox();
		docOrientationMenu.setModel(new DefaultComboBoxModel(new String[] {"Portrait", "Landscape"}));
		docOrientationMenu.setBounds(119, 32, 100, 26);
		docOrientationMenu.setActionCommand("orientation");
		docOrientationMenu.addActionListener(this);
		docPanel.add(docOrientationMenu);
			
		JLabel lblBackgroundColor = new JLabel("Background Color");
		lblBackgroundColor.setBounds(6, 68, 137, 16);
		docPanel.add(lblBackgroundColor);
		
		docBGColorWell = new ColorWell();
		docBGColorWell.setBounds(155, 60, 56, 30);
		docBGColorWell.setColor(canvasPanel.bgColor);
		docPanel.add(docBGColorWell);
		docBGColorWell.delegate=this;
		
		JLabel lblPageCount = new JLabel("Page Count");
		lblPageCount.setBounds(6, 94, 137, 16);
		docPanel.add(lblPageCount);
		
		docPageCountField = new JTextFieldDirty();
		docPageCountField.setBounds(155, 93, 54, 28);
		docPageCountField.setColumns(2);
		docPageCountField.setText(""+controller.documentModel.pageCount);
		docPageCountField.addFocusListener(this);
		docPageCountField.setActionCommand("pageCount");
		docPageCountField.addActionListener(this);
		docPanel.add(docPageCountField);
		
		JLabel label_2 = new JLabel("Initial Page Index");
		label_2.setBounds(6, 122, 137, 16);
		docPanel.add(label_2);
		
		docStartPageField = new JTextFieldDirty();
		docStartPageField.setColumns(2);
		docStartPageField.setActionCommand("startPage");
		docStartPageField.setText(""+(controller.documentModel.startPageIndex+1));
		docStartPageField.addFocusListener(this);
		docStartPageField.addActionListener(this);
		docStartPageField.setBounds(155, 124, 54, 28);
		docPanel.add(docStartPageField);
		
		JLabel label_3 = new JLabel("Send/Receive Port");
		label_3.setBounds(6, 157, 137, 16);
		docPanel.add(label_3);
		
		portTextField = new JTextFieldDirty();
		portTextField.setColumns(2);
		portTextField.setActionCommand("port");
		portTextField.setText(""+controller.documentModel.port);
		portTextField.addFocusListener(this);
		portTextField.addActionListener(this);
		portTextField.setBounds(155, 151, 54, 28);
		docPanel.add(portTextField);
		
		JLabel label_4 = new JLabel("Main Pd File");
		label_4.setBounds(6, 209, 137, 16);
		docPanel.add(label_4);
		
		docFileTextField = new JTextFieldDirty();
		docFileTextField.setColumns(2);
		docFileTextField.addFocusListener(this);
		docFileTextField.setActionCommand("pdFile");
		docFileTextField.addActionListener(this);
		docFileTextField.setBounds(6, 237, 205, 28);
		docPanel.add(docFileTextField);
		
		
		
		JButton choosePDFileButton = new JButton("Choose...");
		choosePDFileButton.setBounds(94, 204, 117, 29);
		docPanel.add(choosePDFileButton);
		choosePDFileButton.addActionListener(this);
		choosePDFileButton.setActionCommand("pdFileButton");
		
		JLabel pdInfoLabel = new JLabel("<html>Open this file, and \"PdWrapper.pd\" in Pd. <br>This application will then send/receive <br>messages to Pd when in \"Lock\" mode.");
		pdInfoLabel.setFont(new Font("Lucida Grande", Font.PLAIN, 10));
		pdInfoLabel.setBounds(6, 260, 205, 57);
		docPanel.add(pdInfoLabel);

		
		
		//ADD
		JPanel addPanel = new JPanel();
		//addPanel.setBackground(Color.ORANGE);
		tabbedPane.addTab("Add", null, addPanel, null);
		addPanel.setLayout(null);
		
		
		
		JButton addSliderButton = new JButton("Slider");
		addSliderButton.setActionCommand("addSlider");
		addSliderButton.addActionListener(this);
		addSliderButton.setBounds(5, 38, 68, 55);
		addPanel.add(addSliderButton);
		
		JButton addKnobButton = new JButton("Knob");
		addKnobButton.setBounds(70, 38, 68, 55);
		addPanel.add(addKnobButton);
		addKnobButton.addActionListener(this);
		addKnobButton.setActionCommand("addKnob");
		
		JButton addXYSliderButton = new JButton();
		 JLabel addXYSliderButtonLabel = new JLabel("<html>XY<br>Slider</html>");
		 addXYSliderButton.add(BorderLayout.CENTER,addXYSliderButtonLabel);
		addXYSliderButton.setActionCommand("addXYSlider");
		addXYSliderButton.addActionListener(this);
		addXYSliderButton.setBounds(135, 38, 68, 55);
		addPanel.add(addXYSliderButton);
		
		JButton addLabelButton = new JButton("Label");
		addLabelButton.setActionCommand("addLabel");
		addLabelButton.addActionListener(this);
		addLabelButton.setBounds(5, 89, 68, 55);
		addPanel.add(addLabelButton);
		
		JButton addButtonButton = new JButton("Button");
		addButtonButton.setActionCommand("addButton");
		addButtonButton.addActionListener(this);
		addButtonButton.setBounds(70, 89, 68, 55);
		addPanel.add(addButtonButton);
		
		JButton addToggleButton = new JButton("Toggle");
		addToggleButton.setActionCommand("addToggle");
		addToggleButton.addActionListener(this);
		addToggleButton.setBounds(135, 89, 68, 55);
		addPanel.add(addToggleButton);
		
		JButton addGridButton = new JButton("Grid");
		addGridButton.setActionCommand("addGrid");
		addGridButton.addActionListener(this);
		addGridButton.setBounds(5, 140, 68, 55);
		addPanel.add(addGridButton);
		
		JButton addPanelButton = new JButton("Panel");
		addPanelButton.setActionCommand("addPanel");
		addPanelButton.addActionListener(this);
		addPanelButton.setBounds(70, 140, 68, 55);
		addPanel.add(addPanelButton);
		
		JButton addMultisliderButton = new JButton();
		addMultisliderButton.setLayout(new BorderLayout());
		   JLabel addMultisliderButtonLabel = new JLabel("<html>Multi<br>slider</html>");
		   addMultisliderButton.add(BorderLayout.CENTER,addMultisliderButtonLabel);
		addMultisliderButton.setActionCommand("addMultiSlider");
		addMultisliderButton.addActionListener(this);
		addMultisliderButton.setBounds(135, 140, 68, 55);
		addPanel.add(addMultisliderButton);
		
		JButton addLCDButton = new JButton("LCD");
		addLCDButton.addActionListener(this);
		addLCDButton.setActionCommand("addLCD");
		addLCDButton.setBounds(5, 192, 68, 55);
		addPanel.add(addLCDButton);
		
		JButton addMultiTouchButton = new JButton();
		addMultiTouchButton.setLayout(new BorderLayout());
		   JLabel addMultiTouchButtonLabel = new JLabel("<html>Multi<br>touch</html>");
		   addMultiTouchButton.add(BorderLayout.CENTER,addMultiTouchButtonLabel);
		addMultiTouchButton.setActionCommand("addMultiTouch");
		addMultiTouchButton.addActionListener(this);
		addMultiTouchButton.setBounds(70, 192, 68, 55);
		addPanel.add(addMultiTouchButton);
		
		JButton addMenuButton = new JButton("Menu");
		addMenuButton.addActionListener(this);
		addMenuButton.setActionCommand("addMenu");
		addMenuButton.setBounds(135, 192, 68, 55);
		addPanel.add(addMenuButton);
		
		JButton addTableButton = new JButton("Table");
		addTableButton.addActionListener(this);
		addTableButton.setActionCommand("addTable");
		addTableButton.setBounds(5, 244, 68, 55);
		addPanel.add(addTableButton);
		
		//PROP
		JPanel propPanel = new JPanel();
		//propPanel.setBackground(Color.ORANGE);
		tabbedPane.addTab("Prop", null, propPanel, null);
		propPanel.setLayout(null);
		
		 propColorWell = new ColorWell();
		propColorWell.setBounds(155, 9, 56, 30);
		propColorWell.setColor(Color.BLUE);
		propPanel.add(propColorWell);
		propColorWell.delegate=this;
		propColorWell.hasAlpha=true;
		
		 propHighlightColorWell = new ColorWell();
		 propHighlightColorWell.setBounds(155, 42, 56, 30);
		 propHighlightColorWell.setColor(Color.RED);
		 propHighlightColorWell.delegate=this;
		 propHighlightColorWell.hasAlpha=true;
		propPanel.add(propHighlightColorWell);
		
		propAddressTextField = new JTextFieldDirty();
		propAddressTextField.setColumns(2);
		propAddressTextField.addFocusListener(this);
		propAddressTextField.setActionCommand("propAddressChanged");
		propAddressTextField.addActionListener(this);
		propAddressTextField.setBounds(89, 74, 120, 28);
		propPanel.add(propAddressTextField);
		
		JLabel lblNewLabel_2 = new JLabel("Address");
		lblNewLabel_2.setBounds(17, 80, 61, 16);
		propPanel.add(lblNewLabel_2);
		
		JLabel lblNewLabel_3 = new JLabel("Color");
		lblNewLabel_3.setBounds(17, 16, 61, 16);
		propPanel.add(lblNewLabel_3);
		
		JLabel lblNewLabel_4 = new JLabel("Highlight Color");
		lblNewLabel_4.setBounds(17, 49, 103, 16);
		propPanel.add(lblNewLabel_4);
		
		propVarPanel = new JPanel();
		propVarPanel.setBounds(0, 110, 217, 162);
		propVarPanel.setLayout(null);
		propPanel.add(propVarPanel);
		
		//PROPVAR - GRID
				propVarGridPanel = new JPanel();
				propVarGridPanel.setBounds(0, 0, 217, 162);
				propVarGridPanel.setLayout(null);
				propVarGridPanel.setVisible(false);
				propVarPanel.add(propVarGridPanel);
				
				JLabel gridDimensionLabel = new JLabel("Grid Dimension");
				gridDimensionLabel.setBounds(6, 6, 107, 16);
				propVarGridPanel.add(gridDimensionLabel);
				
				propGridDimXTextField = new JTextFieldDirty();
				propGridDimXTextField.setBounds(106, 0, 40, 28);
				propGridDimXTextField.addFocusListener(this);
				propVarGridPanel.add(propGridDimXTextField);
				propGridDimXTextField.setColumns(10);
				propGridDimXTextField.setActionCommand("propVarGridDimXChanged");
				propGridDimXTextField.addActionListener(this);
				
				propGridDimYTextField = new JTextFieldDirty();
				propGridDimYTextField.setColumns(10);
				propGridDimYTextField.setBounds(165, 0, 40, 28);
				propGridDimYTextField.addFocusListener(this);
				propVarGridPanel.add(propGridDimYTextField);
				propGridDimYTextField.setActionCommand("propVarGridDimYChanged");
				propGridDimYTextField.addActionListener(this);
				
				JLabel lblBy = new JLabel("by");
				lblBy.setBounds(147, 6, 24, 16);
				propVarGridPanel.add(lblBy);
				
				propGridBorderThicknessTextField = new JTextFieldDirty();
				propGridBorderThicknessTextField.setColumns(10);
				propGridBorderThicknessTextField.setBounds(165, 34, 40, 28);
				propGridBorderThicknessTextField.addFocusListener(this);
				propVarGridPanel.add(propGridBorderThicknessTextField);
				propGridBorderThicknessTextField.setActionCommand("propVarGridBorderThicknessChanged");
				propGridBorderThicknessTextField.addActionListener(this);
				
				JLabel lblCellBorderThickness = new JLabel("Cell Border Thickness");
				lblCellBorderThickness.setBounds(31, 40, 140, 16);
				propVarGridPanel.add(lblCellBorderThickness);
				
				
				JLabel lblCellPadding = new JLabel("Cell Padding");
				lblCellPadding.setBounds(83, 72, 88, 16);
				propVarGridPanel.add(lblCellPadding);
				
				propGridCellPaddingTextField = new JTextFieldDirty();
				propGridCellPaddingTextField.setColumns(10);
				propGridCellPaddingTextField.setBounds(165, 66, 40, 28);
				propVarGridPanel.add(propGridCellPaddingTextField);
				propGridCellPaddingTextField.addFocusListener(this);
				propGridCellPaddingTextField.setActionCommand("propVarGridCellPaddingChanged");
				propGridCellPaddingTextField.addActionListener(this);
				
				propGridModeBox = new JComboBox();
				propGridModeBox.setBounds(93, 100, 112, 27);
				propGridModeBox.setModel(new DefaultComboBoxModel(new String[] {"Toggle", "Momentary", "Hybrid"}));
				propGridModeBox.setActionCommand("propGridModeChanged");
				propGridModeBox.addActionListener(this);
				propVarGridPanel.add(propGridModeBox);
				
				JLabel lblNewLabel_10 = new JLabel("Touch Mode:");
				lblNewLabel_10.setBounds(6, 104, 88, 16);
				propVarGridPanel.add(lblNewLabel_10);
				
		
		//propVarPanel - SLIDER
		propVarSliderPanel = new JPanel();
		propVarSliderPanel.setBounds(0, 0, 217, 162);
		//propVarSliderPanel.setBackground(Color.BLUE);
		propVarSliderPanel.setLayout(null);
		propVarSliderPanel.setVisible(false);
		
		
		propVarPanel.add(propVarSliderPanel);
		
		propVarSliderRangeTextField = new JTextFieldDirty();
		propVarSliderRangeTextField.setColumns(2);
		propVarSliderRangeTextField.addFocusListener(this);
		propVarSliderRangeTextField.setActionCommand("propVarSliderRangeChanged");
		propVarSliderRangeTextField.addActionListener(this);
		propVarSliderRangeTextField.setBounds(130, 51, 81, 28);
		propVarSliderPanel.add(propVarSliderRangeTextField);
		
		JLabel lblSliderOrientation = new JLabel("Slider Orientation");
		lblSliderOrientation.setBounds(12, 0, 132, 16);
		propVarSliderPanel.add(lblSliderOrientation);
		
		propVarSliderOrientationBox = new JComboBox();
		propVarSliderOrientationBox.setModel(new DefaultComboBoxModel(new String[] {"Vertical", "Horizontal"}));
		propVarSliderOrientationBox.setBounds(66, 22, 145, 27);
		propVarSliderOrientationBox.setActionCommand("propVarSliderOrientationChanged");
		propVarSliderOrientationBox.addActionListener(this);
		propVarSliderPanel.add(propVarSliderOrientationBox);
		
		JLabel lblNewLabel_7 = new JLabel("Slider Range\n");
		lblNewLabel_7.setBounds(16, 57, 102, 16);
		propVarSliderPanel.add(lblNewLabel_7);
		
		JLabel lblARangeOf = new JLabel("<html>A range of 2 sends 0-1 float. <br>A range of >2 sends integers.</html>");
		lblARangeOf.setFont(new Font("Lucida Grande", Font.PLAIN, 11));
		lblARangeOf.setBounds(26, 85, 176, 31);
		propVarSliderPanel.add(lblARangeOf);
		
		//propVarPanel - KNOB
		propVarKnobPanel = new JPanel();
		propVarKnobPanel.setBounds(0, 0, 217, 162);
		//propVarSliderPanel.setBackground(Color.BLUE);
		propVarKnobPanel.setVisible(false);
		propVarKnobPanel.setLayout(null);
		propVarPanel.add(propVarKnobPanel);
		
		propVarKnobRangeTextField = new JTextFieldDirty();
		propVarKnobRangeTextField.setColumns(2);
		propVarKnobRangeTextField.addFocusListener(this);
		propVarKnobRangeTextField.setActionCommand("propVarKnobRangeChanged");
		propVarKnobRangeTextField.addActionListener(this);
		propVarKnobRangeTextField.setBounds(130, 1, 81, 28);
		propVarKnobPanel.add(propVarKnobRangeTextField);
		
		JLabel propVarKnobRangeLabel = new JLabel("Knob Range\n");
		propVarKnobRangeLabel.setBounds(16, 7, 102, 16);
		propVarKnobPanel.add(propVarKnobRangeLabel);
		
		JLabel propVarKnobRangeInfoLabel = new JLabel("<html>A range of 2 sends 0-1 float. <br>A range of >2 sends integers.</html>");
		propVarKnobRangeInfoLabel.setFont(new Font("Lucida Grande", Font.PLAIN, 11));
		propVarKnobRangeInfoLabel.setBounds(16, 35, 176, 31);
		propVarKnobPanel.add(propVarKnobRangeInfoLabel);
		
		JLabel propVarKnobIndicatorLabel = new JLabel("Indicator Color");
		propVarKnobIndicatorLabel.setBounds(16, 86, 102, 16);
		propVarKnobPanel.add(propVarKnobIndicatorLabel);
		
		propVarKnobIndicatorColorWell = new ColorWell();
		propVarKnobIndicatorColorWell.setBounds(130, 80, 56, 30);
		propVarKnobPanel.add(propVarKnobIndicatorColorWell);
		propVarKnobIndicatorColorWell.delegate=this;
		propVarKnobIndicatorColorWell.hasAlpha=true;
	
		//PROPVAR LABEL
		propVarLabelPanel = new JPanel();
		propVarLabelPanel.setBounds(0, 0, 217, 162);
		propVarLabelPanel.setVisible(false);
		propVarLabelPanel.setLayout(null);
		propVarPanel.add(propVarLabelPanel);
		
		
		propLabelTextField = new JTextArea();
		//propLabelTextField.setBounds(6, 6, 205, 36);
		//doesn't need documentlistener added manually...?
		JScrollPane propLabelScrollPane = new JScrollPane(propLabelTextField);
		propLabelScrollPane.setBounds(6,0,205,40);
		//propLabelScrollPane.setPreferredSize(new Dimension(205,36));
		propVarLabelPanel.add(propLabelScrollPane);
		
		propLabelSizeTextField = new JTextFieldDirty();
		propLabelSizeTextField.setBounds(149, 41, 62, 28);
		propLabelSizeTextField.addFocusListener(this);
		propLabelSizeTextField.setActionCommand("propVarLabelSizeChanged");
		propLabelSizeTextField.addActionListener(this);
		propVarLabelPanel.add(propLabelSizeTextField);
		propLabelSizeTextField.setColumns(10);
		
		//
		propLabelTabbedPane = new JTabbedPane(JTabbedPane.TOP);
		propVarLabelPanel.add(propLabelTabbedPane);
		propLabelTabbedPane.setBounds(0,40+24,220,104);
		propLabelTabbedPane.addChangeListener(this);
		
		propLabeliOSPanel = new JPanel();
		propLabelTabbedPane.addTab("iOS", null, propLabeliOSPanel, null);
		propLabeliOSPanel.setLayout(null);
		
		propLabelFontBox = new JComboBox();
		propLabelFontBox.setBounds(70, 0, 126, 27);
		propLabelFontBox.setActionCommand("font");
		propLabelFontBox.addActionListener(this);
		//propVarLabelPanel.add(propLabelFontBox);
		propLabeliOSPanel.add(propLabelFontBox);
		
		 propLabelFontTypeBox = new JComboBox();
		propLabelFontTypeBox.setBounds(70, 27, 126, 27);
		propLabelFontTypeBox.setActionCommand("fontType");
		propLabelFontTypeBox.addActionListener(this);
		//propVarLabelPanel.add(propLabelFontTypeBox);
		propLabeliOSPanel.add(propLabelFontTypeBox);
		
		
		JLabel textSizeLabel = new JLabel("Label Text Size");
		textSizeLabel.setBounds(16, 48, 121, 15);
		propVarLabelPanel.add(textSizeLabel);
		
		JLabel lblFontFamily = new JLabel("Label Font");
		lblFontFamily.setBounds(3, 3, 78, 15);
		propLabeliOSPanel.add(lblFontFamily);
		
		JLabel lblFontType = new JLabel("Font Type");
		lblFontType.setBounds(3, 30, 78, 15);
		propLabeliOSPanel.add(lblFontType);
		
		
		
		//android panel
		propLabelAndroidPanel = new JPanel();
		propLabelTabbedPane.addTab("Android", null, propLabelAndroidPanel, null);
		propLabelAndroidPanel.setLayout(null);
		
		JLabel lblFontType2 = new JLabel("Font Type");
		lblFontType2.setBounds(3, 3, 78, 15);
		propLabelAndroidPanel.add(lblFontType2);
		
		propLabelAndroidFontTypeBox = new JComboBox();
		propLabelAndroidFontTypeBox.setBounds(70, 0, 126, 27);
		propLabelAndroidFontTypeBox.setActionCommand("androidFontType");
		propLabelAndroidFontTypeBox.addActionListener(this);
		//propVarLabelPanel.add(propLabelFontTypeBox);
		propLabelAndroidPanel.add(propLabelAndroidFontTypeBox);
		
		fillFontPop();
		
		
		//PROPVAR - PANEL
		propVarPanelPanel = new JPanel();
		propVarPanelPanel.setBounds(0, 0, 217, 162);
		propVarPanelPanel.setLayout(null);
		propVarPanelPanel.setVisible(false);
		propVarPanel.add(propVarPanelPanel);
				
		JLabel imageLabel = new JLabel("Image");
		imageLabel.setBounds(21, 11, 61, 16);
		propVarPanelPanel.add(imageLabel);
				
		JButton propPanelChooseButton = new JButton("Choose...");
		propPanelChooseButton.setBounds(94, 6, 117, 29);
		propVarPanelPanel.add(propPanelChooseButton);
				
		propPanelFileTextField = new JTextFieldDirty();
		propPanelFileTextField.setBounds(15, 35, 190, 28);
		propVarPanelPanel.add(propPanelFileTextField);
		propPanelFileTextField.addFocusListener(this);
		propPanelFileTextField.setActionCommand("propVarPanelFileChanged");
		propPanelFileTextField.addActionListener(this);
		propPanelFileTextField.setColumns(10);
				
		JLabel lblNewLabel_8 = new JLabel("<html>Type in just the file name for a relative<br> path (same folder as saved document),<br> or hit choose to specify an absolute path.");
		lblNewLabel_8.setFont(new Font("Lucida Grande", Font.PLAIN, 10));
		lblNewLabel_8.setBounds(5, 60, 205, 45);
		propVarPanelPanel.add(lblNewLabel_8);
				
		propPanelShouldPassTouchesCheckBox = new JCheckBox("Allow touches to scroll");
		propPanelShouldPassTouchesCheckBox.setFont(new Font("Lucida Grande", Font.PLAIN, 12));
		propPanelShouldPassTouchesCheckBox.setBounds(15, 103, 180, 23);
		propPanelShouldPassTouchesCheckBox.setActionCommand("panelShouldPassTouchesChanged");
		propPanelShouldPassTouchesCheckBox.addActionListener(this);
		propVarPanelPanel.add(propPanelShouldPassTouchesCheckBox);
		
		//PROPVAR - MULTISLIDER
		propVarMultiSliderPanel = new JPanel();
		propVarMultiSliderPanel.setBounds(0, 0, 217, 162);
		propVarMultiSliderPanel.setLayout(null);
		propVarMultiSliderPanel.setVisible(false);
		propVarPanel.add(propVarMultiSliderPanel);
		
		JLabel lblNumberOfSliders = new JLabel("Number of Sliders");
		lblNumberOfSliders.setBounds(18, 6, 125, 16);
		propVarMultiSliderPanel.add(lblNumberOfSliders);
		
		propMultiCountTextField = new JTextFieldDirty();
		propMultiCountTextField.setBounds(144, 0, 67, 28);
		propVarMultiSliderPanel.add(propMultiCountTextField);
		propMultiCountTextField.setColumns(10);
		propMultiCountTextField.addFocusListener(this);
		propMultiCountTextField.setActionCommand("propVarMultiCountChanged");
		propMultiCountTextField.addActionListener(this);
		
		//PROPVAR - Toggle
		propVarTogglePanel = new JPanel();
		propVarTogglePanel.setBounds(0, 0, 217, 162);
		propVarTogglePanel.setLayout(null);
		propVarTogglePanel.setVisible(false);
		propVarPanel.add(propVarTogglePanel);
		
		JLabel toggleBorderLabel = new JLabel("Border Thickness");
		toggleBorderLabel.setBounds(18, 6, 125, 16);
		propVarTogglePanel.add(toggleBorderLabel);
		
		propToggleThicknessTextField = new JTextFieldDirty();
		propToggleThicknessTextField.setBounds(144, 0, 67, 28);
		propToggleThicknessTextField.addFocusListener(this);
		propVarTogglePanel.add(propToggleThicknessTextField);
		propToggleThicknessTextField.setColumns(10);
		propToggleThicknessTextField.setActionCommand("propVarToggleBorderThicknessChanged");
		propToggleThicknessTextField.addActionListener(this);
		
		//PROPVAR - Menu
		propVarMenuPanel = new JPanel();
		propVarMenuPanel.setBounds(0, 0, 217, 162);
		propVarMenuPanel.setLayout(null);
		propVarMenuPanel.setVisible(false);
		propVarPanel.add(propVarMenuPanel);
				
		JLabel titleLabel = new JLabel("Menu Title");
		titleLabel.setBounds(21, 11, 200, 16);
		propVarMenuPanel.add(titleLabel);
		
		propMenuTitleTextField = new JTextFieldDirty();
		propMenuTitleTextField.setBounds(15, 39, 190, 28);
		propVarMenuPanel.add(propMenuTitleTextField);
		propMenuTitleTextField.addFocusListener(this);
		propMenuTitleTextField.addActionListener(this);
		propMenuTitleTextField.setActionCommand("propVarMenuTitleChanged");
		propMenuTitleTextField.setColumns(10);
		
		JLabel lblNewLabel_9 = new JLabel("(Menu items are set in the PD patch)");
		lblNewLabel_9.setFont(new Font("Lucida Grande", Font.PLAIN, 11));
		lblNewLabel_9.setBounds(15, 72, 196, 54);
		propVarMenuPanel.add(lblNewLabel_9);
		
		//PROPVAR - Table
		propVarTablePanel = new JPanel();
		propVarTablePanel.setBounds(0, 0, 217, 162);
		propVarTablePanel.setLayout(null);
		propVarTablePanel.setVisible(false);
		propVarPanel.add(propVarTablePanel);
		
		JLabel propVarTableInfoLabel = new JLabel("<html>The address corresponds to <br>\na PD table of the same name <br>\n(including slash).</html>");
		propVarTableInfoLabel.setHorizontalAlignment(SwingConstants.CENTER);
		propVarTableInfoLabel.setFont(new Font("Lucida Grande", Font.PLAIN, 11));
		propVarTableInfoLabel.setBounds(16, 6, 176, 43);
		propVarTablePanel.add(propVarTableInfoLabel);
		
		propTableModeBox = new JComboBox();
		propTableModeBox.setModel(new DefaultComboBoxModel(new String[] {"Select", "Draw"}));
		propTableModeBox.setBounds(109, 61, 102, 27);
		propTableModeBox.setActionCommand("propTableModeChanged");
		propTableModeBox.addActionListener(this);
		propVarTablePanel.add(propTableModeBox);
		
		JLabel propVarTableSelectionColorLabel = new JLabel("Selection Color");
		propVarTableSelectionColorLabel.setBounds(16, 99, 102, 16);
		propVarTablePanel.add(propVarTableSelectionColorLabel);
		
		propTableSelectionColorWell = new ColorWell();
		propTableSelectionColorWell.setBounds(130, 93, 56, 30);
		propVarTablePanel.add(propTableSelectionColorWell);
		propTableSelectionColorWell.delegate=this;
		propTableSelectionColorWell.hasAlpha=true;
		
		JLabel lblTouchMode = new JLabel("Touch Mode:");
		lblTouchMode.setBounds(16, 65, 102, 16);
		propVarTablePanel.add(lblTouchMode);
		
		
		JButton propDeleteButton = new JButton("Delete");
		propDeleteButton.setFont(new Font("Lucida Grande", Font.PLAIN, 12));
		propDeleteButton.setBounds(50, 272, 117, 29);
		propDeleteButton.addActionListener(this);
		propDeleteButton.setActionCommand("deleteButtonPressed");
		propPanel.add(propDeleteButton);
		
		JButton propBringBackwardButton = new JButton("Bring Backward");
		propBringBackwardButton.setFont(new Font("Lucida Grande", Font.PLAIN, 11));
		propBringBackwardButton.addActionListener(this);
		propBringBackwardButton.setActionCommand("bringBackward");
		propBringBackwardButton.setBounds(0, 299, 110, 29);
		propPanel.add(propBringBackwardButton);
		
		JButton propBringForwardButton = new JButton("Bring Forward");
		propBringForwardButton.setFont(new Font("Lucida Grande", Font.PLAIN, 11));
		propBringForwardButton.setBounds(110, 299, 110, 29);
		propPanel.add(propBringForwardButton);
		propBringForwardButton.addActionListener(this);
		propBringForwardButton.setActionCommand("bringForward");
		
		
		
		
		//Lock
		JPanel lockPanel = new JPanel();
		tabbedPane.addTab("Lock", null, lockPanel, null);
		lockPanel.setLayout(null);
		
		consoleTextArea = new JTextArea();
		//consoleTextArea.setBounds(2, 20, 213, 163);
		consoleTextArea.setEditable(false);
		consoleTextArea.setWrapStyleWord(true);
		consoleTextArea.setLineWrap(true);
		consoleTextArea.setFont(new Font(consoleTextArea.getFont().getFontName(), Font.PLAIN, 12));
		/*DefaultCaret caret = (DefaultCaret)consoleTextArea.getCaret();
		caret.setUpdatePolicy(DefaultCaret.ALWAYS_UPDATE);
		*/
		JScrollPane consoleScrollPane = new JScrollPane(consoleTextArea);
		consoleScrollPane.setBounds(2,20,213,163);
		lockPanel.add(consoleScrollPane);
		
		JLabel lblNewLabel_5 = new JLabel("Messages To/From Patch");
		lblNewLabel_5.setFont(new Font("Lucida Grande", Font.PLAIN, 14));
		lblNewLabel_5.setBounds(22, 0, 178, 16);
		lockPanel.add(lblNewLabel_5);
		
		JButton lockClearButton = new JButton("Clear");
		lockClearButton.addActionListener(this);
		lockClearButton.setActionCommand("clearConsole");
		lockClearButton.setBounds(48, 182, 117, 29);
		lockPanel.add(lockClearButton);
		
		JLabel lblSendFakeHardware = new JLabel("Send fake hardware data");
		lblSendFakeHardware.setBounds(32, 212, 159, 16);
		lockPanel.add(lblSendFakeHardware);
		
		fakeXSlider = new JSlider();
		fakeXSlider.setValue(0);
		fakeXSlider.setMaximum(100);
		fakeXSlider.setMinimum(-100);
		fakeXSlider.setBounds(92, 227, 123, 29);
		fakeXSlider.addChangeListener(this);
		lockPanel.add(fakeXSlider);
		
		fakeYSlider = new JSlider();
		fakeYSlider.setValue(0);
		fakeYSlider.setMaximum(100);
		fakeYSlider.setMinimum(-100);
		fakeYSlider.setBounds(92, 245, 123, 29);
		fakeYSlider.addChangeListener(this);
		lockPanel.add(fakeYSlider);
		
		JLabel lblNewLabel_6 = new JLabel("Tilt X");
		lblNewLabel_6.setBounds(19, 235, 61, 16);
		lockPanel.add(lblNewLabel_6);
		
		JLabel lblTiltY = new JLabel("Tilt Y");
		lblTiltY.setBounds(19, 250, 61, 16);
		lockPanel.add(lblTiltY);
		
		JLabel lblxAndY = new JLabel("<html>X and Y are absolute and do<br>not rotate with landscape orientation");
		lblxAndY.setFont(new Font("Lucida Grande", Font.PLAIN, 10));
		lblxAndY.setBounds(10, 268, 205, 31);
		lockPanel.add(lblxAndY);
		
		JLabel lblShakeGesture = new JLabel("Shake Gesture");
		lblShakeGesture.setBounds(15, 306, 89, 16);
		lockPanel.add(lblShakeGesture);
		
		JButton btnShake = new JButton("Shake");
		btnShake.addActionListener(this);
		btnShake.setActionCommand("shake");
		btnShake.setBounds(105, 301, 95, 29);
		lockPanel.add(btnShake);
		
		
		
		
		JButton pageDownButton = new JButton("Down");
		pageDownButton.setActionCommand("pageDown");
		pageDownButton.addActionListener(this);
		pageDownButton.setBounds(4, 385, 76, 32);
		scrollContentPanel.add(pageDownButton);
		
		JButton pageUpButton = new JButton("Up");
		pageUpButton.setBounds(165, 385, 76, 32);
		pageUpButton.setActionCommand("pageUp");
		pageUpButton.addActionListener(this);
		scrollContentPanel.add(pageUpButton);
		
		pageIndexLabel = new JLabel("Page 1/1");
		pageIndexLabel.setBounds(92, 392, 73, 16);
		scrollContentPanel.add(pageIndexLabel);
		
		controlGuideLabel = new JLabel("");
		controlGuideLabel.setHorizontalAlignment(SwingConstants.CENTER);
		controlGuideLabel.setFont(new Font("Lucida Grande", Font.PLAIN, 11));
		controlGuideLabel.setBounds(4, 462, 238, 16);
		scrollContentPanel.add(controlGuideLabel);
		
		JButton layoutGridButton = new JButton("Layout Grid");
		layoutGridButton.setBounds(41, 431, 166, 29);
		layoutGridButton.setActionCommand("openLayoutGrid");
		layoutGridButton.addActionListener(this);
		scrollContentPanel.add(layoutGridButton);
		
		//menu
		menuBar = new JMenuBar();
		menuBar.setBounds(0, 0, 100, 22);
		frame.getContentPane().add(menuBar);
		
		JMenu fileMenu = new JMenu("File");
		menuBar.add(fileMenu);
		
		JMenuItem newFileMenuItem = new JMenuItem("New");
		fileMenu.add(newFileMenuItem);
		newFileMenuItem.addActionListener(this);
		newFileMenuItem.setActionCommand("New");
		//newFileMenuItem.setMnemonic(KeyEvent.VK_N);
		//newFileMenuItem.setAccelerator(KeyStroke.getKeyStroke(
		  //       KeyEvent.VK_N, ActionEvent.CTRL_MASK));
		newFileMenuItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_N, Toolkit.getDefaultToolkit().getMenuShortcutKeyMask()));
		
		
		JMenuItem openFileMenuItem = new JMenuItem("Open");
		fileMenu.add(openFileMenuItem);
		openFileMenuItem.addActionListener(this);
		openFileMenuItem.setActionCommand("Open");
		//openFileMenuItem.setMnemonic(KeyEvent.VK_O);
		//openFileMenuItem.setAccelerator(KeyStroke.getKeyStroke(
		 //        KeyEvent.VK_O, ActionEvent.CTRL_MASK));
		openFileMenuItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_O, Toolkit.getDefaultToolkit().getMenuShortcutKeyMask()));
		
		
		JMenuItem closeFileMenuItem = new JMenuItem("Close");
		fileMenu.add(closeFileMenuItem);
		closeFileMenuItem.addActionListener(this);
		closeFileMenuItem.setActionCommand("Close");
		//closeFileMenuItem.setMnemonic(KeyEvent.VK_W);
		//closeFileMenuItem.setAccelerator(KeyStroke.getKeyStroke(
		  //       KeyEvent.VK_W, ActionEvent.CTRL_MASK));
		closeFileMenuItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_W, Toolkit.getDefaultToolkit().getMenuShortcutKeyMask()));
		
		
		
		JMenuItem saveFileMenuItem = new JMenuItem("Save");
		fileMenu.add(saveFileMenuItem);
		saveFileMenuItem.addActionListener(this);
		saveFileMenuItem.setActionCommand("Save");
		//saveFileMenuItem.setMnemonic(KeyEvent.VK_S);
		//saveFileMenuItem.setAccelerator(KeyStroke.getKeyStroke(
		 //        KeyEvent.VK_S, ActionEvent.CTRL_MASK));
		saveFileMenuItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_S, Toolkit.getDefaultToolkit().getMenuShortcutKeyMask()));
		      
		
		JMenuItem saveAsFileMenuItem = new JMenuItem("Save As");
		fileMenu.add(saveAsFileMenuItem);
		saveAsFileMenuItem.addActionListener(this);
		saveAsFileMenuItem.setActionCommand("SaveAs");
		/*saveAsFileMenuItem.setMnemonic(KeyEvent.VK_S);
		saveAsFileMenuItem.setAccelerator(KeyStroke.getKeyStroke(
		         KeyEvent.VK_S, ActionEvent.CTRL_MASK));
		*/
		
		JMenuItem quitFileMenuItem = new JMenuItem("Quit");
		fileMenu.add(quitFileMenuItem);
		quitFileMenuItem.addActionListener(this);
		quitFileMenuItem.setActionCommand("Quit");
		//quitFileMenuItem.setMnemonic(KeyEvent.VK_Q);
		//quitFileMenuItem.setAccelerator(KeyStroke.getKeyStroke(
		  //       KeyEvent.VK_Q, ActionEvent.CTRL_MASK));
		quitFileMenuItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_Q, Toolkit.getDefaultToolkit().getMenuShortcutKeyMask()));
		
		
		//edit menu
		JMenu editMenu = new JMenu("Edit");
		menuBar.add(editMenu);
		
		JMenuItem copyEditMenuItem = new JMenuItem("Copy");
		editMenu.add(copyEditMenuItem);
		copyEditMenuItem.addActionListener(this);
		copyEditMenuItem.setActionCommand("Copy");
	//	copyEditMenuItem.setMnemonic(KeyEvent.VK_C);
		/*copyEditMenuItem.setAccelerator(KeyStroke.getKeyStroke(
		         KeyEvent.VK_C, ActionEvent.CTRL_MASK));*/
		copyEditMenuItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_C, Toolkit.getDefaultToolkit().getMenuShortcutKeyMask()));
		
		JMenuItem pasteEditMenuItem = new JMenuItem("Paste");
		editMenu.add(pasteEditMenuItem);
		pasteEditMenuItem.addActionListener(this);
		pasteEditMenuItem.setActionCommand("Paste");
		//pasteEditMenuItem.setMnemonic(KeyEvent.VK_V);
		/*pasteEditMenuItem.setAccelerator(KeyStroke.getKeyStroke(
		         KeyEvent.VK_V, ActionEvent.CTRL_MASK));*/
		pasteEditMenuItem.setAccelerator(KeyStroke.getKeyStroke(KeyEvent.VK_V, Toolkit.getDefaultToolkit().getMenuShortcutKeyMask()));
		
		//layout grid dialog
		JPanel layoutPanel = new JPanel();
    	//layoutPanel.setBackground(Color.BLUE);
    	
    	snapToGridXTextField = new JTextField(""+controller.snapToGridXVal);
    	snapToGridXTextField.setColumns(4);
    	snapToGridXTextField.addActionListener(new ActionListener() {
    	    public void actionPerformed(ActionEvent e) {
    	    	updateSnapToGridXField();
    	    }
    	});
    	snapToGridXTextField.addFocusListener(this);
    	
    	snapToGridYTextField = new JTextField(""+controller.snapToGridYVal);
    	snapToGridYTextField.setColumns(4);
    	snapToGridYTextField.addActionListener(new ActionListener() {
    	    public void actionPerformed(ActionEvent e) {
    	    	updateSnapToGridYField();
    	    }
    	});
    	snapToGridYTextField.addFocusListener(this);
    	
    	final JCheckBox snapToGridEnabledCheckBox = new JCheckBox("Snap to grid");
    	snapToGridEnabledCheckBox.setSelected(controller.snapToGridEnabled);
    	snapToGridEnabledCheckBox.addActionListener(new ActionListener() {
    	    public void actionPerformed(ActionEvent e) {
    	    	controller.snapToGridEnabled = snapToGridEnabledCheckBox.isSelected();
    	    	canvasPanel.repaint();
    	    	Preferences prefs = Preferences.userNodeForPackage(MMPWindow.class);
    	    	prefs.putBoolean("snapToGridEnabled", controller.snapToGridEnabled);
    	    }
    	});
    	
    	final JButton snapAllButton = new JButton("Snap all widgets to grid");
    	snapAllButton.addActionListener(new ActionListener() {
    	    public void actionPerformed(ActionEvent e) {
    	    	controller.snapAllToGrid();
    	    }
    	});
    	
    	final JButton closeButton = new JButton("Close");
    	
    	
    	//JButton closeButton = new JButton("Close");
    	layoutPanel.setLayout(new FlowLayout());//BoxLayout(layoutPanel, BoxLayout.Y_AXIS));
    	layoutPanel.add(snapToGridEnabledCheckBox);
    	
    	//JPanel xPanel = new JPanel();
    	layoutPanel.add(new JLabel("X points:"));
    	layoutPanel.add(snapToGridXTextField);
    	//JPanel yPanel = new JPanel();
    	layoutPanel.add(new JLabel("Y points:"));
    	layoutPanel.add(snapToGridYTextField);
    	
    	//layoutPanel.add(xPanel);
    	//layoutPanel.add(yPanel);
    	
    	layoutPanel.add(snapAllButton);
    	layoutPanel.add(closeButton);
    	
    	
    	layoutDialog = new JDialog(frame);
    	layoutDialog.setModal(true);
    	layoutDialog.add(layoutPanel);
    	layoutDialog.pack();
    	layoutDialog.setResizable(false);
    	
    	closeButton.addActionListener(new ActionListener() {
    	    public void actionPerformed(ActionEvent e) {
    	    	layoutDialog.setVisible(false);
    	    }
    	});
		
		updateWindowAndCanvas();
		//kick pd with "/opened"
		Object[] args = new Object[]{new Integer(1)};
		controller.sendMessage("/system/opened", args);
	}
	
	void updateSnapToGridXField() {
		String text = snapToGridXTextField.getText();
    	try{
    		int val = Integer.parseInt(text);
    		if (val<5 || val > 1000) throw new NumberFormatException();
    		controller.snapToGridXVal = val;
    		canvasPanel.repaint();
    		Preferences prefs = Preferences.userNodeForPackage(MMPWindow.class);
    		prefs.putInt("snapToGridXVal", val);
    	} catch(NumberFormatException nfe){
    		snapToGridXTextField.setText(""+controller.snapToGridYVal);
    	}
	}
	void updateSnapToGridYField() {
		String text = snapToGridYTextField.getText();
    	try{
    		int val = Integer.parseInt(text);
    		if (val<5 || val > 1000) throw new NumberFormatException();
    		controller.snapToGridYVal = val;
    		canvasPanel.repaint();
    		Preferences prefs = Preferences.userNodeForPackage(MMPWindow.class);
    		prefs.putInt("snapToGridYVal", val);
    	} catch(NumberFormatException nfe){
    		snapToGridYTextField.setText(""+controller.snapToGridYVal);
    	}
	}
	
	void exitHelper(){
		System.out.println("exit helper");
		MMPController.clearCache();
	}
	
	void closeWindowHelper(){
		System.out.println("close window");
		
		if(controller.dirtyBit==false){
			frame.dispose();
			openWindows--;
			if (openWindows == 0) {
		         System.exit(0);  // Terminate when the last window is closed.
		    }
		}
		else{//dirty bit
	   		int n = JOptionPane.showConfirmDialog(
 			    frame,
 			    "Do you want to save changes in document "+controller.filename+ "?",
 			    null,//alert title
			    JOptionPane.YES_NO_CANCEL_OPTION);
 			if(n==0){//yes
 				//System.out.print("\nyes");
 				if(controller.filePath!=null)saveHelper();//todo check for successful save
 				else saveAsHelper();
 				//assuming saved
 				frame.dispose();
 				openWindows--;
 				if (openWindows == 0) {
 		            System.exit(0);  // Terminate when the last window is closed.
 		        }
 				
 			}
 			else if(n==1){//no
 				//System.out.print("\nno");
 				frame.dispose();
 				openWindows--;
 				if (openWindows == 0) {
 		            System.exit(0);  // Terminate when the last window is closed.
 		        }
 		        
 			}
 			else {
 				//System.out.print("\ncancel");
 			}
 			
	    }		
	}
	
	void saveAsHelper(){
		if(controller.filePath==null)fc.setSelectedFile(new File("Untitled.mmp"));
		int returnVal = fc.showSaveDialog(this.canvasPanel);

        if (returnVal == JFileChooser.APPROVE_OPTION) {
            File file = fc.getSelectedFile();
            
            controller.filePath = file.getAbsolutePath(); 
            controller.filename = file.getName();
            frame.setTitle(controller.filename);
            //String outString = controller.documentModel.modelToString();
            BufferedWriter writer = null;
        	try  {
        		writer = new BufferedWriter( new FileWriter( file));
        		writer.write( controller.documentModel.modelToString() );
        		controller.dirtyBit=false;
        	}
        	catch ( IOException e){
        	}
        	finally            	{
        		try	{
        			if ( writer != null)writer.close( );
        		}
        		catch ( IOException e){}
             }
        }
	}
	
	void saveHelper(){
		BufferedWriter writer = null;
    	try  {
    		writer = new BufferedWriter( new FileWriter( new File(controller.filePath)));
    		writer.write( controller.documentModel.modelToString() );
    		controller.dirtyBit=false;
    	}
    	catch ( IOException e){
    	}
    	finally            	{
    		try	{
    			if ( writer != null)writer.close( );
    		}
    		catch ( IOException e){}
         }
	}
	
	void sendTilts(){
		Object[] args = new Object[]{new Float((float)fakeXSlider.getValue()/100), new Float((float)fakeYSlider.getValue()/100)};
		controller.sendMessage("/system/tilts", args);
	}
	
	//tabbed pane and slider change
	public void stateChanged(ChangeEvent e) {
        if(e.getSource().equals(tabbedPane)){
        	 if(tabbedPane.getSelectedIndex()<3)controller.setIsEditing(true);
	            else controller.setIsEditing(false);
        }
        else if (e.getSource().equals(propLabelTabbedPane)){
        	boolean isAndroid = (propLabelTabbedPane.getSelectedIndex()==1);
        	for (MMPControl control : controller.documentModel.controlArray) {
        		if (control instanceof MMPLabel) {
        			((MMPLabel)control).showAndroidFont(isAndroid);
        		}
        	}
        }
        else if(e.getSource().equals(fakeXSlider)){
        	sendTilts();
        }
        else if(e.getSource().equals(fakeYSlider)){
        	sendTilts();
        }
	}
	//text feld, jmenu
	public void actionPerformed(ActionEvent evt) {
		//System.out.print("\naction");
		String cmd = evt.getActionCommand();

        if(cmd.equals("New")){
            
        	try {
				MMPWindow window = new MMPWindow();
				window.frame.setLocation((int)this.frame.getLocation().getX()+30, (int)this.frame.getLocation().getY()+30 );
				window.frame.setVisible(true);
				//this.frame.dispose();
			} catch (Exception e) {
				e.printStackTrace();
			}
        }
        
        else if(cmd.equals("Save")){
        	if(controller.filePath!=null)saveHelper();
        	else saveAsHelper();
        	
        }
        
        else if(cmd.equals("SaveAs")){
        	saveAsHelper();
        }
        
        else if(cmd.equals("Close")){
        	closeWindowHelper();
        }
        
        else if(cmd.equals("Open")){
        	try{
        	int returnVal = fc.showOpenDialog(this.canvasPanel);
        	
            if (returnVal == JFileChooser.APPROVE_OPTION) {
                File file = fc.getSelectedFile();
               
                //This is where a real application would open the file.
                //log.append("Opening: " + file.getName() + "." + newline);
           
        		
        		
        			//BufferedReader br = new BufferedReader(	new FileReader("test/MMPTutorial0-HelloSine.mmp")); 
        			BufferedReader reader = new BufferedReader( new FileReader (file));
        		    String         line = null;
        		    StringBuilder  stringBuilder = new StringBuilder();
        		    //String         ls = System.getProperty("line.separator");

        		    while( ( line = reader.readLine() ) != null ) {
        		        stringBuilder.append( line );
        		      //  stringBuilder.append( ls );
        		    }

        		   //System.out.print(stringBuilder.toString());
        		    
        			MMPWindow window = new MMPWindow();
        			window.controller.documentModel=DocumentModel.modelFromString(stringBuilder.toString());
        			window.frame.setTitle(file.getName());
        			window.controller.filePath = file.getAbsolutePath(); 
        			window.controller.filename = file.getName();
        			//System.out.print("model has "+ window.controller.documentModel.controlArray.size());
        			
        			window.controller.loadFromModel();
        		    //backwards ordering: json will be in back-to-front ordering, wheras adding to container paints them front-to-back
        		    /*for(MMPControl control: documentModel.controlArray){
        		        control.editingDelegate=this;
        		        windowDelegate.canvasPanel.add(control);
        		    }*/
        		/*    ListIterator<MMPControl> li = window.controller.documentModel.controlArray.listIterator(window.controller.documentModel.controlArray.size());

        		 // Iterate in reverse.
        		 while(li.hasPrevious()) {
        			 MMPControl control = li.previous();
        		   control.editingDelegate=window.controller;
        	       window.canvasPanel.add(control);
        	       System.out.print("+");
        		 }*/
        		 
        		 window.frame.setLocation((int)this.frame.getLocation().getX()+30, (int)this.frame.getLocation().getY()+30 );
 				window.frame.setVisible(true);
        		
            } else {
                //log.append("Open command cancelled by user." + newline);
            }
        		} catch (IOException e) {
        			e.printStackTrace();
        		}
        	
        }
        //edit
        else if(cmd.equals("Copy")){
        	System.out.print("\ncmd copy");
        	copyArrayList.clear();
        	//TODO: why am I making a copy of the object here, and then again on paste? (if I only do one, it fails)
        	for(MMPControl control :controller.documentModel.controlArray){
	            if (control.isSelected) {
	            	if(control instanceof MMPSlider)copyArrayList.add(new MMPSlider((MMPSlider)control));
	            	else if(control instanceof MMPKnob)copyArrayList.add(new MMPKnob((MMPKnob)control));
	            	else if(control instanceof MMPXYSlider)copyArrayList.add( new MMPXYSlider((MMPXYSlider)control));
	       	        else if(control instanceof MMPLabel)copyArrayList.add(new MMPLabel((MMPLabel)control));
	       	        else if(control instanceof MMPButton)copyArrayList.add( new MMPButton((MMPButton)control));
	    	        else if(control instanceof MMPToggle)copyArrayList.add(new MMPToggle((MMPToggle)control));
	    	        else if(control instanceof MMPGrid)copyArrayList.add(new MMPGrid((MMPGrid)control));
	    	        else if(control instanceof MMPPanel)copyArrayList.add(  new MMPPanel((MMPPanel)control));
	    	        else if(control instanceof MMPMultiSlider)copyArrayList.add(new MMPMultiSlider((MMPMultiSlider)control));
	    	        else if(control instanceof MMPLCD)copyArrayList.add(new MMPLCD((MMPLCD)control));
	    	        else if(control instanceof MMPMultiTouch)copyArrayList.add(new MMPMultiTouch((MMPMultiTouch)control));
	    	        else if(control instanceof MMPTable)copyArrayList.add(new MMPTable((MMPTable)control));
	    	        else if(control instanceof MMPMenu)copyArrayList.add(new MMPMenu((MMPMenu)control));
		            
	            }
	        }
        	
        }
        else if(cmd.equals("Paste")){
        	System.out.print("\ncmd paste");
        	if(controller.isEditing()==true){
        		//clear selection
        		controller.clearSelection();
        		for(MMPControl control: controller.documentModel.controlArray)control.setIsSelected(false); 
        		
        		MMPControl newControl=null;
        		
        		for(MMPControl control :copyArrayList){	
       	           if(control instanceof MMPSlider){
       	        	    newControl = new MMPSlider((MMPSlider)control);
       	        	   controller.pasteControlHelper(newControl);
       	           }
       	           else if(control instanceof MMPKnob){
       	        	   newControl = new MMPKnob((MMPKnob)control);
       	        	   controller.pasteControlHelper(newControl);
       	           }
       	           else if(control instanceof MMPXYSlider){
       	        	   newControl = new MMPXYSlider((MMPXYSlider)control);
       	        	   controller.pasteControlHelper(newControl);
       	           }
       	           else if(control instanceof MMPLabel){
       	           		newControl = new MMPLabel((MMPLabel)control);
       	           		controller.pasteControlHelper(newControl);
       	           }
       	           else if(control instanceof MMPButton){
    	        	    newControl = new MMPButton((MMPButton)control);
    	        	   controller.pasteControlHelper(newControl);
    	           }
       	           else if(control instanceof MMPToggle){
    	        	   newControl = new MMPToggle((MMPToggle)control);
    	        	   controller.pasteControlHelper(newControl);
    	           }
       	           else if(control instanceof MMPGrid){
    	        	   newControl = new MMPGrid((MMPGrid)control);
    	        	   controller.pasteControlHelper(newControl);
    	           }
       	           else if(control instanceof MMPPanel){
    	           		newControl = new MMPPanel((MMPPanel)control);
    	           		controller.pasteControlHelper(newControl);
    	           }
       	           else if(control instanceof MMPMultiSlider){
    	           		newControl = new MMPMultiSlider((MMPMultiSlider)control);
    	           		controller.pasteControlHelper(newControl);
    	           }
       	           else if(control instanceof MMPLCD){
    	           		newControl = new MMPLCD((MMPLCD)control);
    	           		controller.pasteControlHelper(newControl);
    	           }
       	           else if(control instanceof MMPMultiTouch){
       	        	   newControl = new MMPMultiTouch((MMPMultiTouch)control);
       	        	   controller.pasteControlHelper(newControl);
       	           }
       	           else if(control instanceof MMPMenu){
    	           		newControl = new MMPMenu((MMPMenu)control);
    	           		controller.pasteControlHelper(newControl);
    	           }
       	           else if(control instanceof MMPTable){
       	        	   newControl = new MMPTable((MMPTable)control);
       	        	   controller.pasteControlHelper(newControl);
       	           }
       	           
        		}
        		if(copyArrayList.size()==1 && newControl!=null){
        			controller.controlEditClicked(newControl, false, false);
        		}
	           
        	}
        }
        else if(cmd.equals("Quit")){//todo: not being called
        	//System.out.println("quit command");
        	for(MMPController c : MMPController.controllerArrayList){
        		c.windowDelegate.closeWindowHelper();
        	}
        }
        else if(cmd.equals("pageDown")){
        	if(controller.currentPageIndex>0)controller.setCurrentPage(controller.currentPageIndex-1);
        }
        
        else if(cmd.equals("pageUp")){
        	if(controller.currentPageIndex<controller.documentModel.pageCount-1)controller.setCurrentPage(controller.currentPageIndex+1);
        }
        else if (cmd.equals("openLayoutGrid")) {
        	
        	layoutDialog.setVisible(true);
        	
        }
        else if(cmd.equals("canvasType")){
        	switch(docCanvasTypeMenu.getSelectedIndex()){
        		case 0:controller.documentModel.canvasType = DocumentModel.CanvasType.canvasTypeIPhone3p5Inch; break;
        		case 1:controller.documentModel.canvasType = DocumentModel.CanvasType.canvasTypeIPhone4Inch; break;
        		case 2:controller.documentModel.canvasType = DocumentModel.CanvasType.canvasTypeIPad; break;
        		case 3:controller.documentModel.canvasType = DocumentModel.CanvasType.canvasTypeAndroid7Inch; break;
        	}
        	controller.dirtyBit=true;
        	updateWindowAndCanvas();
        }
        
        else if(cmd.equals("orientation")){
        	switch(docOrientationMenu.getSelectedIndex()){
    		case 0:controller.documentModel.isOrientationLandscape =false; break;
    		case 1:controller.documentModel.isOrientationLandscape = true; break;
    		
        	}
        	controller.dirtyBit=true;
        	updateWindowAndCanvas();
        }
        
        else if(cmd.equals("pageCount")){
        	updatePageCount();
        }
        
        else if(cmd.equals("startPage")){
        	//System.out.print("\ncomand startPage");
        	updateStartPage();
        }
        
        else if(cmd.equals("port")){
        	updatePort();
        }
        
        else if(cmd.equals("pdFile")){
        	updateDocPdFile();
        }
        
        else if(cmd.equals("pdFileButton")){//button
        	//String text = pageCountTextField.getText();
        	int returnVal = pdfc.showOpenDialog(this.canvasPanel);

            if (returnVal == JFileChooser.APPROVE_OPTION) {
                File file = pdfc.getSelectedFile();
                controller.documentModel.pdFile = file.getName();
                this.docFileTextField.setText(file.getName());
                controller.dirtyBit=true;
            }
        }
        
        else if(cmd.equals("addSlider")){
        	controller.addSlider();
        }
        else if(cmd.equals("addKnob")){
        	controller.addKnob();
        }
        else if(cmd.equals("addXYSlider")){
        	controller.addXYSlider();
        }
        else if(cmd.equals("addLabel")){
        	controller.addLabel();
        }
        else if(cmd.equals("addButton")){
        	controller.addButton();
        }
        else if(cmd.equals("addToggle")){
        	controller.addToggle();
        }
        else if(cmd.equals("addGrid")){
        	controller.addGrid();
        }
        else if(cmd.equals("addPanel")){
        	controller.addPanel();
        }
        else if(cmd.equals("addMultiSlider")){
        	controller.addMultiSlider();
        }
        else if(cmd.equals("addLCD")){
        	controller.addLCD();
        }
        else if(cmd.equals("addMultiTouch")){
        	controller.addMultiTouch();
        }
        else if(cmd.equals("addMenu")){
        	controller.addMenu();
        }
        else if(cmd.equals("addTable")){
        	controller.addTable();
        }
        else if(cmd.equals("propAddressChanged")){
        	updateAddress();
        }
        else if(cmd.equals("propVarSliderRangeChanged")){
        	updateSliderRange();
        }
        
        else if(cmd.equals("propVarSliderOrientationChanged")){
        	//System.out.print("\npropVarSliderOrientationChanged ===");
        	MMPSlider currSlider = (MMPSlider)controller.currentSingleSelection;
        	boolean newIsHoriz = (propVarSliderOrientationBox.getSelectedIndex()==0) ? false : true;
        	currSlider.setIsHorizontal(newIsHoriz);
        }
        
        else if(cmd.equals("propVarKnobRangeChanged")){
        	updateKnobRange();
        }
        
        else if(cmd.equals("propVarLabelSizeChanged")){
        	updateLabelSize();
        }
        
        else if(cmd.equals("font")){
        	List<Map> fontArray = MMPController.fontArray;
        	Map<String, Object> currFamilyMap = fontArray.get(propLabelFontBox.getSelectedIndex());
        	
        	String currFamily = (String)currFamilyMap.get("family");
        	List<String> typeList = (List<String>)currFamilyMap.get("types");
        	
        	propLabelFontTypeBox.removeActionListener( propLabelFontTypeBox.getActionListeners()[0]);
        	
        	propLabelFontTypeBox.removeAllItems();
        	for(String currType: typeList){
        		propLabelFontTypeBox.addItem(currType);
        	}
        	propLabelFontTypeBox.addActionListener(this);
        	if(typeList.size()>0)propLabelFontTypeBox.setSelectedIndex(0);
        	else if(currFamily.equals("Default")){
        		MMPLabel currLabel = (MMPLabel)controller.currentSingleSelection;
        		if(currLabel!=null) currLabel.setFontFamilyAndName("Default", "Default");
        	}
        }
        
        else if(cmd.equals("fontType")){
        	String currFamily = (String)propLabelFontBox.getSelectedItem();
        	String currType = (String)propLabelFontTypeBox.getSelectedItem();
        	System.out.print("\nsetting fonttype "+currFamily+" "+currType);
			
        	MMPLabel currLabel = (MMPLabel)controller.currentSingleSelection;
        	if(currLabel!=null){
        		currLabel.setFontFamilyAndName(currFamily, currType );
        		if(!systemHasFontFamily(currFamily)){
        			//System.out.print("\nfonttype can't");
        			//can't make the font...
        			//JOptionPane.showMessageDialog(frame, "Cannot find font.\n(Still setting label to this font,\nwill render in this font on device)");
        		}
        	}
        }
        
        else if(cmd.equals("androidFontType")) {
        	String androidFontName = (String)propLabelAndroidFontTypeBox.getSelectedItem();
        	MMPLabel currLabel = (MMPLabel)controller.currentSingleSelection;
        	if(currLabel!=null){
        		currLabel.setAndroidFontName(androidFontName);
        	}
        }
     
        else if(cmd.equals("propVarGridDimXChanged")){
        	updateGridX();
        }
        else if(cmd.equals("propVarGridDimYChanged")){
        	updateGridY();
        }
        else if(cmd.equals("propVarGridBorderThicknessChanged")){
        	updateGridBorderThickness();
        }
        else if(cmd.equals("propVarGridCellPaddingChanged")){
        	updateGridCellPadding();
        }
        else if(cmd.equals("propVarPanelFileChanged")){
        	updatePanelFile();
        	
        }
        else if (cmd.equals("panelShouldPassTouchesChanged")){
        	updatePanelShouldPassTouches();
        }
        
        else if(cmd.equals("propVarMultiCountChanged")){
        	updateMultiSliderCount();
        }
        
        else if(cmd.equals("propVarToggleBorderThicknessChanged")){
        	updateToggleThickness();
        }
        else if (cmd.equals("propVarMenuTitleChanged")){
        	MMPMenu currMenu = (MMPMenu)controller.currentSingleSelection;
        	currMenu.setTitleString(propMenuTitleTextField.getText());
        }
        else if (cmd.equals("propTableModeChanged")){
        	MMPTable currTable = (MMPTable)controller.currentSingleSelection;
        	currTable.setMode(propTableModeBox.getSelectedIndex());
        }
        else if (cmd.equals("propGridModeChanged")){
        	MMPGrid currGrid = (MMPGrid)controller.currentSingleSelection;
        	currGrid.setMode(propGridModeBox.getSelectedIndex());
        }
        
        else if(cmd.equals("deleteButtonPressed")){
        	controller.deletePressed();
        }
        else if(cmd.equals("bringBackward")){
        	ArrayList<MMPControl> selectedControls = new ArrayList<MMPControl>();
        	//iterate backwards!
        	ListIterator<MMPControl> li = controller.documentModel.controlArray.listIterator(controller.documentModel.controlArray.size());

   		 // Iterate in reverse.
   		 	while(li.hasPrevious()) {
   		 		MMPControl control = li.previous();
        		if(control.isSelected==true){
        			selectedControls.add(control);
        		}
        	}
        	for(MMPControl control: selectedControls){
        		
        			//change both zorder and controlarray order
        			controller.documentModel.controlArray.remove(control);
        			controller.documentModel.controlArray.add(0, control);
        			canvasPanel.setComponentZOrder(control, canvasPanel.getComponentCount()-1);
        			
        		
        	}
        	controller.dirtyBit=true;
        	canvasPanel.repaint();
        }
        else if(cmd.equals("bringForward")){
        	ArrayList<MMPControl> selectedControls = new ArrayList<MMPControl>();
        	
        	for(MMPControl control: controller.documentModel.controlArray){
        		if(control.isSelected==true){
        			selectedControls.add(control);
        		}
        	}
        	for(MMPControl control: selectedControls){	
        		
        			//change both zorder and controlarray order
        			controller.documentModel.controlArray.remove(control);
        			controller.documentModel.controlArray.add(control);//to END of controlArray
        			canvasPanel.setComponentZOrder(control, 0);//to FRONT of zorder
        			
        	}
        	controller.dirtyBit=true;
        	canvasPanel.repaint();
        }
        
        else if(cmd.equals("clearConsole")){
        	this.consoleTextArea.setText("");
        	controller.textLineArray.clear();
        }
        
        else if(cmd.equals("shake")){
        	Object[] args = new Object[]{new Integer(1)};
        	controller.sendMessage("/system/shake", args);
        }
	}
	
	public boolean systemHasFontFamily(String fontFamily){
		for(String s: systemFontList){// String[] systemFontList
			if (s.equals(fontFamily)) return true;
		}
		return false;
	}
		
	
	//ugh, helpers
	
	void updateDocPdFile(){
		String text = docFileTextField.getText();
    	if(text!=controller.documentModel.pdFile){//on change
    		controller.documentModel.pdFile = text;
    		controller.dirtyBit=true;
    	}
	}
	
	void updatePageCount(){
		//System.out.print("\nUPDATE PAGE COUNT");
		String text = docPageCountField.getText();
    	try{
    		int oldPageCount = controller.documentModel.pageCount;
    		int newPageCount = Integer.parseInt(text);
    		//System.out.print("\n"+newPageCount);
    		if(newPageCount<1){
    			newPageCount=1;
    			docPageCountField.setText("1");
    		}
    		if(newPageCount>oldPageCount){//add pages
    			controller.documentModel.pageCount=newPageCount;
    			controller.dirtyBit=true;
    		}
    		else if (newPageCount<oldPageCount){//remove pages
    			//JOption fires a focus lost, which is redundant on us hitting enter (and creates two optionpanes), so disable focus listener momentarily
    			this.docPageCountField.removeFocusListener(this);
    			int n = JOptionPane.showConfirmDialog(
    				    frame,
    				    "Delete Page(s)?",
    				    "Change Page Count",
    				    JOptionPane.YES_NO_OPTION);
    			if(n==0){
    				 controller.documentModel.pageCount = newPageCount;
    				 controller.dirtyBit=true;
    		            //do we have to change current page?
    		            if(controller.currentPageIndex>=newPageCount)controller.setCurrentPage(newPageCount-1);
    		            
    			}
    			else{
    				docPageCountField.setText(""+oldPageCount);
    			}
    			this.docPageCountField.addFocusListener(this);
    		}
    		canvasPanel.setPageCount(controller.documentModel.pageCount);
    		controller.pruneControls();
    		pageIndexLabel.setText("Page "+(controller.currentPageIndex+1)+"/"+controller.documentModel.pageCount);
    		
    	}
    	catch(NumberFormatException e){
    		docPageCountField.setText(""+controller.documentModel.pageCount);
    	}
	}

	void updateStartPage(){
		String text = docStartPageField.getText();
		//System.out.print("\nupdate stat page");
		try{
    		int val = Integer.parseInt(text)-1;
    		//System.out.print("\nupdate stat page"+val);//todo check range
    		if(val>=controller.documentModel.pageCount){//greater than page count
    			controller.documentModel.startPageIndex=controller.documentModel.pageCount-1;
    			docStartPageField.setText(""+(controller.documentModel.startPageIndex+1));
    		}
    		else controller.documentModel.startPageIndex=val;
    		controller.dirtyBit=true;
    		//
    		
    	}
    	catch(NumberFormatException e){
    		docStartPageField.setText(""+(controller.documentModel.startPageIndex+1));
    	}
	}

	void updatePort(){
		String text = portTextField.getText();
    	try{
    		int val = Integer.parseInt(text);
    		System.out.print("\n"+val);
    		controller.documentModel.port=val;
    		controller.dirtyBit=true;
    	}
    	catch(NumberFormatException e){
    		portTextField.setText(""+controller.documentModel.port);
    	}
	}

	void updateAddress(){
		controller.propAddressChanged(propAddressTextField.getText());
	}
	
	void updateSliderRange(){
		MMPSlider currSlider = (MMPSlider)controller.currentSingleSelection;
    	String text = propVarSliderRangeTextField.getText();
    	int oldRange = currSlider.range;
    	try{
    		int newRange = Integer.parseInt(text);
    		if(newRange<2)
    			newRange=2;
    		if(newRange>1000)
    			newRange = 1000;
    			
    		propVarSliderRangeTextField.setText(""+newRange);	
    		
    		currSlider.setRange(newRange);
    	}
    	catch(NumberFormatException e){
    		propVarSliderRangeTextField.setText(""+currSlider.range);
    	}
	}
		

	void updateKnobRange(){
		MMPKnob currKnob = (MMPKnob)controller.currentSingleSelection;
    	String text = propVarKnobRangeTextField.getText();
    	//int oldRange = currKnob.range;
    	try{
    		int newRange = Integer.parseInt(text);
    		if(newRange<2)
    			newRange=2;
    		if(newRange>1000)
    			newRange = 1000;
    			
    		
    		propVarSliderRangeTextField.setText(""+newRange);
    		
    		currKnob.setRange(newRange);
    	}
    	catch(NumberFormatException e){
    		propVarSliderRangeTextField.setText(""+currKnob.range);
    	}
	}

	void updateLabelSize(){
		MMPLabel currLabel = (MMPLabel)controller.currentSingleSelection;
    	String text = propLabelSizeTextField.getText();
    	int oldTextSize = currLabel.textSize;
    	try{
    		int newTextSize = Integer.parseInt(text);
    		currLabel.setTextSize(newTextSize);
    	}
    	catch(NumberFormatException e){
    		propLabelSizeTextField.setText(""+currLabel.textSize);
    	}
	}
		
	void updateGridX(){
		MMPGrid currGrid = (MMPGrid)controller.currentSingleSelection;
    	String text = propGridDimXTextField.getText();
    	try{
    		int newDimX = Integer.parseInt(text);
    		currGrid.setDimX(newDimX);
    	}
    	catch(NumberFormatException e){
    		propGridDimXTextField.setText(""+currGrid.dimX);
    	}
	}
	
	void updateGridY(){
		MMPGrid currGrid = (MMPGrid)controller.currentSingleSelection;
    	String text = propGridDimYTextField.getText();
    	try{
    		int newDimY = Integer.parseInt(text);
    		currGrid.setDimY(newDimY);
    	}
    	catch(NumberFormatException e){
    		propGridDimYTextField.setText(""+currGrid.dimY);
    	}
	}

	void updateGridBorderThickness(){
		MMPGrid currGrid = (MMPGrid)controller.currentSingleSelection;
    	String text = propGridBorderThicknessTextField.getText();
    	
    	try{
    		int newBorderSize = Integer.parseInt(text);
    		currGrid.setBorderThickness(newBorderSize);
    	}
    	catch(NumberFormatException e){
    		propGridBorderThicknessTextField.setText(""+currGrid.borderThickness);
    	}
	}

	void updateGridCellPadding(){
		MMPGrid currGrid = (MMPGrid)controller.currentSingleSelection;
    	String text = propGridCellPaddingTextField.getText();
    	try{
    		int newPadding = Integer.parseInt(text);
    		currGrid.setCellPadding(newPadding);
    	}
    	catch(NumberFormatException e){
    		propGridCellPaddingTextField.setText(""+currGrid.cellPadding);
    	}
	}
	
	void updatePanelFile(){
		MMPPanel currPanel = (MMPPanel)controller.currentSingleSelection;
    	String text = propPanelFileTextField.getText();
    	currPanel.setImagePath(text);
    	currPanel.loadImage();
	}
	
	void updatePanelShouldPassTouches(){
		MMPPanel currPanel = (MMPPanel)controller.currentSingleSelection;
		boolean check = propPanelShouldPassTouchesCheckBox.isSelected();
		currPanel.shouldPassTouches = check;
		
	}
	
	void updateMultiSliderCount(){
		MMPMultiSlider currMulti = (MMPMultiSlider)controller.currentSingleSelection;
    	String text = propMultiCountTextField.getText();
    	try{
    		int newCount = Integer.parseInt(text);
    		currMulti.setRange(newCount);
    	}
    	catch(NumberFormatException e){
    		propMultiCountTextField.setText(""+currMulti.range);
    	}
	}

	void  updateToggleThickness(){
		MMPToggle currToggle = (MMPToggle)controller.currentSingleSelection;
    	String text = propToggleThicknessTextField.getText();
    	try{
    		int newBorderThickness = Integer.parseInt(text);
    		currToggle.setBorderThickness(newBorderThickness);
    	}
    	catch(NumberFormatException e){
    		propToggleThicknessTextField.setText(""+currToggle.borderThickness);
    	}
	}

	
	void updateWindowAndCanvas(){
		//CGRect screenFrame = [[NSScreen mainScreen] visibleFrame];
		Dimension screenSize = Toolkit.getDefaultToolkit().getScreenSize();
		double height = screenSize.getHeight();
		
	    //System.out.print("\nupdate - canvas "+controller.documentModel.canvasType+" orientislandscape "+controller.documentModel.isOrientationLandscape);
	    if(controller.documentModel.canvasType==DocumentModel.CanvasType.canvasTypeIPhone3p5Inch){//iphone 3.5"
	        if(controller.documentModel.isOrientationLandscape==false){//portrait
	            frame.getContentPane().setPreferredSize(new Dimension(CANVAS_LEFT+320+CANVAS_TOP, 480+CANVAS_TOP+CANVAS_TOP+menuBar.getHeight()));
	            frame.pack();
	            canvasOuterPanel.setBounds(new Rectangle(CANVAS_LEFT,CANVAS_TOP, 320, 480));
	            scrollPane.setSize(new Dimension(CANVAS_LEFT+320+CANVAS_TOP, 480+CANVAS_TOP+CANVAS_TOP));
	            //scrollContentPanel seems to resize - no
	            scrollContentPanel.setPreferredSize( new Dimension(5,5) );
	            
	            //[documentScrollView setFrame:CGRectMake(0, 0, documentView.frame.size.width, documentView.frame.size.height)];
	            //[documentScrollView.documentView setFrameSize:documentScrollView.contentSize];
	            //[canvasOuterView setFrame:CGRectMake(CANVAS_LEFT,documentView.frame.size.height-480-CANVAS_TOP, 320, 480)];
	            
	        }
	        else{//landscape
	            
	        	frame.getContentPane().setPreferredSize(new Dimension(CANVAS_LEFT+480+CANVAS_TOP, 500+menuBar.getHeight()));
	        	frame.pack();
	        	canvasOuterPanel.setBounds(new Rectangle(CANVAS_LEFT,CANVAS_TOP, 480, 320));
	        	scrollPane.setSize(new Dimension(CANVAS_LEFT+480+CANVAS_TOP, 500));
	        	scrollContentPanel.setPreferredSize( new Dimension(5,5) );
	           // [documentScrollView setFrame:CGRectMake(0, 0, documentView.frame.size.width, documentView.frame.size.height)];
	           // [documentScrollView.documentView setFrameSize:documentScrollView.contentSize];
	           // [canvasOuterView setFrame:CGRectMake(CANVAS_LEFT,documentView.frame.size.height-320-CANVAS_TOP, 480, 320)];
	        }
	    }
	    else if(controller.documentModel.canvasType==DocumentModel.CanvasType.canvasTypeIPhone4Inch){//iphone 4"
	    	if(controller.documentModel.isOrientationLandscape==false){//portrait
	            frame.getContentPane().setPreferredSize(new Dimension(CANVAS_LEFT+320+CANVAS_TOP, 568+CANVAS_TOP+CANVAS_TOP+menuBar.getHeight()));
	            frame.pack();
	            canvasOuterPanel.setBounds(new Rectangle(CANVAS_LEFT,CANVAS_TOP, 320, 568));
	            scrollPane.setSize(new Dimension(CANVAS_LEFT+320+CANVAS_TOP, 568+CANVAS_TOP+CANVAS_TOP));
	            scrollContentPanel.setPreferredSize( new Dimension(5,5) );
	            /*[documentWindow setFrame:CGRectMake(0, screenFrame.origin.y, CANVAS_LEFT+320+CANVAS_TOP, 568+CANVAS_TOP+CANVAS_TOP+20) display:YES animate:NO];
	            [documentScrollView setFrame:CGRectMake(0, 0, documentView.frame.size.width, documentView.frame.size.height)];
	            [documentScrollView.documentView setFrameSize:documentScrollView.contentSize];
	            [canvasOuterView setFrame:CGRectMake(CANVAS_LEFT,documentView.frame.size.height-568-CANVAS_TOP, 320, 568)];*/
	            
	        }
	        else{//landscape
	        	frame.getContentPane().setPreferredSize(new Dimension(CANVAS_LEFT+568+CANVAS_TOP, 500));
	            frame.pack();
	            canvasOuterPanel.setBounds(new Rectangle(CANVAS_LEFT,CANVAS_TOP, 568, 320));
	            scrollPane.setSize(new Dimension(CANVAS_LEFT+568+CANVAS_TOP, 500));
	            scrollContentPanel.setPreferredSize( new Dimension(5,5) );
	            /*[documentWindow setFrame:CGRectMake(0, screenFrame.origin.y, CANVAS_LEFT+568+CANVAS_TOP, 500) display:YES animate:NO];
	            
	            [documentScrollView setFrame:CGRectMake(0, 0, documentView.frame.size.width, documentView.frame.size.height)];
	            [documentScrollView.documentView setFrameSize:documentScrollView.contentSize];
	            [canvasOuterView setFrame:CGRectMake(CANVAS_LEFT,documentView.frame.size.height-320-CANVAS_TOP, 568, 320)];*/
	        }
	    }
	    else if(controller.documentModel.canvasType==DocumentModel.CanvasType.canvasTypeIPad){//ipad
	    	frame.setLocation(0,0);
	    	if(controller.documentModel.isOrientationLandscape==false){//portrait 
	    		frame.getContentPane().setPreferredSize(new Dimension(CANVAS_LEFT+768+CANVAS_TOP+CANVAS_TOP+scrollPane.getVerticalScrollBar().getWidth(), (int)height-60));//TODO smaller of height and 1024
	            frame.pack();
	            canvasOuterPanel.setBounds(new Rectangle(CANVAS_LEFT,CANVAS_TOP, 768, 1024));
	            scrollPane.setSize(new Dimension(CANVAS_LEFT+768+CANVAS_TOP+CANVAS_TOP+scrollPane.getVerticalScrollBar().getWidth(), (int)height-60-menuBar.getHeight()) );
	            scrollContentPanel.setPreferredSize( new Dimension(CANVAS_LEFT+768+CANVAS_TOP+CANVAS_TOP, 1024+CANVAS_TOP+CANVAS_TOP ) ) ;
	            
	           
	        }
	        else{//landscape
	        	frame.getContentPane().setPreferredSize(new Dimension(CANVAS_LEFT+1024+CANVAS_TOP, 768+CANVAS_TOP+CANVAS_TOP+menuBar.getHeight()));//TODO smaller of height and 1024
	            frame.pack();
	            canvasOuterPanel.setBounds(new Rectangle(CANVAS_LEFT,CANVAS_TOP, 1024, 768));
	            scrollPane.setSize(new Dimension(CANVAS_LEFT+1024+CANVAS_TOP, 768+CANVAS_TOP+CANVAS_TOP) );
	            scrollContentPanel.setPreferredSize(new Dimension(5, 5 ) );//tigher than ness, will resize...
	           
	        }
	    } else { //android 7 inch
	    	frame.setLocation(0,0);
	    	if(controller.documentModel.isOrientationLandscape==false){//portrait 
	    		frame.getContentPane().setPreferredSize(new Dimension(CANVAS_LEFT+600+CANVAS_TOP+CANVAS_TOP+scrollPane.getVerticalScrollBar().getWidth(), (int)height-60));
	            frame.pack();
	            canvasOuterPanel.setBounds(new Rectangle(CANVAS_LEFT,CANVAS_TOP, 600, 912));
	            scrollPane.setSize(new Dimension(CANVAS_LEFT+600+CANVAS_TOP+CANVAS_TOP+scrollPane.getVerticalScrollBar().getWidth(), (int)height-60-menuBar.getHeight()) );
	            scrollContentPanel.setPreferredSize( new Dimension(CANVAS_LEFT+600+CANVAS_TOP+CANVAS_TOP, 912+CANVAS_TOP+CANVAS_TOP ) ) ;
	            
	        }
	        else{//landscape
	        	frame.getContentPane().setPreferredSize(new Dimension(CANVAS_LEFT+960+CANVAS_TOP, 552+CANVAS_TOP+CANVAS_TOP+menuBar.getHeight()));//TODO smaller of height and 1024
	            frame.pack();
	            canvasOuterPanel.setBounds(new Rectangle(CANVAS_LEFT,CANVAS_TOP, 960, 552));
	            scrollPane.setSize(new Dimension(CANVAS_LEFT+960+CANVAS_TOP, 552+CANVAS_TOP+CANVAS_TOP) );
	            scrollContentPanel.setPreferredSize(new Dimension(5, 5 ) );//tigher than ness, will resize...
	           
	        }
	    }
	    
	    //this has to be done after setting outerview, it doesn't move with the change of outerview!
	    canvasPanel.setCanvasType(controller.documentModel.canvasType);
	    canvasPanel.setIsOrientationLandscape(controller.documentModel.isOrientationLandscape);
		
	}

	

	//focus
	public void focusGained(FocusEvent e) {
		//System.out.print("Focus gained");
    }

    public void focusLost(FocusEvent e) {
    	//System.out.print("Focus lost");
    	if(e.getComponent()==this.docFileTextField && this.docFileTextField.dirty==true){
    		this.docFileTextField.dirty=false;
    		updateDocPdFile();
    	}
    	if(e.getComponent()==this.docPageCountField && this.docPageCountField.dirty==true){
    		//System.out.print("\npagecount focuslost and dirty");
    		this.docPageCountField.dirty=false;
    		updatePageCount();
    	}
    	if(e.getComponent()==this.docStartPageField && this.docStartPageField.dirty==true){
    		this.docStartPageField.dirty=false;
    		updateStartPage();
    	}
    	if(e.getComponent()==this.portTextField && this.portTextField.dirty==true){
    		this.portTextField.dirty=false;
    		updatePort();
    	}
    	if(e.getComponent()==this.propAddressTextField && this.propAddressTextField.dirty==true){
    		this.propAddressTextField.dirty=false;
    		updateAddress();
    	}
    	if(e.getComponent()==this.propVarSliderRangeTextField && this.propVarSliderRangeTextField.dirty==true){
    		this.propVarSliderRangeTextField.dirty=false;
    		updateSliderRange();
    	}
    	if(e.getComponent()==this.propVarKnobRangeTextField && this.propVarKnobRangeTextField.dirty==true){
    		this.propVarKnobRangeTextField.dirty=false;
    		updateKnobRange();
    	}
    	if(e.getComponent()==this.propLabelSizeTextField && this.propLabelSizeTextField.dirty==true){
    		this.propLabelSizeTextField.dirty=false;
    		updateLabelSize();
    	}
    	if(e.getComponent()==this.propGridDimXTextField && this.propGridDimXTextField.dirty==true){
    		this.propGridDimXTextField.dirty=false;
    		updateGridX();
    	}
    	if(e.getComponent()==this.propGridDimYTextField && this.propGridDimYTextField.dirty==true){
    		this.propGridDimYTextField.dirty=false;
    		updateGridY();
    	}
    	if(e.getComponent()==this.propGridBorderThicknessTextField && this.propGridBorderThicknessTextField.dirty==true){
    		this.propGridBorderThicknessTextField.dirty=false;
    		updateGridBorderThickness();
    	}
    	if(e.getComponent()==this.propGridCellPaddingTextField && this.propGridCellPaddingTextField.dirty==true){
    		this.propGridCellPaddingTextField.dirty=false;
    		updateGridCellPadding();
    	}
    	if(e.getComponent()==this.propPanelFileTextField && this.propPanelFileTextField.dirty==true){
    		this.propPanelFileTextField.dirty=false;
    		updatePanelFile();
    	}
    	if(e.getComponent()==this.propMultiCountTextField && this.propMultiCountTextField.dirty==true){
    		this.propMultiCountTextField.dirty=false;
    		updateMultiSliderCount();
    	}
    	if(e.getComponent()==this.propToggleThicknessTextField && this.propToggleThicknessTextField.dirty==true){
    		this.propToggleThicknessTextField.dirty=false;
    		updateToggleThickness();
    	}
    	if(e.getComponent()==this.snapToGridXTextField ){
    		updateSnapToGridXField();
    	}
    	if(e.getComponent()==this.snapToGridYTextField){
    		updateSnapToGridYField();
    	}
    }
    
    //colorwell
    public void colorWellChanged(ColorWell inWell, Color newColor){
		if(inWell==docBGColorWell){
			controller.setDocBackgroundColor(newColor);
		}
		else if(inWell == propColorWell ){
			controller.propColorWellChanged(newColor);
		}
		else if(inWell == propHighlightColorWell ){
			controller.propHighlightColorWellChanged(newColor);
		}
		else if(inWell == propVarKnobIndicatorColorWell ){
			MMPKnob currKnob = (MMPKnob)controller.currentSingleSelection;
			currKnob.setIndicatorColor(newColor);
		} 
		else if (inWell == propTableSelectionColorWell){
			MMPTable currTable = (MMPTable)controller.currentSingleSelection;
			currTable.setSelectionColor(newColor);
		}
	}


class MMPKeyAction extends AbstractAction {

    private String cmd;

    public MMPKeyAction(String cmd) {
        this.cmd = cmd;
    }

    @Override
    public void actionPerformed(ActionEvent e) {
        if (cmd.equalsIgnoreCase("delete")) {
            System.out.println("delete");
            controller.deletePressed();
        }
        /*if (cmd.equalsIgnoreCase("copy")) {
            System.out.println("copy");
            //controller.deletePressed();
        }
        if (cmd.equalsIgnoreCase("paste")) {
            System.out.println("paste");
            //controller.deletePressed();
        }*/
        
        /*} else if (cmd.equalsIgnoreCase("RightArrow")) {
            System.out.println("The right arrow was pressed!");
        } else if (cmd.equalsIgnoreCase("UpArrow")) {
            System.out.println("The up arrow was pressed!");
        } else if (cmd.equalsIgnoreCase("DownArrow")) {
            System.out.println("The down arrow was pressed!");
        }*/
    }
}


@Override
public void changedUpdate(DocumentEvent arg0) {
	// TODO Auto-generated method stub
	//System.out.print("changed: "+propLabelTextField.getText());
}

@Override
public void insertUpdate(DocumentEvent arg0) {
	// TODO Auto-generated method stub
	//System.out.print("insert: "+propLabelTextField.getText());
	Document fromDoc = arg0.getDocument();
	if(fromDoc == this.propLabelTextField.getDocument()){
		MMPLabel currLabel = (MMPLabel)controller.currentSingleSelection;
		currLabel.setStringValue(propLabelTextField.getText());
	}
	else if (fromDoc == this.propMenuTitleTextField.getDocument()){
		MMPMenu currMenu = (MMPMenu)controller.currentSingleSelection;
		currMenu.setTitleString(propMenuTitleTextField.getText());
	}
}

@Override
public void removeUpdate(DocumentEvent arg0) {
	// TODO Auto-generated method stub
	Document fromDoc = arg0.getDocument();
	if(fromDoc == this.propLabelTextField.getDocument()){
		MMPLabel currLabel = (MMPLabel)controller.currentSingleSelection;
		currLabel.setStringValue(propLabelTextField.getText());
	}
	else if (fromDoc == this.propMenuTitleTextField.getDocument()){
		MMPMenu currMenu = (MMPMenu)controller.currentSingleSelection;
		currMenu.setTitleString(propMenuTitleTextField.getText());
	}
}

	void fillFontPop(){
		List<Map> fontArray = MMPController.fontArray;
			
		for(Map currMap: fontArray){
			if(currMap.get("family")!=null){
				String fontName = (String)currMap.get("family");
				propLabelFontBox.addItem(fontName);
			}
		}
		
		List<String> androidFontNameArray = MMPController.androidFontNameArray;
		
		for(String currFontName: androidFontNameArray){
			propLabelAndroidFontTypeBox.addItem(currFontName);	
		}
		
	}
	
	void populateFont(){
		List<Map> fontArray = MMPController.fontArray;
    	Map<String, Object> currFamilyMap = fontArray.get(propLabelFontBox.getSelectedIndex());
    	
    	String currFamily = (String)currFamilyMap.get("family");
    	List<String> typeList = (List<String>)currFamilyMap.get("types");
    	propLabelFontTypeBox.removeAllItems();
    	for(String currType: typeList){
    		propLabelFontTypeBox.addItem(currType);
    	}
	}
}

/*class ComboBoxRenderer extends JLabel implements ListCellRenderer {
private Font uhOhFont;

	public ComboBoxRenderer() {
		setOpaque(true);
		setHorizontalAlignment(CENTER);
		setVerticalAlignment(CENTER);
	}

	public Component getListCellRendererComponent(
                JList list,
                Object value,
                int index,
                boolean isSelected,
                boolean cellHasFocus) {
		//Get the selected index. (The index param isn't
		//always valid, so just use the value.)
		int selectedIndex = ((Integer)value).intValue();

		if (isSelected) {
			setBackground(list.getSelectionBackground());
			setForeground(list.getSelectionForeground());
		} else {
			setBackground(list.getBackground());
			setForeground(list.getForeground());
		}

//Set the icon and text.  If icon was null, say so.
		ImageIcon icon = images[selectedIndex];
		String pet = petStrings[selectedIndex];
		setIcon(icon);
		if (icon != null) {
			setText(pet);
			setFont(list.getFont());
		} else {
			setUhOhText(pet + " (no image available)",
					list.getFont());
		}

		return this;
}

//Set the font and text when no image was found.
protected void setUhOhText(String uhOhText, Font normalFont) {
if (uhOhFont == null) { //lazily create this font
uhOhFont = normalFont.deriveFont(Font.ITALIC);
}
setFont(uhOhFont);
setText(uhOhText);
}
}*/



