package com.iglesiaintermedia.MobMuPlatEditor;
import java.net.InetAddress;
import java.net.SocketException;
import java.net.URL;
import java.net.UnknownHostException;
import java.util.*;
import java.util.prefs.Preferences;

import com.illposed.osc.*;
import com.iglesiaintermedia.MobMuPlatEditor.DocumentModel.CanvasType;
import com.iglesiaintermedia.MobMuPlatEditor.controls.*;
import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.google.gson.JsonElement;
import com.google.gson.JsonParser;

import java.awt.Color;
import java.awt.Component;
import java.awt.EventQueue;
import java.awt.Font;
import java.awt.FontFormatException;
import java.awt.GraphicsEnvironment;
import java.awt.Point;
import java.awt.Rectangle;
import java.io.*;

import javax.swing.JComponent;
import javax.swing.JOptionPane;
import javax.swing.SwingUtilities;

 

public class MMPController {
	//ONE stataic
	static OSCPortIn receiver;
	static ArrayList<MMPController> controllerArrayList;
	static OSCPortOut sender;
	static List<Map> fontArray;
	static List<String> androidFontFileArray;
	public static Map<String, String> androidFontFileToNameMap;
	
	//defines
	final static int DEFAULT_PORT_NUMBER=54321;
	final static int CANVAS_LEFT=250;
	final static int CANVAS_TOP=8;
	final static int LOG_LINES = 12;
	
	boolean isEditing;
	int currentPageIndex;
	public boolean dirtyBit;
	
	public MMPWindow windowDelegate;
	public DocumentModel documentModel;
	MMPControl currentSingleSelection;
	public String filePath;
	public String filename;
	
	ArrayList<String> textLineArray;
	
	//layout grid
	public boolean snapToGridEnabled;
	public int snapToGridXVal;
	public int snapToGridYVal;
	
		
	static OSCListener oscListener = new OSCListener() {
        public void acceptMessage(java.util.Date time, OSCMessage message) {
    		/*System.out.println("Message received2! instance"+ this);
    		System.out.println(message.getAddress());
    		Object[] args = message.getArguments();
    		for(int i=0;i<args.length;i++)
    			System.out.print(" "+args[i]);//type Integer, Float*/
        	for(MMPController controller:controllerArrayList){
        		controller.receiveMessage(message);
        	}
        }
       };
	
	public MMPController(){
		super();
		documentModel = new DocumentModel();
		
		//layotu guide values from preferences
		Preferences prefs = Preferences.userNodeForPackage(MMPWindow.class);
		snapToGridXVal = prefs.getInt("snapToGridXVal", 20);
		snapToGridYVal = prefs.getInt("snapToGridYVal", 20);
		snapToGridEnabled = prefs.getBoolean("snapToGridXnabled", false);
				
		//osc out
		
		if(MMPController.sender==null){
			try{
			MMPController.sender = new OSCPortOut(InetAddress.getLocalHost(), 54300);	
			}catch(UnknownHostException e){
				System.out.print("unknown host exception");
			}catch(SocketException e){
				System.out.print("sender socket exception");	
				JOptionPane.showMessageDialog(null, "Unable to create OSC sender on port 54300. \nI won't be able to send messages to PD. \nPerhaps another application, or instance of this editor, is on this port.");			
			}
		}
		if(MMPController.receiver==null){
			//System.out.print("\ncreate receiver");
				try{
				MMPController.receiver = new OSCPortIn(54310);
				MMPController.receiver.addListener(".*", oscListener);
				MMPController.receiver.startListening();
				}catch(SocketException e){
					System.out.print("receiver socket exception");	
					JOptionPane.showMessageDialog(null, "Unable to create OSC receiver on port 54310. \nI won't be able to receive messages from PD. \nPerhaps another application, or instance of this editor, is on this port.");
				}
				
				MMPController.controllerArrayList = new ArrayList<MMPController>();
				
			}
		
			
		if(MMPController.fontArray==null){
				System.out.print("\nat "+new File(".").getAbsolutePath());
				try{
				//BufferedReader reader = new BufferedReader( new FileReader (new File("uifontlist.txt")));
				URL url = this.getClass().getResource("uifontlist.txt");
				System.out.print("\nread "+url.getPath());
				//Reader justreader = (new InputStreamReader(stream));
				BufferedReader reader = new BufferedReader(new InputStreamReader(url.openStream()));
				
				String         line = null;
    		    StringBuilder  stringBuilder = new StringBuilder();
    		    //String         ls = System.getProperty("line.separator");

    		  
    		    while( ( line = reader.readLine() ) != null ) {
    		        stringBuilder.append( line );
    		      //  stringBuilder.append( ls );
    		    }

    		   //System.out.print(stringBuilder.toString());
    		    //PARSE - UGLY!
    		    JsonParser parser = new JsonParser();
    		    //JsonObject topDict = parser.parse(stringBuilder.toString()).getAsJsonObject();//top dict
    		    JsonArray fontJsonArray = parser.parse(stringBuilder.toString()).getAsJsonArray();//top array of dict
				
    		    fontArray = new ArrayList<Map>();
    		    for(JsonElement jsonMap: fontJsonArray){
    		    	//System.out.print("\n"+((JsonObject)jsonMap).get("family") );
    		    	
    		    	Map<String, Object> newMap = new HashMap<String, Object>();
    		    	newMap.put("family", ((JsonObject)jsonMap).get("family").getAsString()  );
    		    	
    		    	JsonArray typesJsonArray = ((JsonObject)jsonMap).get("types").getAsJsonArray();
    		    	List<String> typeList = new ArrayList<String>();
    		    	for(JsonElement jsonTypeName: typesJsonArray){
    		    		typeList.add(jsonTypeName.getAsString());
    		    	}
    		    	
    		    	newMap.put("types", typeList);
    		    	fontArray.add(newMap);
    		    }
    		    Collections.sort(fontArray, new FontArrayComparator());
    		    Map defMap = new HashMap<String, Object>();
    		    defMap.put("family", "Default");
    		    defMap.put("types", new ArrayList<String>());//empty
    		    fontArray.add(defMap);
    		    
    		    //DUMMY
    		 /*   Map defMap2 = new HashMap<String, Object>();
    		    defMap2.put("family", "Dummy");
    		    ArrayList<String> defMap2Strings =  new ArrayList<String>(); 
    		    defMap2Strings.add("dummy one");
    		    defMap2Strings.add("dummy two");
    		    defMap2.put("types", defMap2Strings);//
    		    fontArray.add(defMap2);*/
    		    //print
    		    /*for(Map map: fontArray){
    		    	System.out.print("\n"+map.get("family"));
				}*/
				}
				catch(FileNotFoundException e){}
				catch(IOException e){}
			}
		if (androidFontFileArray == null) {
			//totally whack, when reading fonts from a jar, versus from file (in eclipse), the font names are different!!!
			// from eclipse it is "Roboto-Regular", from jar it is "Roboto Regular".
			// So we derive the font name on font creation from file name. ugh.
			androidFontFileArray = Arrays.asList(
					"Roboto-Regular",
                    "Roboto-Bold",
                    "Roboto-Italic",
                    "Roboto-BoldItalic",
                    "Roboto-Light",
                    "Roboto-LightItalic",
                    "Roboto-Thin",
                    "Roboto-ThinItalic",
                    "RobotoCondensed-Regular",
                    "RobotoCondensed-Bold",
                    "RobotoCondensed-Italic",
                    "RobotoCondensed-BoldItalic");
			//install fonts 
			//androidFontNameArray = new ArrayList<String>();
			androidFontFileToNameMap = new HashMap<String, String>();
			for (String fontFilename : androidFontFileArray) {
				try {
					InputStream is = this.getClass().getResourceAsStream("androidfonts/"+fontFilename+".ttf");
					GraphicsEnvironment ge = 
							GraphicsEnvironment.getLocalGraphicsEnvironment();
					Font f = Font.createFont(Font.TRUETYPE_FONT, is);
					ge.registerFont(f);
					String fontName = f.getName();
					androidFontFileToNameMap.put(fontFilename, fontName);
				} catch (IOException e) {
					//Handle exception
					System.out.print("NO FONT");
				} catch (FontFormatException e) {
					System.out.print("NO FONT");
				}
			}
		}
		
		
		System.out.print("\nadd controller instance to arraylist "+ this);
		MMPController.controllerArrayList.add(this);
			
		
		textLineArray = new ArrayList<String>();
		
		
	}
	
	public void setIsEditing(boolean inIsEditing){
		isEditing=inIsEditing;
	    if(!isEditing){
	        for(MMPControl control :documentModel.controlArray){
	            if (control.isSelected) control.setIsSelected(false);
	        }
	        //self clearSelection];
	    }
	}
	
	public boolean isEditing(){
		return isEditing;
	}
	
	void writeJSON(){
		Gson gson = new Gson();
		Map<String,Object> data = new HashMap<String,Object>();
		data.put("status", "1");
		data.put("message", "success!");
		String content = gson.toJson(data);
		//System.out.println(content);
		try{
		File file = new File("test/filename.txt");
		 
		// if file doesnt exists, then create it
		//if (!file.exists()) {
			file.createNewFile();
		//}

		FileWriter fw = new FileWriter(file.getAbsoluteFile());
		BufferedWriter bw = new BufferedWriter(fw);
		bw.write(content);
		bw.close();
	} catch (IOException e) {
		e.printStackTrace();
	}

	}
	
	
	
	
	public void loadFromModel(){
	    
		 ListIterator<MMPControl> li = this.documentModel.controlArray.listIterator(documentModel.controlArray.size());
		 // Iterate in reverse.
		 while(li.hasPrevious()) {
			 MMPControl control = li.previous();
		   control.editingDelegate=this;
	       windowDelegate.canvasPanel.add(control);
	       //System.out.print("+");
		 }
		
		Set<String> addedTableNamesSet = new HashSet<String>();
	    for(MMPControl control : documentModel.controlArray){
	    	if(control instanceof MMPPanel){
	    		if(((MMPPanel) control).imagePath!=null){
	    			((MMPPanel) control).loadImage();
	    		}
	    	}
	    	 //table stuff
	    	if(control instanceof MMPTable){
	          // use set to quash multiple loads of same table/address
	          if (!addedTableNamesSet.contains(control.getAddress())) {
	            ((MMPTable)control).loadTable();
	            addedTableNamesSet.add(control.getAddress());
	          }
	    	}
	    }
		
	    
	    //UPDATE APPLICATION FIELDS
	    //pdfile
	    if(documentModel.pdFile!=null)
	        windowDelegate.docFileTextField.setText(documentModel.pdFile);//[self.docFileTextField setStringValue:[documentModel pdFile]];
	    
	    //orient and canvas size
	    windowDelegate.updateWindowAndCanvas();
	    
	    windowDelegate.docCanvasTypeMenu.removeActionListener(windowDelegate.docCanvasTypeMenu.getActionListeners()[0]);
        if(documentModel.canvasType==CanvasType.canvasTypeTallPhone) windowDelegate.docCanvasTypeMenu.setSelectedIndex(1);
        else if(documentModel.canvasType==CanvasType.canvasTypeWideTablet) windowDelegate.docCanvasTypeMenu.setSelectedIndex(2);
        else windowDelegate.docCanvasTypeMenu.setSelectedIndex(0);
	    windowDelegate.docCanvasTypeMenu.addActionListener(windowDelegate);
	    
	    windowDelegate.docOrientationMenu.removeActionListener(windowDelegate.docOrientationMenu.getActionListeners()[0]);
        if(documentModel.isOrientationLandscape==true) windowDelegate.docOrientationMenu.setSelectedIndex(1);
        else windowDelegate.docOrientationMenu.setSelectedIndex(0);
        windowDelegate.docOrientationMenu.addActionListener(windowDelegate);
	    

        //doc bg color
	    windowDelegate.canvasPanel.setBackground(documentModel.backgroundColor);// [canvasView setBgColor:[documentModel backgroundColor]];
	    windowDelegate.docBGColorWell.setColor(documentModel.backgroundColor);// [self.docBGColorWell setColor:[documentModel backgroundColor]];
	    
	    //pages
	    windowDelegate.docPageCountField.setText(Integer.toString(documentModel.pageCount));// ;) [self.docPageCountField setIntValue:[documentModel pageCount]];
	    windowDelegate.canvasPanel.setPageCount(documentModel.pageCount);
	    windowDelegate.docStartPageField.setText(Integer.toString(documentModel.startPageIndex+1));// ;) [self.docPageCountField setIntValue:[documentModel pageCount]];
	    //windowDelegate.canvasPanel.setPageViewIndex(documentModel.startPageIndex) ;
	    setCurrentPage(documentModel.startPageIndex);
	  
	}
	
	void pruneControls(){
		//System.out.print("\nprune");
		ArrayList<MMPControl> selectedControls = new ArrayList<MMPControl>();
		for(MMPControl control : documentModel.controlArray){
			if(control.getX()>windowDelegate.canvasPanel.getWidth()){
				//System.out.print("-found");
				selectedControls.add(control);
			}
		}
		
		for(MMPControl control : selectedControls){
			deleteControl(control);
		}
	}
	
	
	void pasteControlHelper(MMPControl newControl){
		dirtyBit=true;
		Rectangle currBounds = newControl.getBounds();
 	   	newControl.setBounds(currBounds.x+20, currBounds.y+20,currBounds.width, currBounds.height );
		 newControl.editingDelegate=this;
		 documentModel.controlArray.add(0,newControl);
		 windowDelegate.canvasPanel.add(newControl);
		 windowDelegate.canvasPanel.setComponentZOrder(newControl, 0);
		 
		 if(newControl instanceof MMPPanel){
			 if(((MMPPanel) newControl).imagePath!=null){
				 ((MMPPanel) newControl).loadImage();
			 }
		 }
		 
		 if(newControl instanceof MMPTable){
			 ((MMPTable)newControl).loadTable();
		 }
		 
		 newControl.setIsSelected(true);
		    //controlEditClicked(newControl, false, false);
		 System.out.print("ADDED");
		 
	}
	
	//run after the individual "addSlider", "addPanel", etc methods
	void addControlHelper(MMPControl newControl){
	    dirtyBit=true;
	    newControl.editingDelegate=this;
	    documentModel.controlArray.add(newControl);//
	    windowDelegate.canvasPanel.add(newControl);
	    windowDelegate.canvasPanel.setComponentZOrder(newControl, 0);
	    newControl.setColor(windowDelegate.propColorWell.colorPanel.getBackground());
	    newControl.setHighlightColor(windowDelegate.propHighlightColorWell.colorPanel.getBackground());
	    
	    //[newControl setColor:[self.propColorWell color] ];
	    //[newControl setHighlightColor:[self.propHighlightColorWell color] ];
	    
	    //just for redo
	    //[newControl hackRefresh];
	    
	    //select
	    newControl.setIsSelected(true);
	    controlEditClicked(newControl, false, false);
	    
	    //[[self undoManager] registerUndoWithTarget:self selector:@selector(deleteControl:) object:newControl ];
	    
	}

	
	public void addSlider(){
	    MMPSlider newControl = new MMPSlider(new Rectangle(-windowDelegate.canvasPanel.getX(),0,40,160 ));//[[MMPSlider alloc]initWithFrame:CGRectMake(-canvasView.frame.origin.x, 0, 40, 160)];
	    //[self addControlHelper:newControl];
	    addControlHelper(newControl);
	}
	
	public void addKnob(){
	    MMPKnob newControl = new MMPKnob(new Rectangle(-windowDelegate.canvasPanel.getX(),0,100,100 ));//[[MMPSlider alloc]initWithFrame:CGRectMake(-canvasView.frame.origin.x, 0, 40, 160)];
	    //[self addControlHelper:newControl];
	    addControlHelper(newControl);
	}
	public void addXYSlider(){
	    MMPXYSlider newControl = new MMPXYSlider(new Rectangle(-windowDelegate.canvasPanel.getX(),0,100,100 ));//[[MMPSlider alloc]initWithFrame:CGRectMake(-canvasView.frame.origin.x, 0, 40, 160)];
	    addControlHelper(newControl);
	}
	public void addLabel(){
	    MMPLabel newControl = new MMPLabel(new Rectangle(-windowDelegate.canvasPanel.getX(),0,200,50 ));//[[MMPSlider alloc]initWithFrame:CGRectMake(-canvasView.frame.origin.x, 0, 40, 160)];
	    addControlHelper(newControl);
	}
	public void addButton(){
		 MMPButton newControl = new MMPButton(new Rectangle(-windowDelegate.canvasPanel.getX(),0,100,100 ));//[[MMPSlider alloc]initWithFrame:CGRectMake(-canvasView.frame.origin.x, 0, 40, 160)];
		    addControlHelper(newControl);
	}
	public void addToggle(){
		MMPToggle newControl = new MMPToggle(new Rectangle(-windowDelegate.canvasPanel.getX(),0,100,100 ));//[[MMPSlider alloc]initWithFrame:CGRectMake(-canvasView.frame.origin.x, 0, 40, 160)];
	    addControlHelper(newControl);
	}
	public void addGrid(){
		MMPGrid newControl = new MMPGrid(new Rectangle(-windowDelegate.canvasPanel.getX(),0,100,100 ));//[[MMPSlider alloc]initWithFrame:CGRectMake(-canvasView.frame.origin.x, 0, 40, 160)];
	    addControlHelper(newControl);
		
	}
	public void addPanel(){
		MMPPanel newControl = new MMPPanel(new Rectangle(-windowDelegate.canvasPanel.getX(),0,100,100 ));//[[MMPSlider alloc]initWithFrame:CGRectMake(-canvasView.frame.origin.x, 0, 40, 160)];
	    addControlHelper(newControl);
	}
	public void addMultiSlider(){
		MMPMultiSlider newControl = new MMPMultiSlider(new Rectangle(-windowDelegate.canvasPanel.getX(),0,100,100 ));//[[MMPSlider alloc]initWithFrame:CGRectMake(-canvasView.frame.origin.x, 0, 40, 160)];
	    addControlHelper(newControl);
	}
	public void addLCD(){
		MMPLCD newControl = new MMPLCD(new Rectangle(-windowDelegate.canvasPanel.getX(),0,100,100 ));//[[MMPSlider alloc]initWithFrame:CGRectMake(-canvasView.frame.origin.x, 0, 40, 160)];
	    addControlHelper(newControl);
	}
	public void addMultiTouch(){
		MMPMultiTouch newControl = new MMPMultiTouch(new Rectangle(-windowDelegate.canvasPanel.getX(),0,100,100 ));
	    addControlHelper(newControl);
	}
	public void addMenu(){
		MMPMenu newControl = new MMPMenu(new Rectangle(-windowDelegate.canvasPanel.getX(),0,200,40 ));
	    addControlHelper(newControl);
	}
	public void addTable(){
		MMPTable newControl = new MMPTable(new Rectangle(-windowDelegate.canvasPanel.getX(),0,100,100 ));
	    addControlHelper(newControl);
	    newControl.loadTable();
	}
	
	public void deleteControl(MMPControl control){
		dirtyBit=true;
		windowDelegate.canvasPanel.remove(control);
		documentModel.controlArray.remove(control);
		if(control==currentSingleSelection)clearSelection();
	}
	
	public void deletePressed(){
		//System.out.print("\ndeletepressed");
		ArrayList<MMPControl> selectedControls = new ArrayList<MMPControl>();
		for(MMPControl control : documentModel.controlArray){
			if(control.isSelected==true) selectedControls.add(control);
		}
		
		for(MMPControl control : selectedControls){
			deleteControl(control);
		}
		 /*NSMutableArray* selectedControls = [[NSMutableArray alloc] init];
		    for(MMPControl* control in [documentModel controlArray]){//printf(" %d", currControl);
		        if([control isSelected]) [selectedControls addObject:control];
		    }

		    for(MMPControl* control in selectedControls){
		        [self deleteControl:control];
		    }
		    
		    [self clearSelection];
		   */ 
			clearSelection();
		    windowDelegate.canvasPanel.revalidate();
		    windowDelegate.canvasPanel.repaint();
	}
	
	public void sendMessage(String address, Object[] args){
		//System.out.print("\nsending...");
		try{
		
		/*Object args[] = new Object[2];
		args[0] = new Integer(3);
		args[1] = "hello";
		OSCMessage msg = new OSCMessage("/sayhello", args);*/
			OSCMessage msg = new OSCMessage(address, args);
		
		String newString = "[out] "+address+" ";
		for(Object ob: args){
			if(ob instanceof String) newString = newString+(String)ob;
    		else if(ob instanceof Float) newString+=(String.format("%.3f",((Float)(ob)).floatValue()) );
    		else if(ob instanceof Integer) newString+=(String.format("%d",((Integer)(ob)).intValue()) );
    		newString = newString+" ";
		}
		log(newString);
		
		MMPController.sender.send(msg);
		}
		 catch (Exception e) {
			 System.out.print("Couldn't send");
		 }
	}
	
	
	
	public void receiveMessage(final OSCMessage message) {
		SwingUtilities.invokeLater(new Runnable() {
		    public void run() {
		      // Here, we can safely update the GUI
		      // because we'll be called from the
		      // event dispatch thread
		      
		    	
		    
		
		
		Object[] args = message.getArguments();
		ArrayList<Object> newList = new ArrayList<Object>();
		for(Object ob : args){
			newList.add(ob);
		}
		
		//log
		String newString = "[in] "+message.getAddress()+" ";
		for(Object ob: args){
			if(ob instanceof String) newString = newString+(String)ob;
			else if(ob instanceof Float) newString+=(String.format("%.3f",((Float)(ob)).floatValue()) );
			else if(ob instanceof Integer) newString+=(String.format("%d",((Integer)(ob)).intValue()) );
			newString = newString+" ";
		}
		log(newString);
		
		//to control - now on EDT
		
		//if(newList.size()==1 && ((String)newList.get(0)).equals("/system/tableResponse")){
		if(message.getAddress().equals("/system") && newList.get(0).equals("requestPort")){
			Object[] portArgs = new Object[]{new Integer(documentModel.port)};
			sendMessage("/system/port", portArgs);
		}
		else if(newList.size()==1 && message.getAddress().equals("/system/setPage") && (newList.get(0) instanceof Integer)){
			int page = ((Integer)newList.get(0)).intValue();
			setCurrentPage(page);
		}
		else if(newList.size()>1 && message.getAddress().equals("/system/tableResponse")){
			String address = (String) newList.get(0);
			for(MMPControl control : documentModel.controlArray){
				if((control instanceof MMPTable) && control.getAddress().equals(address)){
					ArrayList<Object> subList = new ArrayList<Object>();//have to manually make, as subList only returns List<E>
					for(int i=1;i<newList.size();i++){
						subList.add(newList.get(i));
					}				
					control.receiveList(subList);
				}
			}
		}
		else {//SEND TO OBJECT!
			for(MMPControl control : documentModel.controlArray){
				if(control.getAddress().equals(message.getAddress())){
					control.receiveList(newList);
				}
			}
		}
		
		//log
		//for(int i=0;i<args.length;i++)
		//System.out.print(" "+args[i]);//type Integer, Float, string
	
	
	
		    }
		  });
		
	}
	
	public void setCurrentPage(int newIndex){    
	    currentPageIndex = newIndex;
	    windowDelegate.canvasPanel.setPageViewIndex(currentPageIndex);
	    windowDelegate.pageIndexLabel.setText("Page "+(currentPageIndex+1)+"/"+documentModel.pageCount);
	    
	   
		Object[] args = new Object[]{new Integer(currentPageIndex)};
		sendMessage("/system/page", args);
		
	}
	
	void clearSelection(){
	    currentSingleSelection=null;
	    for(Component varPanel:windowDelegate.propVarPanel.getComponents())varPanel.setVisible(false); //[self.propVarView setSubviews:[NSArray array]];//clear the control-specific subview
	    windowDelegate.propAddressTextField.setEnabled(false);//[self.propAddressTextField setEnabled:NO];
	    windowDelegate.propAddressTextField.setText("");//[self.propAddressTextField setStringValue:@""];
	}
	
	//crazy hack
	//before: requested focus was causing the textfield's loseFocus method to fire AFTER the new singleselection was set.
	//now: requestfocus to losefocus, then invokelater the rest of the method to make the singleselection assignemnt occur AFTER losefocus completes
	public void controlEditClicked(MMPControl control, boolean withShift, boolean wasAlreadySelected){
		final MMPControl fcontrol = control;
		final boolean fwithShift = withShift;
		final boolean fwas = wasAlreadySelected;
		
		windowDelegate.canvasPanel.requestFocus();
		
		SwingUtilities.invokeLater(new Runnable() {
		    public void run() {
				controlEditClickedHelper( fcontrol,  fwithShift,  fwas);
		    }
		});
	}
	
	public void controlEditClickedHelper(MMPControl control, boolean withShift, boolean wasAlreadySelected){
		//System.out.print("\n CEC is edt? "+EventQueue.isDispatchThread());
		
		if(!withShift && !wasAlreadySelected){
			//System.out.print("CEC");
	        for(MMPControl currControl: documentModel.controlArray){//for(MMPControl* currControl in [documentModel controlArray]){
	            if(!currControl.equals(control)) currControl.setIsSelected(false);
	        }
	    }
		
		//set color wells to control's color
	    windowDelegate.propColorWell.setColor(control.color);
	    windowDelegate.propHighlightColorWell.setColor(control.highlightColor);
	    
	    //if group selection
	    if(withShift==true)clearSelection();
	    //single selection
	    else{
	        //first update the application gui, so that text fields send their values to the previous selection
	        
	        //[documentWindow makeFirstResponder:control];//forces address textfield to lose focus, thus assigning address to whaever was selected before
	        //windowDelegate.canvasPanel.requestFocus();
	        //windowDelegate.loseFocusHack();
	    	
	        
	    	//clear property tab class-specific subview
	    	 for(Component varPanel:windowDelegate.propVarPanel.getComponents())varPanel.setVisible(false);
	        //fill in property tab fields (address, class-specific, etc)
	        windowDelegate.propAddressTextField.setEnabled(true);
	        windowDelegate.propAddressTextField.setText(control.getAddress());
	        
	        if(control instanceof MMPKnob){
	            windowDelegate.propVarKnobPanel.setVisible(true);// [self.propVarView addSubview:self.propKnobView];
	            MMPKnob currKnob = (MMPKnob)control;
	            windowDelegate.propVarKnobRangeTextField.setText(""+currKnob.range);
	            windowDelegate.propVarKnobIndicatorColorWell.setColor(currKnob.indicatorColor);
	           
	        }
	        else if( control instanceof MMPSlider ){
	            windowDelegate.propVarSliderPanel.setVisible(true);//add(windowDelegate.propVarSliderPanel);//  [self.propVarView addSubview:self.propSliderView];
	            MMPSlider currSlider = (MMPSlider)control;
	            windowDelegate.propVarSliderRangeTextField.setText(""+currSlider.range);
	            
	            windowDelegate.propVarSliderOrientationBox.removeActionListener(windowDelegate);
	            if(currSlider.isHorizontal==true)windowDelegate.propVarSliderOrientationBox.setSelectedIndex(1);
	            else windowDelegate.propVarSliderOrientationBox.setSelectedIndex(0);
	            windowDelegate.propVarSliderOrientationBox.addActionListener(windowDelegate);
	            
	            
	        }
	        else if(control instanceof MMPLabel){
	        	windowDelegate.propVarLabelPanel.setVisible(true);
	        	MMPLabel currLabel = (MMPLabel)control;
	        	
	        	windowDelegate.propLabelTextField.getDocument().removeDocumentListener(windowDelegate);
	        	windowDelegate.propLabelTextField.setText(currLabel.stringValue);
	        	windowDelegate.propLabelTextField.getDocument().addDocumentListener(windowDelegate);
	        	
	        	windowDelegate.propLabelSizeTextField.removeActionListener(windowDelegate);
	        	windowDelegate.propLabelSizeTextField.setText(""+currLabel.textSize);
	        	windowDelegate.propLabelSizeTextField.addActionListener(windowDelegate);
	        	
	        	windowDelegate.propLabelFontBox.removeActionListener(windowDelegate);
	        	windowDelegate.propLabelFontBox.setSelectedItem(currLabel.fontFamily);
	            windowDelegate.propLabelFontBox.addActionListener(windowDelegate);
	            
	            windowDelegate.propLabelFontTypeBox.removeActionListener(windowDelegate);
	            windowDelegate.populateFont();
	        	windowDelegate.propLabelFontTypeBox.setSelectedItem(currLabel.fontName);
	            windowDelegate.propLabelFontTypeBox.addActionListener(windowDelegate);
	        	
	           windowDelegate.propLabelAndroidFontTypeBox.removeActionListener(windowDelegate);
	            windowDelegate.propLabelAndroidFontTypeBox.setSelectedItem(currLabel.androidFontFileName);
	            windowDelegate.propLabelAndroidFontTypeBox.addActionListener(windowDelegate);
	            
	        }
	        else if(control instanceof MMPGrid){
	        	windowDelegate.propVarGridPanel.setVisible(true);
	        	MMPGrid currGrid = (MMPGrid)control;
	        	
	        	windowDelegate.propGridDimXTextField.removeActionListener(windowDelegate);
	        	windowDelegate.propGridDimXTextField.setText(""+currGrid.dimX);
	        	windowDelegate.propGridDimXTextField.addActionListener(windowDelegate);
	        	
	        	windowDelegate.propGridDimYTextField.removeActionListener(windowDelegate);
	        	windowDelegate.propGridDimYTextField.setText(""+currGrid.dimY);
	        	windowDelegate.propGridDimYTextField.addActionListener(windowDelegate);
	        	
	        	windowDelegate.propGridBorderThicknessTextField.removeActionListener(windowDelegate);
	        	windowDelegate.propGridBorderThicknessTextField.setText(""+currGrid.borderThickness);
	        	windowDelegate.propGridBorderThicknessTextField.addActionListener(windowDelegate);
	        	
	        	windowDelegate.propGridCellPaddingTextField .removeActionListener(windowDelegate);
	        	windowDelegate.propGridCellPaddingTextField.setText(""+currGrid.cellPadding);
	        	windowDelegate.propGridCellPaddingTextField.addActionListener(windowDelegate);
	        	
	        	windowDelegate.propGridModeBox.removeActionListener(windowDelegate.propGridModeBox.getActionListeners()[0]);
	        	windowDelegate.propGridModeBox.setSelectedIndex(currGrid.getMode());
	            	windowDelegate.propGridModeBox.addActionListener(windowDelegate);
	        	
	        }
	        else if(control instanceof MMPPanel){
	        	windowDelegate.propVarPanelPanel.setVisible(true);
	        	MMPPanel currPanel = (MMPPanel)control;
	        	if(currPanel.imagePath!=null){
	        		windowDelegate.propPanelFileTextField.removeActionListener(windowDelegate);
		        	windowDelegate.propPanelFileTextField.setText(currPanel.imagePath);
		        	windowDelegate.propPanelFileTextField.addActionListener(windowDelegate);
	        	}
	        	windowDelegate.propPanelShouldPassTouchesCheckBox.removeActionListener(windowDelegate);
	        	windowDelegate.propPanelShouldPassTouchesCheckBox.setSelected(currPanel.shouldPassTouches);
	        	windowDelegate.propPanelShouldPassTouchesCheckBox.addActionListener(windowDelegate);
	           
	        }
	        else if(control instanceof MMPMultiSlider){
	        	windowDelegate.propVarMultiSliderPanel.setVisible(true);
	        	MMPMultiSlider currMS = (MMPMultiSlider)control;
        		windowDelegate.propMultiCountTextField.removeActionListener(windowDelegate);
	        	windowDelegate.propMultiCountTextField.setText(""+currMS.range);
	        	windowDelegate.propMultiCountTextField.addActionListener(windowDelegate);
	        	windowDelegate.propMultiOutputModeBox.removeActionListener(windowDelegate.propMultiOutputModeBox.getActionListeners()[0]);
	        	windowDelegate.propMultiOutputModeBox.setSelectedIndex(currMS.outputMode);
	            windowDelegate.propMultiOutputModeBox.addActionListener(windowDelegate);
	        }
	        else if(control instanceof MMPToggle){
	        	windowDelegate.propVarTogglePanel.setVisible(true);
	        	MMPToggle currToggle = (MMPToggle)control;
	        	windowDelegate.propToggleThicknessTextField.removeActionListener(windowDelegate);
	        	windowDelegate.propToggleThicknessTextField.setText(""+currToggle.borderThickness);
	        	windowDelegate.propToggleThicknessTextField.addActionListener(windowDelegate);
	            
	        }
	        else if (control instanceof MMPMenu){
	        	windowDelegate.propVarMenuPanel.setVisible(true);
	        	MMPMenu currMenu = (MMPMenu)control;
	        	windowDelegate.propMenuTitleTextField.getDocument().removeDocumentListener(windowDelegate);
	        	windowDelegate.propMenuTitleTextField.setText(currMenu.titleString);
	        	windowDelegate.propMenuTitleTextField.getDocument().addDocumentListener(windowDelegate);
	        }
	        
	        else if (control instanceof MMPTable){
	        	windowDelegate.propVarTablePanel.setVisible(true);
	        	MMPTable currTable = (MMPTable)control;
	        	// touch mode
	        	windowDelegate.propTableModeBox.removeActionListener(windowDelegate);
	        	windowDelegate.propTableModeBox.setSelectedIndex(currTable.getMode());
	            windowDelegate.propTableModeBox.addActionListener(windowDelegate);
	            // selection color
	            windowDelegate.propTableSelectionColorWell.setColor(currTable.getSelectionColor());
	            // display mode
	            windowDelegate.propTableDisplayModeBox.removeActionListener(windowDelegate);
	        	windowDelegate.propTableDisplayModeBox.setSelectedIndex(currTable.getDisplayMode());
	            windowDelegate.propTableDisplayModeBox.addActionListener(windowDelegate);
	            // range
	            windowDelegate.propTableDisplayRangeLoTextField.removeActionListener(windowDelegate);
	        	windowDelegate.propTableDisplayRangeLoTextField.setText(""+currTable.getDisplayRangeLo());
	        	windowDelegate.propTableDisplayRangeLoTextField.addActionListener(windowDelegate);
	        	windowDelegate.propTableDisplayRangeHiTextField.removeActionListener(windowDelegate);
	        	windowDelegate.propTableDisplayRangeHiTextField.setText(""+currTable.getDisplayRangeHi());
	        	windowDelegate.propTableDisplayRangeHiTextField.addActionListener(windowDelegate);
	            
	        }
	       
	        currentSingleSelection=control;
	    }
	}
	
	public void controlEditMoved(MMPControl control, Point deltaPoint){
		dirtyBit=true;
		for(MMPControl currControl: documentModel.controlArray){//for(MMPControl* currControl in [documentModel controlArray]){
            if(/*!currControl.equals(control) &&*/ currControl.isSelected){
            	currControl.setLocation(currControl.getX()+deltaPoint.x, currControl.getY()+deltaPoint.y);
            }
        }
	}
	
	public void controlEditReleased(MMPControl control, boolean withShift, boolean hadDrag){
		if(hadDrag && snapToGridEnabled==true) {
		    for(MMPControl currControl: documentModel.controlArray){
		      if(currControl.isSelected) {
		        int x = currControl.getX();
		        int y = currControl.getY();
		        x = snapToGridXVal *  (int)(((float)x/snapToGridXVal)+0.5);
		        y = snapToGridYVal * (int)(((float)y/snapToGridYVal)+0.5);
		        currControl.setLocation(x, y);
		      }
		    }
		  }
		
		if(!withShift && !hadDrag){
			for(MMPControl currControl: documentModel.controlArray){//for(MMPControl* currControl in [documentModel controlArray]){
				if(!currControl.equals(control) && currControl.isSelected){
					currControl.setIsSelected(false);
				}
			}
        }
	}
	
	public void snapAllToGrid() {
		for(MMPControl currControl: documentModel.controlArray){
			int x = currControl.getX();
			int y = currControl.getY();
			x = snapToGridXVal *  (int)(((float)x/snapToGridXVal)+0.5);
			y = snapToGridYVal * (int)(((float)y/snapToGridYVal)+0.5);
		    
			int newWidth = currControl.getWidth();
		      int newHeight = currControl.getHeight();
		      newWidth = (int)(snapToGridXVal * Math.floor(((float)newWidth/snapToGridXVal)+0.5));
		      newHeight = (int)(snapToGridYVal * Math.floor(((float)newHeight/snapToGridYVal)+0.5));
		      newWidth = Math.max(newWidth, 40);
		      newHeight = Math.max(newHeight,40);
		     Rectangle newFrame = new Rectangle(x, y, newWidth, newHeight);
		     currControl.setBounds(newFrame);
			
		}
		
	}

	public void canvasClicked(){
		//System.out.print("Canvas Clicked");
		//[documentWindow makeFirstResponder:canvasView];
	    for(MMPControl currControl: documentModel.controlArray){
	        currControl.setIsSelected(false);
	    }
	     clearSelection();
	     windowDelegate.canvasPanel.requestFocus();
	}
	
	public void updateGuide(MMPControl control) {
		if(control==null)windowDelegate.controlGuideLabel.setText("");
		else {
			windowDelegate.controlGuideLabel.setText("x:"+control.getX()+" y:"+control.getY()+" w:"+control.getWidth()+" h:"+control.getHeight());
		}
	}
	
	public void setDocBackgroundColor(Color inColor){
		dirtyBit=true;
		documentModel.backgroundColor = inColor;
		windowDelegate.canvasPanel.setBackground(inColor);
	}
	public Color patchBackgroundColor(){
		return documentModel.backgroundColor;
	}
	
	public void propColorWellChanged(Color newColor	){
		for(MMPControl control:documentModel.controlArray){
			if(control.isSelected){
            //[[self undoManager] registerUndoWithTarget:control selector:@selector(setColorUndoable:) object:[control color]];
            //[[self undoManager] registerUndoWithTarget:self selector:@selector(setPropColorWellColor:) object:[control color]];
				dirtyBit=true;
				control.setColor(newColor);
        	}
		}
    }
	
	public void propHighlightColorWellChanged(Color newColor){
		for(MMPControl control:documentModel.controlArray){
			if(control.isSelected){
			//System.out.print("!");
            //[[self undoManager] registerUndoWithTarget:control selector:@selector(setColorUndoable:) object:[control color]];
            //[[self undoManager] registerUndoWithTarget:self selector:@selector(setPropColorWellColor:) object:[control color]];
				dirtyBit=true;
				control.setHighlightColor(newColor);
        	}
		}
    }
	//do straight from window?
	public void propAddressChanged(String newString){
		//System.out.print("\nprop address "+ newString);
		if(currentSingleSelection!=null){
			dirtyBit=true;
			currentSingleSelection.setAddress(newString);
		}
	}
	
	public void log(String logString){
		//System.out.print("log on edt? "+SwingUtilities.isEventDispatchThread());
		textLineArray.add(logString);
		if(textLineArray.size()>LOG_LINES)textLineArray.remove(0);
		//windowDelegate.consoleTextArea.setText("");
		String newString = "";
		for(String substring: textLineArray){
			/*if(textLineArray.indexOf(substring)!=0)*/newString+="\n";
			newString=newString+substring;
		}
		//windowDelegate.consoleTextArea.setText(newString);
		windowDelegate.consoleTextArea.setText("");
		windowDelegate.consoleTextArea.append(newString);
		
		//int pos = newString.length();
		windowDelegate.consoleTextArea.setCaretPosition(windowDelegate.consoleTextArea.getDocument().getLength());
	}
	
	//CACHE
	public static String cachePathWithAddress(String address) {
		String folderPath = System.getProperty("java.io.tmpdir")+"com.iglesiaintermedia.MobMuPlatEditor";
		//System.out.print("folder path:"+folderPath);
		File tempFolderFile = new File(folderPath);
		if(!tempFolderFile.exists()){
			tempFolderFile.mkdir();
		}
		
		if(address==null){
			return folderPath;
		}
		
		if(address.startsWith("/")){
			address = address.substring(1);
		}
		
		return folderPath+File.separator+address;
	}
	
	public static void clearCache(){
		String folderPath = System.getProperty("java.io.tmpdir")+"com.iglesiaintermedia.MobMuPlatEditor";
		File tempFolderFile = new File(folderPath);
		System.out.println("tempFolder:"+tempFolderFile.toString());
		if (tempFolderFile.listFiles() != null) {
			for(File file: tempFolderFile.listFiles()){
				System.out.println("deleting "+file.toString());
				file.delete();
			}
		}
	}
}

class FontArrayComparator implements Comparator<Map> {


    @Override
    public int compare(Map o1, Map o2) {
    	String s1 = (String)o1.get("family");
    	String s2 = (String)o2.get("family");
 
		return s1.compareTo(s2);
    }


}


	


