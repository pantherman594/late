//// diff from analog marked //12// drawNowCircle + drawTime
//// set d24 prop: default 24 or 12h calendar
//// links in properties to help with -analog suffix !!!
//// drawtime switch
//// boldness

//// manifest app id

//// remove any debug variables
//// remove weather localisation property

// Ensure empiric limits: 2000 first event + 600 every other [B:5704/7 venusq, B:3872/5 fr945, exit:3592]


using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Time as Time;
using Toybox.Time.Gregorian as Calendar;
using Toybox as Toy;
using Toybox.Math as Math;
using Toybox.Application as App;

//enum {SUNRISET_NOW=0,SUNRISET_MAX,SUNRISET_NBR}
var meteoColors;

class lateView extends Ui.WatchFace {
	var app;
	hidden var dateForm; hidden var batThreshold = 33;
	hidden var centerX; hidden var centerY; hidden var height;
	hidden var color; hidden var timeColor; hidden var dateColor; hidden var activityColor; hidden var backgroundColor; hidden var dimmedColor;
	hidden var calendarColors; 
	hidden var eventColors = [];
	hidden var gcalColors = [];
	var activity=null; var activityL=null; var activityR=null; var showSunrise = false; var dataLoading = false; var showWeather = false; var percentage = false;
	//hidden var icon=null; hidden var iconL=null; hidden var iconR=null; hidden var sunrs = null; hidden var sunst = null; //hidden var iconNotification;
	hidden var clockTime; 
	hidden var utcOffset; hidden var day = -1;
	//hidden var lonW; hidden var latN; 
	//hidden var sunrise = new [SUNRISET_NBR]; hidden var sunset = new [SUNRISET_NBR];
	hidden var sunrise; hidden var sunset;
	hidden var fontSmall = null; hidden var fontHours = null; hidden var fontMedium = null; hidden var fontCondensed = null;
	hidden var dateY = null; hidden var radius; hidden var circleWidth = 3; hidden var dialSize = 0; hidden var batteryY; hidden var activityY; hidden var messageY; hidden var sunR; //hidden var temp; //hidden var notifY;
	hidden var icons;
	hidden var d24;
	hidden var burnInProtection=0;
	hidden var lowPowerMode = false; hidden var doNotDisturb = false; hidden var sleepMode = false;
	
	hidden var events_list = [];
	var message = false;
	var weatherHourly = [];

	// redraw full watchface
	//hidden var redrawAll=2; 
	//hidden var lastRedrawMin=-1;
	//hidden var dataCount=0;hidden var wakeCount=0;

	function initialize (){
		app = App.getApp();

		if(Ui.loadResource(Rez.Strings.DataLoading).toNumber()==1){ // our code is ready for data loading for this device
			dataLoading = Sys has :ServiceDelegate;	// watch is capable of data loading
		}
		if(!dataLoading){
			if(app.getProperty("activity")==6){
				app.setProperty("activity", 0);
			}
			if(app.getProperty("weather")){
				app.setProperty("weather", false);
			}
		}
		WatchFace.initialize();


		var s=Sys.getDeviceSettings();
		height = s.screenHeight;
		centerX = s.screenWidth >> 1;
		centerY = height >> 1;
		clockTime = Sys.getClockTime();
		

		//Sys.println(["events_list before init", events_list ? events_list.toString().substring(0,30)+"...": ""]);
		var events = Toybox.Application has :Storage ? Toybox.Application.Storage.getValue("events") : app.getProperty("events");
		if(events instanceof Lang.Array){
			events_list = events;
		}

		//Sys.println("init: "+ weatherHourly);
		if(weatherHourly.size()==0){
			var weather = app.getProperty("weatherHourly");
			if(weather instanceof Lang.Array){
				weatherHourly = weather;
			}
		}
		// onBackgroundData({"weather"=>[8, 75, 62, 78, 5.960000, -1, -1, -1, 0, 0.5, 0.99, 4, 4.5, 4.99, -1, 4, 2, 2.5, 2.99, -1, 3, 3.5, 3.99, 4, 2, 6, 6.5, 6.99, 4]});
		d24 = app.getProperty("d24") == 1 ? true : false; // making sure it loads for the first time 
		//Sys.println("init: "+ weatherHourly);
	}

	(:release)
	function onLayout (dc) { 
		loadSettings();
	}

	(:debug)
	function onLayout (dc) {
		var mem = Sys.getSystemStats();
		//System.println(" mem: free: " +mem.freeMemory + "/"+mem.totalMemory +" used: "+mem.usedMemory);
		/* HR prototyping Sys.println(Toy.UserProfile.getHeartRateZones(Toy.UserProfile.HR_ZONE_SPORT_GENERIC));
		If the watch device is newer it will likely support calling this method, which returns an heart rate value that is updated every second:
		Activity.getActivityInfo().currentHeartRate()
		Otherwise, you can call this method and use the most recent value, which will be the heart rate within the last minute:
		ActivityMonitor.getHeartRateHistory()
		In both cases you will need to check for a null value, which will happen if the sensor is not available or the user is not wearing the watch.*/
		presetTestVariables();
		loadSettings();
		resetTestVariables();	
	}

	(:debug)
	function presetTestVariables () {
		var data = loadJsonResource(:testData);
		if(data.hasKey("CopyProperties")){
			var d = data["Properties"];
			var keys = d.keys();
			for(var i=0;i<keys.size();i++){
				Sys.println(" - copy property "+keys[i]+" to "+(d[keys[i]]!=null ? d[keys[i]].toString().substring(0,30) : "[MISSING]"));
				app.setProperty(keys[i], app.setProperty(keys[i],d[keys[i]]));
			}
		}
		if(data.hasKey("clearProperties")){
			var d = data["clearProperties"];
			for(var i=0;i<d.size();i++){
				Sys.println(" - clear property "+d[i]);
				app.setProperty(d[i], null);
			}
		}
		if(data.hasKey("Properties")){
			var d = data["Properties"];
			var keys = d.keys();
			for(var i=0;i<keys.size();i++){
				Sys.println(" - property "+keys[i]+": "+(d[keys[i]]!=null ? d[keys[i]].toString().substring(0,30) : "[MISSING]"));
				app.setProperty(keys[i], d[keys[i]]);
			}
		}
		if(data.hasKey("CharProperties")){
			var d = data["CharProperties"];
			var keys = d.keys();
			for(var i=0;i<keys.size();i++){
				Sys.println(" - char property "+keys[i]+": "+d[keys[i]].toCharArray()[0]);
				app.setProperty(keys[i], d[keys[i]]);
			}
		}
		if(data.hasKey("clearStorage")){
			var d = data["clearStorage"];
			for(var i=0;i<d.size();i++){
				if(Toybox.Application has :Storage){
					Sys.println(" - clear storage "+d[i]);	
					Toybox.Application.Storage.setValue(d[i], null);
				} else {
					Sys.println(" - clear property instead of storage "+d[i]);
					app.setProperty(d[i], null);
				}
			}
		}
		if(data.hasKey("Storage")){
			var d = data["Storage"];
			var keys = d.keys();
			for(var i=0;i<keys.size();i++){
				if(Toybox.Application has :Storage){
					Sys.println(" - storage "+keys[i]);	
					Toybox.Application.Storage.setValue(keys[i], (d[keys[i]]!=null ? d[keys[i]] : "[MISSING]"));
				} else {
					Sys.println(" - property instead of storage "+keys[i]+": "+d[keys[i]]);
					app.setProperty(keys[i], d[keys[i]]);
				}
			}
		}

		//app.setProperty("d24", Sys.getDeviceSettings().is24Hour); 
		//app.setProperty("units", 1);
		//set props: mainColor=1;circleWidth=9;
		//app.setProperty("activity", 6); app.setProperty("calendar_ids", ["myneur@gmail.com","petr.meissner@gmail.com"]);
		//app.setProperty("weather", true); app.setProperty("location", [50.1137639,14.4714428]); app.setProperty("sunriset", true);
		//app.setProperty("activityL", 2); app.setProperty("activityR", 1); 
		//app.setProperty("dialSize", 0);
		if(data.hasKey("Reinitialize")){
			Sys.println(" - Reinitialize");
			initialize();
		}
	}

	(:debug)
	function resetTestVariables () {
		var data = loadJsonResource(:testData);

		if(data.hasKey("AfterLayoutProperties")){
			var d = data["AfterLayoutProperties"];
			var keys = d.keys();
			for(var i=0;i<keys.size();i++){
				Sys.println(" - property reset "+keys[i]+": "+(d[keys[i]]!=null ? d[keys[i]].toString().substring(0,30) : "[MISSING]"));
				app.setProperty(keys[i], d[keys[i]]);
			}
		}
		if(data.hasKey("AfterLayoutCharProperties")){
			var d = data["AfterLayoutCharProperties"];
			var keys = d.keys();
			for(var i=0;i<keys.size();i++){
				Sys.println(" - char property reset "+keys[i]+": "+d[keys[i]].toCharArray()[0]);
				app.setProperty(keys[i], d[keys[i]].toCharArray()[0]);
			}
		}
		if(data.hasKey("AfterLayoutStorage")){
			var d = data["AfterLayoutStorage"];
			var keys = d.keys();
			for(var i=0;i<keys.size();i++){
				if(Toybox.Application has :Storage){
					Sys.println(" - storage reset "+keys[i]);	
					Toybox.Application.Storage.setValue(keys[i], d[keys[i]]);
				} else {
					Sys.println(" - property instead of storage reset "+keys[i]+": "+(d[keys[i]] ? d[keys[i]].toString().substring(0,30) : "[MISSING]"));
					app.setProperty(keys[i], d[keys[i]]);
				}
			}
		}
		if(data.hasKey("Message")){
			Sys.println(" - Message");
			showMessage({"msg"=>data["Message"]});
		}
		//weatherHourly = [18, 9, 0, 1, 6, 4, 5, 2, 3, 1, 6, 4, 5, 2, 3, 1, 6, 4, 5, 2, 3, 1, 6, 4, 5, 2, 3, 1, 6, 4, 5, 2, 3];
		//if(activity == :calendar && app.getProperty("refresh_token") == null){dialSize = 0;	/* there is no space to show code in strong mode */}
	}

	function loadSettings(){
		//rain = app.getProperty("rain");
		dateForm = app.getProperty("dateForm");
		
		var activities = [null, :steps, :calories, :activeMinutesDay, :activeMinutesWeek, :floorsClimbed, :calendar, :timeHour, :timeMinute];
		activity = activities[app.getProperty("activity")];
		activityL = activities[app.getProperty("activityL")];
		activityR = activities[app.getProperty("activityR")];
		showSunrise = app.getProperty("sunriset");
		batThreshold = app.getProperty("bat");
		dialSize = app.getProperty("dialSize");
		showWeather = app.getProperty("weather"); if(showWeather==null) {showWeather=false;} // because it is not in settings of non-data devices
		percentage = app.getProperty("percents");
		if(app.getProperty("subs")!=null && weatherHourly!=null && weatherHourly instanceof Array){
			if(weatherHourly.size()>5){	// if we know at least some forecast
				app.setProperty("last", 'w');	// to refresh the calendar first after the reload
			}
		}
		var d24new = app.getProperty("d24") == 1 ? true : false; 
		//d24new=true; app.setProperty("d24", d24new); 
		if(( activity == :calendar) && (d24!= null && d24new != d24)){	// changing 24 / 12h 
			events_list=[];
			showMessage(app.scheduleDataLoading(dataLoading, activity, showWeather));
			/*	TODO: changing angle immediately
				var hour = clockTime.hour;
				var mul; var a; var b;
				if(d24new){
					mul = 2;
					a = Math.PI/(720.0) * (hour*60+clockTime.min);	// 720 = 2PI/24hod
					if(hour>11){ hour-=12;}
					if(0==hour){ hour=12;}
					b = Math.PI/(360.0) * (hour*60+clockTime.min);	// 360 = 2PI/12hod
				} else {
					mul = 0.5;
					if(hour>11){ hour-=12;}
					if(0==hour){ hour=12;}
					b = Math.PI/(360.0) * (hour*60+clockTime.min);	// 360 = 2PI/12hod
					hour = clockTime.hour;
					a = Math.PI/(720.0) * (hour*60+clockTime.min);	// 720 = 2PI/24hod
				}
				for(var i=0; i<events_list.size(); i++){
					events_list[5] = ((a - events_list[5])*mul +b).toNumber();
					events_list[6] = ((a - events_list[6])*mul +b).toNumber();
				}
			*/
		}
		d24 = d24new;
		circleWidth = app.getProperty("boldness");
		if(height>280 && burnInProtection==0){
			circleWidth=circleWidth<<1;
		}
		var tone = app.getProperty("tone").toNumber()%5;
		var mainColor = app.getProperty("mainColor").toNumber()%6;

		setColor(mainColor, tone);

		if(dialSize>0){
			activityL=null;
			activityR=null;
		}
		// when running for the first time: load resources and compute sun positions
		if(showSunrise){ // TODO recalculate when day or position changes
			clockTime = Sys.getClockTime();
			utcOffset = clockTime.timeZoneOffset;
			computeSun();
			//Sys.println([sunrise, sunset]);
		}
		
		if(height==208 ){	// FR45 with 8 colors do not support gray. Contrary the simluator, the real watch do not support even LT_GRAY. 
			activityColor = Gfx.COLOR_WHITE; 
			if(tone != 3 && tone != 4){
				dateColor = Gfx.COLOR_WHITE;
			}
		}
		if(showWeather || activity == :calendar){
			loadDataColors(mainColor, tone, app);
		}
		setLayoutVars();
		onShow();
	}

	function blendColors(color1, color2, factor) {
		var r1 = (color1>>16)&0xFF;
		var g1 = (color1>>8)&0xFF;
		var b1 = color1&0xFF;
		var r2 = (color2>>16)&0xFF;
		var g2 = (color2>>8)&0xFF;
		var b2 = color2&0xFF;
		var r = (r1 + (r2 - r1)*factor).toNumber();
		var g = (g1 + (g2 - g1)*factor).toNumber();
		var b = (b1 + (b2 - b1)*factor).toNumber();
		return (r<<16)|(g<<8)|b;
	}

	function dimColor(color, factor){
		return blendColors(color, 0, factor);
	}

	function setColor(mainColor, tone){
		//	red, 	, yellow, 	green, 		blue, 	violet, 	grey
		color = [
			[0xFF0000, 0xFFAA00, 0x00FF00, 0x00AAFF, 0xFF00FF, 0xAAAAAA],
			[0xAA0000, 0xFF5500, 0x00AA00, 0x0000FF, 0xAA00FF, 0x555555], 
			[0xAA0055, 0xFFFF00, 0x55FFAA, 0x00AAAA, 0x5500FF, 0xAAFFFF]
		][tone<=2 ? tone : 0][mainColor];
		if(tone == 3){ 			// white background
			backgroundColor = 0xFFFFFF;
			timeColor = 0x0;
			dateColor = 0x0;
			activityColor = 0x555555;
			dimmedColor = 0xAAAAAA;
			if(color == 0xFFAA00){	// dark yellow background is more readable
				color = 0xFF5500;
			}
		} else if (tone == 4) {	// color background
			if(color == 0xFFAA00){	// dark yellow background is more readable
				color = 0xFF5500;
			} else if(color == 0xAAAAAA){	// dark gray background is more readable
				color = 0x555555;
			}
			backgroundColor = color;
			color = 0xFFFFFF;
			timeColor = 0x0;
			dateColor = 0x0;
			activityColor = 0xFFFFFF;
			dimmedColor = 0xAAAAAA;
		} else { 						// black background 
			backgroundColor = 0x0;
			timeColor = 0xFFFFFF;
			//activityColor = 0x555555;
			//dateColor = 0xAAAAAA;
			activityColor = 0xAAAAAA;
			dimmedColor = 0x555555;
			dateColor = 0xFFFFFF;
		}

		if (burnInProtection) {
			var dimFactor = 0.5;
			backgroundColor = dimColor(backgroundColor, dimFactor);
			color = dimColor(color, dimFactor);
			timeColor = dimColor(timeColor, dimFactor);
			dateColor = dimColor(dateColor, dimFactor);
			activityColor = dimColor(activityColor, dimFactor);
			dimmedColor = dimColor(dimmedColor, dimFactor);
		}
	}

	(:data)
	function loadJsonResource(id){
		return Ui.loadResource(Rez.JsonData[id]);
	}
	(:nodata) function loadJsonResource(id){ return {}; }

	(:data)
	function loadDataColors(mainColor, tone, app){
		mainColor = app.getProperty("mainColor").toNumber()%6;
		if(showWeather){
			meteoColors = loadJsonResource(:metCol);
			//Sys.println([0xFFAA00,	0xAA5500,	0x005555, 0x00AAFF,	0xAAAAAA, 0xFFFFFF, 0x555500];);
				//enum {	clear, 		partly, 	lghtrain, rain,	 	mild snow, snow, clear neight} // clean moon can be 555555 instead of sun and mostly cloudy can be skipped
			if(tone>2){
				meteoColors[2]=0x0055FF;
				//meteoColors[3]=0x00AAFF;
				if(tone==4){		// color bg
					meteoColors[0]=0xFFFF55;
					meteoColors[1]=0xFFAA00;
					if(mainColor==2 || mainColor==3){	// green || blue
						meteoColors[2]= mainColor==2 ? 0x0055FF /* try 0AF */ : 0x005555;
						meteoColors[3]=0x0000AA;
					} else if(mainColor==5 ){	// gray
						meteoColors[2]=0x0055FF;
					}
				}
			}
			if(tone==3){	// white background
				meteoColors[4]=0x555555;
				meteoColors[5]=0x0;

			}
		}

		/*var colorsToOverride = app.getProperty("cheat");
		if(colorsToOverride != null){
			if(colorsToOverride.length()>=6){
				colorsToOverride = app.split(colorsToOverride);
				if(colorsToOverride.size()>0) {color = colorsToOverride[0].toNumberWithBase(0x10);}
				if(colorsToOverride.size()>1) {dateColor = colorsToOverride[1].toNumberWithBase(0x10);}
				if(colorsToOverride.size()>2) {activityColor = colorsToOverride[2].toNumberWithBase(0x10);}
				if(colorsToOverride.size()>3) {timeColor = colorsToOverride[3].toNumberWithBase(0x10);}
				if(colorsToOverride.size()>4) {backgroundColor = colorsToOverride[4].toNumberWithBase(0x10);}
			}
		}*/
		if(activity == :calendar){
			if (eventColors.size() == 0) {
				eventColors = loadJsonResource(:evtCol);
				gcalColors = loadJsonResource(:gcalCol);
			}
			if(app.getProperty("calendar_colors") || !(app.getProperty("calendarColors") instanceof Array) ){	// match calendar colors to watch
				calendarColors = loadJsonResource(:calCol)[mainColor];
				/*Sys.println( [
					[0xAA0055, 0xFFFF00, 0x555555], 
					[0xFFFF00, 0xAA00FF, 0x555555], 
					[0x55FFAA, 0x00AAFF, 0x555555], 
					[0x00AAAA, 0xFFFF00, 0x555555], 
					[0xAA00FF, 0xFFFF00, 0x555555], 
					[0x555555, 0xAA00FF, 0x00AAFF] 
					]);*/
				/*for(var i=0; i<calendarColors.size(); i++){
					calendarColors[i] = calendarColors[i].toNumberWithBase(0x10);
				}*/
				if(tone == 4) {	// color background 
					calendarColors[0] = 0xFFFFFF;
					calendarColors[2] = 0x0;
					if(mainColor==1 || mainColor==2) {calendarColors[1]=0xFFFF55;}
					else if(mainColor==5) {calendarColors[1]=0xAAFFFF;}
				} else if(tone == 3) { // white background
					if(mainColor==0 || mainColor==3) {calendarColors[1]=0xAA00FF;}
					else if(mainColor==2) {calendarColors[0]=0x00AA00;}
					else if(mainColor==2) {calendarColors[0]=0xFF5500;}
				}
				app.setProperty("calendarColors", calendarColors);
			} else {	// keep last calendar colors
				calendarColors = app.getProperty("calendarColors");
			}
		}
	}
	(:nodata) function loadDataColors(mainColor, tone, app){ return false;}


	function setBaseVars(){ /// part of vars that need to be reset by OLED in AOD
		// add maincolor and cirlcewidth
		var s=Sys.getDeviceSettings();
		height = s.screenHeight;
		centerX = s.screenWidth >> 1;
		centerY = height >> 1;

		if(dialSize>0){
			dateY = (centerY-radius*.5-Gfx.getFontHeight(fontSmall)).toNumber();
			if(height<208){
				dateY += 7;
			}
		} else {
			//try {
				dateY = (centerY-(radius+Gfx.getFontHeight(fontSmall))*1.17).toNumber();
			//} catch(ex){ 
			//var m = ex.getErrorMessage();showMessage({"msg"=>m.substring(0, m.length()/2), "msg2"=>m.substring(m.length()/2, null), "now"=>true});}
		}
		//Sys.println("MEM: "+Sys.getSystemStats().freeMemory);
	}


	function setLayoutVars(){
		icons = Ui.loadResource(Rez.Fonts.Ico);
		sunR = Math.ceil(centerX-5*height/218)+1;// - (height>=390 ? (showWeather ? 23:16) : (showWeather ? 15:11)); // base: -9-11, weather: 15
		if(sunR>centerX-6){
			sunR=centerX - (!(activity==:calendar || showWeather) ? 6 :5); // drawCircle is wider than fillCircle
		}
		if(showSunrise){
			//sunrs.getWidth()>>1;
			if(activity==:calendar){ sunR -= height<390 ? 9:13;}
			if(showWeather){ sunR -=  height<390 ? 4:6;}
			//if(activity==:calendar && showWeather) { sunR -= 2;}
			// TODO sunrs.width() - calendar f6: 6 venu: 10 / weather: f6: 3 venu: 5
		}
		fontCondensed = Ui.loadResource(Rez.Fonts.Condensed);
		fontMedium = Ui.loadResource(Rez.Fonts.Medium);
		if(dialSize>0){ // strong design
			fontHours = Ui.loadResource(Rez.Fonts.HoursStrong);
			fontSmall = Ui.loadResource(Rez.Fonts.SmallStrong);
			radius = (Gfx.getFontHeight(fontHours)*1.07).toNumber();
			if(centerX-radius-circleWidth>>1 <= 15){	// shrinking radius to fit day circle and sunriset on small screens
				radius = centerX-15-circleWidth>>1;
				sunR+=1;	
			}
			circleWidth=circleWidth*3; // TODO unify with AOD
			batteryY=height-14;

			if(height<208){
				radius -= 11;
			}
		} else { // elegant design
			fontHours = Ui.loadResource(Rez.Fonts.Hours);
			fontSmall = Ui.loadResource(Rez.Fonts.Small);
			radius = (Gfx.getFontHeight(fontHours)).toNumber();
			batteryY = centerY+0.6*radius;			
		}
		setBaseVars();
		
		// MEM logs: 39368-39376
		if(dialSize==0){
			activityY = (height>180) ? height-Gfx.getFontHeight(fontCondensed)-10 : centerY+80-Gfx.getFontHeight(fontCondensed)>>1 ;
/* ±10? */		messageY = (centerY-radius+10)>>2 - Gfx.getFontHeight(fontCondensed)-1 + centerY+radius+10;						
		} else {
			activityY= centerY+Gfx.getFontHeight(fontHours)>>1+15;
			if(height<208){
				activityY -= 7;
			}
			messageY =activityY - Gfx.getFontHeight(fontSmall)>>1 -10; 
		}
		/*if(batteryY<centerY+radius+circleWidth>>1){
			if(activity!=:calendar){
				batteryY = activityY - 10;
				activityY += 10;
			} else {
				batteryY = dateY+Gfx.getFontHeight(fontSmall);
			}
			
		}*/

		if(dataLoading){
			if(activity == :calendar || showWeather){
				showMessage(app.scheduleDataLoading(dataLoading, activity, showWeather));
				if(activity == :calendar){
					activityY = messageY;
				}
			} else {
				app.unScheduleDataLoading();
			}
		} else {
			showWeather = false;
			if(activity == :calendar){ 
				activity = null; 
			}
		}


		var langTest = Calendar.info(Time.now(), Time.FORMAT_MEDIUM).day_of_week.toCharArray()[0]; // test if the name of week is in latin. Name of week because name of month contains mix of latin and non-latin characters for some languages. 
		if(langTest.toNumber()>382){ // fallback for not-supported latin fonts 
			fontSmall = Gfx.FONT_SMALL;
		}
		/////Sys.println("Layout finish free memory: "+Sys.getSystemStats().freeMemory);
	}

	//! Called when this View is brought to the foreground. Restore the state of this View and prepare it to be shown. This includes loading resources into memory.
	//function onShow() {
		//App.getApp().setProperty("l", App.getApp().getProperty("l")+"w");
		//Sys.println(clockTime.min+"w");
		//Sys.println("onShow");
		
		/*if(centerX <=104){ // FR45 and VA4 needs to redraw the display every second. Better to 
			redrawAll=100;
		} else {
			redrawAll=2; // 2: 2 clearDC() because of lag of refresh of the screen ?
		}*/
	//}
	
	//! Called when this View is removed from the screen. Save the state of this View here. This includes freeing resources from memory.
	//function onHide(){
		//App.getApp().setProperty("l", App.getApp().getProperty("l")+"h");
		//Sys.println(clockTime.min+"h");
		/////Sys.println("onHide");
		//redrawAll=0;
	//}
	
	//! The user has just looked at their watch. Timers and animations may be started here.
	(:oled)
	function onExitSleep(){
		if(Sys.getDeviceSettings().requiresBurnInProtection){
			lowPowerMode=false;
			burnInProtection=0;
				
			try { // WTF!!! OLED devices remove fonts and launch onExitSleep before initialize again
	
				circleWidth = app.getProperty("boldness");
				if(height>280){
					circleWidth=circleWidth<<1;
				}
				if(dialSize>0){
					circleWidth*=3;
				}

				setBaseVars();
				setColor(app.getProperty("mainColor"), app.getProperty("tone"));
			} catch (ex){
				initialize();
			}
		}
	
		//onShow();
		//App.getApp().setProperty("l", App.getApp().getProperty("l")+"x");
		//Sys.println(clockTime.min+"x");
		//////Sys.println("onExitSleep");
		//wakeCount++;
		
		/*if(showWeather){
			locateAt = new Toy.Timer.Timer().start(method(:loadSettings), getTemporalEventRegisteredTime(), true);
		}*/
	}

	//! Terminate any active timers and prepare for slow updates.
	(:oled)
	function onEnterSleep(){
		if(Sys.getDeviceSettings().requiresBurnInProtection){
			lowPowerMode=true;
			burnInProtection=1;
			circleWidth=10;
			setColor(app.getProperty("mainColor"), app.getProperty("tone")>2 ? 0 : app.getProperty("tone"));
		}
		//App.getApp().setProperty("l", App.getApp().getProperty("l")+"e");
		//Sys.println(clockTime.min+"e");
		//////Sys.println("onEnterSleep");
		/*if(centerX <=104){ // FR 45 needs to redraw the display every second
			redrawAll=100;
			Ui.requestUpdate();
		} else {
			redrawAll=0; // 2: 2 clearDC() because of lag of refresh of the screen ?
		}*/
		//redrawAll=0; // 2: 2 clearDC() because of lag of refresh of the screen ?
	}

	/*function openTheMenu(){
		menu = new MainMenu(self);
		Ui.pushView(new Rez.Menus.MainMenu(), new MyMenuDelegate(), Ui.SLIDE_UP);
	}*/

	//! Update the view
	// TODO AOD-X // var dx=5;var dy=5;
	function onUpdate (dc) {	//Sys.println("onUpdate ");
		clockTime = Sys.getClockTime();
		var cal = Calendar.info(Time.now(), Time.FORMAT_MEDIUM);
		//if (lastRedrawMin != clockTime.min && redrawAll==0) { redrawAll = 1; }
		//var ms = [Sys.getTimer()];
		//if (redrawAll>0){
		//////Sys.println([clockTime.min, redrawAll, Sys.getSystemStats().freeMemory]);
		if(dc has :setAntiAlias) {
			dc.setAntiAlias(true);
		}
		dc.setColor(backgroundColor, backgroundColor);
		dc.clear();

		sleepMode = false;
		if (lowPowerMode) {
			burnInProtection = burnInProtection != 0 ? burnInProtection : 1;
		} else {
			doNotDisturb = Sys.getDeviceSettings().doNotDisturb;
			if (doNotDisturb) {
				var profile = Toy.UserProfile.getProfile();
				var time = Time.now().subtract(Time.today());
				var wakeTime = profile.wakeTime;
				var dur24hr = new Time.Duration(86400);
				if (wakeTime.lessThan(profile.sleepTime)) {
					wakeTime = wakeTime.add(dur24hr);
				}
				if (time.lessThan(profile.sleepTime)) {
					time = time.add(dur24hr);
				}
				if (time.lessThan(wakeTime)) {
					sleepMode = true;
				}
			}
			if (sleepMode) {
				burnInProtection = 3;
			} else {
				burnInProtection = 0;
			}
		}

		if(burnInProtection){
			var diff = 4;
			if(burnInProtection == 2) {
				centerX = centerX + ((centerX == (height>>1)) ? diff : -diff);
				burnInProtection=1;
			} else if (burnInProtection == 1) {
				var move = (centerY==(height>>1)) ? diff : -diff;
				centerY = centerY + move;
				dateY = dateY + move;
				burnInProtection=2;
			}

			if (activityR == :timeMinute) {
				var x = centerX-radius - (sunR-radius)>>1-(dc.getTextWidthInPixels("1", fontSmall)/3).toNumber();	// scale 4 with resolution
				drawActivity(dc, activityR, centerX<<1-x, centerY, false);
			}
		} else {
		// TODO AOD-X // if(burnInProtection){Sys.println([clockTime.hour, dx,dy]);if(burnInProtection>1){dx = dx == -5 ? dx+10 : dx-10;centerX = centerX + dx;centerY = centerY + dy;burnInProtection=1;}else{dy = dy == -5 ? dy+10 : dy-10;centerX = centerX + dx;centerY = centerY + dy;burnInProtection=2;}} else {
			//lastRedrawMin=clockTime.min;
			
			
			//ms.add(Sys.getTimer()-ms[0]);

			// function drawDate(x, y){}
			dc.setColor(dateColor, Gfx.COLOR_TRANSPARENT);
			var text = "";
			if(dateForm != null){
				text = Lang.format("$1$ ", ((dateForm == 0) ? [cal.month] : [cal.day_of_week]) );
			}
			text += cal.day.format("%0.1d");
			dc.drawText(centerX, dateY, fontSmall, text, Gfx.TEXT_JUSTIFY_CENTER);
			dc.setColor(activityColor, backgroundColor);

			var iconX = centerX-dc.getTextWidthInPixels(text+"  ", fontSmall)>>1;
			var iconY = dateY+dc.getFontHeight(fontSmall)>>1+1;
			if (doNotDisturb) {
				dc.fillCircle(iconX - 8, iconY, 8);
				dc.setColor(backgroundColor, Gfx.COLOR_TRANSPARENT);
				dc.fillRectangle(iconX - 8 - 5, iconY - 1, 11, 3);
			} else {
				var icon = null;
				if (sleepMode) {
					icon = ")";
				} else if(!doNotDisturb && Sys.getDeviceSettings().notificationCount){
					icon = "!";
				}

				if (icon != null) {
					dc.drawText(iconX, iconY, icons, icon, Gfx.TEXT_JUSTIFY_RIGHT | Gfx.TEXT_JUSTIFY_VCENTER);
					//dc.fillCircle(centerX-dc.getTextWidthInPixels(text, fontSmall)>>1-14, dateY+dc.getFontHeight(fontSmall)>>1+1, 5);
				}
			}

			/*dc.drawText(centerX, height-20, fontSmall, Toy.ActivityMonitor.getInfo().moveBarLevel, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);dc.setPenWidth(2);dc.drawArc(centerX, height-20, 12, Gfx.ARC_CLOCKWISE, 90, 90-(Toy.ActivityMonitor.getInfo().moveBarLevel.toFloat()/(ActivityMonitor.MOVE_BAR_LEVEL_MAX-ActivityMonitor.MOVE_BAR_LEVEL_MIN)*ActivityMonitor.MOVE_BAR_LEVEL_MAX)*360);*/
			dc.setColor(activityColor, Gfx.COLOR_TRANSPARENT);
			var x = centerX-radius - (sunR-radius)>>1-(dc.getTextWidthInPixels("1", fontSmall)/3).toNumber();	// scale 4 with resolution
			drawActivity(dc, activityL, x, centerY, false);
			drawActivity(dc, activityR, centerX<<1-x, centerY, false);
		}
		drawTime(dc, activityR != :timeMinute);
		if(activity != null || message){
				if(activity == :calendar || message){
					drawEvent(dc);
				} else { 
					if(burnInProtection==0){
						drawActivity(dc, activity, centerX, activityY, true);
					}
				}
			}
		// DEBUG System.println([clockTime.sec , showWeather, burnInProtection]); 
		if(burnInProtection==0){
			if(showWeather){
				drawWeather(dc);
			}
			if(activity == :calendar){
				drawEvents(dc);
			}
			if(showSunrise){
				drawSunBitmaps(dc, cal);
			}
			// TODO recalculate sunrise and sunset every day or when position changes (timezone is probably too rough for traveling)
			drawNowCircle(dc, clockTime.hour);
			drawBatteryLevel(dc);
		} 
//showMessage({"msg":"testing"});
		//}
		//ms.add(Sys.getTimer()-ms[0]);
		/////Sys.println("ms: " + ms + " sec: " + clockTime.sec + " redrawAll: " + redrawAll);
		//if (redrawAll>0) { redrawAll--; }
	}

	
	function steps(info){
		return info.steps.toFloat()/info.stepGoal;
	}
	function calories(info){
		var hist = ActivityMonitor.getHistory();
		if(hist.size()>0 && hist[0].calories){
			return info.calories.toFloat()/ActivityMonitor.getHistory()[0].calories;
		} else {
			return 0;
		}
		
	}
	function activeMinutesDay(info){
		return info.activeMinutesDay.total.toFloat()/(info.activeMinutesWeekGoal.toFloat()/7);
	}
	function activeMinutesWeek(info){
		return info.activeMinutesWeek.total.toFloat()/info.activeMinutesWeekGoal;
	}
	function floorsClimbed(info){
		return info.floorsClimbed.toFloat()/info.floorsClimbedGoal;
	}

	function drawActivity(dc, activity, x, y, horizontal){
		if(activity == :timeHour) {
			var h = clockTime.hour;
			var set = Sys.getDeviceSettings();
			if(set.is24Hour == false){
				if(h > 11){ h -= 12; }
				if(h == 0){ h = 12; }
			}
			dc.setColor(color, Gfx.COLOR_TRANSPARENT);
			dc.drawText(x, y, fontCondensed, h.format("%0.1d"), Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
		} else if(activity == :timeMinute) {
			var m = clockTime.min; 
			dc.setColor(color, Gfx.COLOR_TRANSPARENT);
			dc.drawText(x-7, y, fontMedium, m.format("%0.2d"), Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
		} else if(activity != null){
			//Sys.println("ActivityMonitor");
			var info = Toy.ActivityMonitor.getInfo();
			var activityChar = {:steps=>'s', :calories=>'c', :activeMinutesDay=>'a', :activeMinutesWeek=>'a', :floorsClimbed=>'f'}[activity];	// todo optimize
			//var activityChar = activity==:steps ? 's' : activity==:calories ? 'c' : activity==:floorsClimbed? 'a' : 'f';
			//var activityChar;switch(activity){case :steps: activityChar='s';case :calories: activityChar='c';case :floorsClimbed: activityChar='f';default: activityChar='a';}
			if(percentage){
				info = method(activity).invoke(info);
				var r = Gfx.getFontHeight(icons)-3;
				dc.setPenWidth(2);
				dc.setColor(activityColor, Gfx.COLOR_TRANSPARENT);	
				drawIcon(dc, x, y, activityChar); // dc.drawBitmap(x-icon.getWidth()>>1, y-icon.getHeight()>>1, icon);	
				if(info>0.0001){
					dc.setColor(info<2 ? activityColor : dateColor, Gfx.COLOR_TRANSPARENT);	
					if(info>1){	
						if(info<3){
							dc.drawArc(x, y, r, Gfx.ARC_CLOCKWISE, 90-info*360-10, 100); 
							dc.setColor( info<2 ? dateColor : color, Gfx.COLOR_TRANSPARENT);
						} else {
							dc.setColor( color, Gfx.COLOR_TRANSPARENT);
							dc.drawCircle(x, y, r);
						}
					}
					dc.drawArc(x, y, r, Gfx.ARC_CLOCKWISE, 90, 90-info*360); 
				}
			} else {
				info = info[activity];
				info = humanizeNumber( (activity==:activeMinutesDay || activity==:activeMinutesWeek) ? info.total : info);
				var icoHalf = dc.getTextWidthInPixels(activityChar.toString(), icons)>>1;
				dc.setColor(activityColor, Gfx.COLOR_TRANSPARENT);	
				if(horizontal){	// bottom activity
					dc.drawText(x + icoHalf+1, y, fontCondensed, info, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER); 
					drawActivityIcon(dc, x - dc.getTextWidthInPixels(info, fontCondensed)>>1 -2, y, activityChar);
				} else {
					drawActivityIcon(dc, x  -3, y-Gfx.getFontHeight(icons)-1, activityChar);
					dc.drawText(x, y+1, fontCondensed, info, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER); 
				}
			}
		}
	}

	function drawIcon(dc, x, y, char){
		//dc.setColor(activityColor, 0xffffff);
		dc.drawText(x, y, icons, char, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
		//dc.setColor(0xff0000, 0xff0000);dc.setPenWidth(1);dc.drawLine(x-20, y, x+20, y);dc.drawLine(x, y-20, x, y+20);
	}
	function drawActivityIcon(dc, x, y, activityChar){
		//dc.setColor(activityColor, 0xffffff);
		dc.drawText(x, y, icons, activityChar, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
		//dc.setColor(0xff0000, 0xff0000);dc.setPenWidth(1);dc.drawLine(x-20, y, x+20, y);dc.drawLine(x, y-20, x, y+20);
	}

/*	function positionMetric(icon, text, vertical) {
		if(vertical){
			y: icon/2 down, icon: (text+icon)/2 up -gap

		} else {
			x: icon/2 right icon: (text+icon)/2 left -gap
			x: (text+icon)/2
				+icon
				-gap
		}
	}*/

	function showMessage(msg){	//Sys.println("message "+message);
		if(msg instanceof Lang.Dictionary && msg.hasKey("msg")){
			var nowError = Time.now().value();
			message = true;
			if(msg.hasKey("wait")){
				nowError += msg["wait"].toNumber();
			}
			var context = msg.hasKey("msg2") ? " "+ msg["msg2"] : "";
			var calendar = msg.hasKey("now") ? -1 : 0;

			var fromAngle = ((nowError-Time.today().value())/240.0).toFloat(); // seconds_in_day/360 // TODO bug: for some reason it won't show it at all althought the degrees are correct. 
			events_list = [[nowError, nowError+86400, msg["msg"].toString(), context, calendar, fromAngle, fromAngle+2]].addAll(events_list); // seconds_in_day
		}
	}

	(:data)
	function onBackgroundData(data) { //+*/Sys.println("onBackgroundData view "+clockTime.hour + ":" + clockTime.min); Sys.println(data); 
		if(data instanceof Array){	
			events_list = data;
		} 
		else if(data instanceof Lang.Dictionary){
			if(data.hasKey("weather")){
				weatherHourly = data["weather"];
				//Sys.println(weatherHourly);
				var h = Sys.getClockTime().hour; // first hour of the forecast
				//	Sys.println(["meteoColors", meteoColors]); Sys.println(["weatherHourly", weatherHourly]); 
				if (weatherHourly instanceof Array && weatherHourly.size()>5){	
					if(weatherHourly[0]!=h){ // delayed response or time passed
						if((h+1)%24 == weatherHourly[0]){	// forecast from future
							var gap = weatherHourly[0]-h;
							if(gap<0){
								gap += 24;
							}
							var balast = new [gap];
							while(gap>0){
								gap--;
								balast[gap]= -1;
							}
							weatherHourly = [h].addAll(weatherHourly.slice(1,5)).addAll(balast).addAll(weatherHourly.slice(5,null));
						} else if(!(h==(weatherHourly[0]+1)%24)){ // all except forecast in past
							weatherHourly[0]=h;	// ignoring difference because of the bug 
						}
					}
				} 
				var hourAngle = (trimPastHoursInWeatherHourly())%24;
				//Sys.println(weatherHourly);
				if(hourAngle>=0 && showSunrise && sunrise != null){	// dimming clear-night colors
					var sunAngle = toAngle(sunrise);
					var moonAngle = toAngle(sunset);
					//Sys.println([sunAngle,moonAngle]);
					for(var i =5; i<weatherHourly.size();i++){
						if(hourAngle+1 < sunAngle || hourAngle>moonAngle){	// dim by half at night
							var category = weatherHourly[i].toNumber();
							weatherHourly[i] = category + (weatherHourly[i]-category)/2;
						}
						//Sys.println(hourAngle);
						hourAngle=(hourAngle+1)%24;
					}
				}
				app.setProperty("weatherHourly", weatherHourly);
			}
			else if(data.hasKey("msg")){
				showMessage(data);
			}
			//debug();
		}
		onShow();
		Ui.requestUpdate();
	}


/*function debug(){
	if(Toy has :Weather){
		var weather = Toy.Weather.getDailyForecast();
		if(weather != null){
			weather = weather[0];
			rain = [weather.lowTemperature, weather.highTemperature, weather.precipitationChance];
			if(weatherHourly.size()>4){
				var t = weatherHourly[1];
				if(t<rain[0]){rain[0] = t;}
				if(t>rain[1]){rain[1] = t;}
			}
			app.setProperty("rain", rain);
			//Sys.println(rain);
		}
	}

	//if(App.getApp().getProperty("calendar_ids").size()>0){
		//if(App.getApp().getProperty("calendar_ids")[0].find("myneur")!=null){//showMessage({"msg"=> message});
		//weatherHourly = [13, 9, 0, 1, 6, 4, 5, 2, 3];App.getApp().setProperty("weatherHourly", weatherHourly);}}
}*/

	function humanizeNumber(number){
		if(number>1000) {
			return (number.toFloat()/1000).format("%1.1f")+"k";
		} else {
			return number.toString();
		}
	}

	function drawNowCircle(dc, hour){
		// show now in a day
		if( !(events_list.size()>0 && events_list[0][4]==-1) /* permanent message =-1 in 4th events_list item */ && (activity == :calendar || showSunrise || showWeather) ){
			var a;
			if(d24){
				a = Math.PI/(720.0) * (hour*60+clockTime.min);	// 720 = 2PI/24hod
			} else { 
				//return; // so far for 12h //12//
				if(hour>11){ hour-=12;}
				if(0==hour){ hour=12;}
				a = Math.PI/(360.0) * (hour*60+clockTime.min);	// 360 = 2PI/12hod
			}
			var x = centerX+(sunR*Math.sin(a));
			var y = centerY-(sunR*Math.cos(a));
			dc.setColor(backgroundColor, backgroundColor);
			dc.fillCircle(x, y, 5);
			if(activity == :calendar || showWeather){
				dc.setColor(dateColor, backgroundColor);
				dc.fillCircle(x, y, 4);
			} else {
				dc.setColor(activityColor, backgroundColor);
				dc.setPenWidth(1);
				dc.drawCircle(x, y, 4);
			}
			// line instead of circle dc.drawLine(centerX+(r*Math.sin(a)), centerY-(r*Math.cos(a)),centerX+((r-11)*Math.sin(a)), centerY-((r-11)*Math.cos(a)));
		}
	}

	(:data)
	function drawEvent(dc){ 
		// calculate time to first event
		var eventStart;   
		var eventStartTime; 
		var eventLocation="";    
		var i=0;
		for(; i<events_list.size(); i++){
			//Sys.println(events_list[i]);
			eventStartTime = new Time.Moment(events_list[i][0]);
			var timeNow = Time.now();
			var tillStart = eventStartTime.compare(timeNow);
			if(tillStart >= (d24 ? 86400 : 43200)){ 
				continue;
			} 
			var eventEnd = new Time.Moment(events_list[i][1]);

			if(eventEnd.compare(timeNow)<0 || tillStart < -28800) { // past event or event that started more than 8 hours in past regardless if it still lasts
				events_list.remove(events_list[i]);
				if(events_list.size()==0){
					message = false;
				}
				i--;
				continue;
			}

			if(tillStart < -300){
			  continue;  
			}
			if (tillStart >= 28800){ // more than 8 hrs, do not draw
				continue;
			}
			if(tillStart <= 0){
				eventStart = "now!";
			} else {

				if(tillStart < 3480){	// 58 mins
					var secondsFromLastHour = events_list[i][0] - (Time.now().value()-(clockTime.min*60+clockTime.sec));
					var a = (secondsFromLastHour).toFloat()/1800*Math.PI; // 2Pi/hour
					var r = (tillStart>=120 || clockTime.min<10 || burnInProtection>0) ? radius : radius-Gfx.getFontHeight(fontSmall)>>1-1; //12//
					//var r = dialSize ? radius : 1.12*radius; //12//
					var x= Math.round(centerX+(r*Math.sin(a)));
					var y = Math.round(centerY-(r*Math.cos(a)));

					//12// marker 
					
					if(burnInProtection==0){
						dc.setColor(backgroundColor, backgroundColor);
						dc.fillCircle(x, y, 4);
						dc.setColor(dateColor, backgroundColor);
						dc.fillCircle(x, y, 2);
					} else {
						dc.setColor(dateColor, backgroundColor);
						dc.fillCircle(x, y, 4);
						dc.setColor(backgroundColor, backgroundColor);
						dc.fillCircle(x, y, 3);
					}
					
					dc.setPenWidth(1);
					dc.setColor(dateColor, backgroundColor);
					dc.drawCircle(x, y, circleWidth>>1);
				}
				if (tillStart < 3600) {	// hour
					eventStart = tillStart/60 + "m";
				} else if (tillStart < 28800) {	// 8 hours
					eventStart = tillStart/3600 + "h" + tillStart%3600 / 60 ;
				// } else {
				// 	var time = Calendar.info(eventStartTime, Calendar.FORMAT_SHORT);
				// 	var h = time.hour;
				// 	if(Sys.getDeviceSettings().is24Hour == false){
				// 		if(h>11){ h-=12;}
				// 		else if(0==h){ h=12;}	
				// 	}
				// 	eventStart = h.toString() + ":"+ time.min.format("%02d");
				}
			}
			eventLocation = height>=280 || events_list[i][4]<0 ? events_list[i][3] : events_list[i][3].substring(0,8); // big screen or emphasized event without date 
			//event["name"] += "w"+wakeCount+"d"+dataCount;	// debugging how often the watch wakes for updates every seconds
			break;
		}

		// draw first event if it is close enough
		if(eventStart != null && burnInProtection==0){
			if(events_list[i][4]<0){ // no calendar event, but prompt
				dc.setColor(dateColor , Gfx.COLOR_TRANSPARENT); // emphasized event without date
			} else {
				dc.setColor(activityColor , Gfx.COLOR_TRANSPARENT);
			} 				// TODO weirdly, messageY can be null => FIX! 
			dc.drawText(centerX, messageY, fontCondensed, height>=280 ? events_list[i][2] : events_list[i][2].substring(0,21), Gfx.TEXT_JUSTIFY_CENTER);
			dc.setColor(dateColor, Gfx.COLOR_TRANSPARENT);
			// TODO remove prefix for simplicity and size limitations
			var x = centerX;
			var justify = Gfx.TEXT_JUSTIFY_CENTER;
			var eventHeight=Gfx.getFontHeight(fontCondensed)-1;  
			if(events_list[i][4]>=0){ // calendar event
				dc.setColor(dateColor , Gfx.COLOR_TRANSPARENT); // empha
				x-=(dc.getTextWidthInPixels(eventStart+eventLocation, fontCondensed)>>1 
					-(dc.getTextWidthInPixels(eventStart, fontCondensed)));
				dc.drawText(x, messageY+eventHeight, fontCondensed, eventStart, Gfx.TEXT_JUSTIFY_RIGHT);
				dc.setColor(activityColor, Gfx.COLOR_TRANSPARENT);
				justify = Gfx.TEXT_JUSTIFY_LEFT;
			}

			//else {dc.drawText(x,  height-batteryY, fontCondensed, eventStart, Gfx.TEXT_JUSTIFY_VCENTER);}
			dc.drawText(x, messageY+eventHeight, fontCondensed, eventLocation, justify);
		}
	}
	(:nodata)function drawEvent(dc){ return false;}

	(:data)
	function drawEvents(dc){
		var radius = centerY;
		var width;
		if(height >= 390){
			radius -= showWeather ? 13:7;
			width = 12;
		} else {
			radius -= showWeather ? 8:4;
			width = 8;	
		}
		var nowAngle = ((clockTime.min+clockTime.hour*60.0)/ (d24? 4 : 2 )).toNumber(); // 360/1440;
		var tomorrow = Time.now().value() + (d24 ? 86400 : 43200); // 86400= Calendar.SECONDS_PER_DAY 
		var fromAngle; var toAngle;
		// var center; 
		/*var h; var idx=2;	// offset 
		var weatherStart; var weatherEnd;*/

		for(var i=0; i <events_list.size() && events_list[i][0]<tomorrow; i++){		
			var event = events_list[i];
			fromAngle = event[5];
			toAngle = event[6];	
			/*var midnight = Time.today().value();	
			var dayDegrees = 86400.0 / (App.getApp().getProperty("d24") == 1 ? 360 : 720);	// SECONDS_PER_DAY /
			fromAngle = Math.round((events_list[i][0]-(midnight))/dayDegrees).toNumber();
			toAngle = Math.round((events_list[i][1]-(midnight))/dayDegrees).toNumber();
			if(fromAngle == toAngle){
				toAngle = fromAngle+1;
			}*/
			//Sys.println([i, events_list[i][0], nowAngle,tomorrow, fromAngle, toAngle]);		
			// TODO drop event that started yesterday
			if(event[1] >= events_list[0][0] + (d24 ? 86400 : 43200)){	// event end overlaps first event start
				toAngle = events_list[0][5].toNumber()%360;
				//toAngle = Math.round((events_list[0][0]-(midnight))/dayDegrees).toNumber()%360;
				if((fromAngle.toNumber()+1)%360>=toAngle){ // intented to prevent shorter events than 1° to fail. 
					//Sys.println(["f", i, nowAngle,tomorrow, fromAngle, toAngle]);		
					toAngle = fromAngle+1;
					//continue; // 
				} else {
					toAngle-=1;
				}
			} 
			if(event[1]>=tomorrow && event[6]>nowAngle ) { // event ending tomorrow overlaps now
			//if(events_list[i][1]>=tomorrow && Math.round((events_list[i][1]-(midnight))/dayDegrees).toNumber()>nowAngle ) { // crop tomorrow event overlapping now on 360° dial
				toAngle=nowAngle.toNumber()%360;
				if((fromAngle.toNumber()+1)%360>=toAngle){ // intented to prevent shorter events than 1° to fail. 
					//Sys.println(["s", i, nowAngle,tomorrow, fromAngle, toAngle]);		
					//toAngle = nowAngle;
					//continue;
					toAngle = fromAngle+1;
				} else {
					toAngle-=1;
				}

			} 
			/*if(showWeather && weatherHourly.size()>2){
				// counting overlap // first attempt was: // weatherStart = ((weatherHourly[0]+idx-2)*360/24)%360;weatherEnd = ((weatherHourly[0]+idx-2+1)*360/24)%360;fromAngle = fromAngle.toNumber()%360;toAngle = toAngle.toNumber()%360;while(idx<weatherHourly.size() && (fromAngle>weatherEnd || toAngle<weatherStart)){idx++;}radius = centerY - (idx<weatherHourly.size()? 2:7);
				weatherStart = (fromAngle*24.0/360).toNumber()%24;
				weatherEnd = Math.ceil(toAngle*24.0/360).toNumber()%24;
				h = weatherStart;
				idx = h-weatherHourly[0]+2; /////Sys.println([weatherHourly[0], idx, weatherStart, weatherEnd]);
				if(idx<2){
					idx = 24-weatherHourly[0]+weatherStart+2;
				}
				while(h<weatherEnd && idx<weatherHourly.size()){
					if(weatherHourly[idx]!=-1){	
						break; // no weather to add padding 
					}
					idx++;
					h++;
				}
				radius = centerY - (h<weatherEnd? 8:2); //System.println([h,weatherEnd,radius]);
			}*/
			// drawing
			//Sys.println([fromAngle, toAngle]);
			//Sys.println([i, nowAngle,tomorrow, fromAngle, toAngle]);		
			dc.setColor(backgroundColor, backgroundColor);
			dc.setPenWidth(width);
			dc.drawArc(centerX, centerY, radius, Gfx.ARC_CLOCKWISE, 450-fromAngle+1, 450-fromAngle);
			var cal = event[4];
			
			if(cal!=null && cal>=0){
				var colors;
				if (cal % 4 == 0) {
					colors = eventColors;
				} else if (cal % 4 == 1) {
					colors = gcalColors;
				} else {
					colors = calendarColors;
				}
				if (colors.size() > 0) {
					cal = (cal>>2)%colors.size();
					dc.setColor(colors[cal], backgroundColor);
				}
			}
			dc.setPenWidth(width);
			// center = fromAngle>=60 && fromAngle<240 ? centerX-1 : centerX; // correcting the center is not in the center because the display resolution is even
			dc.drawArc(centerX, centerY, radius, Gfx.ARC_CLOCKWISE, 450-fromAngle, 450-toAngle);	// draw event on dial

		}
	}
	(:nodata) function drawEvents(dc){ return false;}

	/*function drawIconP(percent, icon, dc){
		var a = percent * 2*Math.PI;
		var r = centerX-9;
		dc.drawText(0, 0, icons, "1", Gfx.TEXT_JUSTIFY_CENTER); //dc.drawBitmap(centerX+(r*Math.sin(a))-8, centerY-(r*Math.cos(a))-8, icon);
		return a;
	}*/
	
	
	/*
	function drawTime (dc){

		// draw hour
		var r; var v;
		var h=clockTime.hour;
		var set = Sys.getDeviceSettings();
		if(set.is24Hour == false){
			if(h>11){ h-=12;}
			if(0==h){ h=12;}
		}

		// minutes
		dc.setColor(timeColor, Gfx.COLOR_TRANSPARENT);
		dc.setPenWidth(1);
		var minutes = clockTime.min; 
		var angle =  minutes.toFloat()/30.0*Math.PI;
		v = circleWidth>>1+1;
		r = dialSize ? radius.toFloat() : 1.12*radius;
		var rX = r*Math.sin(angle);
		var rY = r*Math.cos(angle);
		
		var beta = angle + Math.PI/2;
		var offX = v*Math.sin(beta);
		var offY = v*Math.cos(beta);
		var gap = (0.1*r).toNumber();
		var gapX = gap*Math.sin(angle);
		var gapY = gap*Math.cos(angle);		
		dc.drawLine(Math.round(centerX+gapX+offX), Math.round(centerY-gapY-offY), Math.round(centerX+rX+offX), Math.round(centerY-rY-offY));
		beta = beta - Math.PI;
		offX = v*Math.sin(beta);
		offY = v*Math.cos(beta);
		dc.drawLine(Math.round(centerX+gapX+offX), Math.round(centerY-gapY-offY), Math.round(centerX+rX+offX), Math.round(centerY-rY-offY));
		angle = 360*angle/(2*Math.PI)-90;
		dc.drawArc(Math.round(centerX+rX), Math.round(centerY-rY), v, Gfx.ARC_CLOCKWISE, -angle+90, -angle-90);

		// Hours
		var mode24 = false;
		if(burnInProtection==0){ 
			angle =  h/(mode24==false ? 6.0 : 12.0)*Math.PI;
			dc.setColor(timeColor, Gfx.COLOR_TRANSPARENT);
			dc.drawText(Math.round(centerX + radius * Math.sin(angle)), Math.round(centerY - radius * Math.cos(angle)), fontSmall, h, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
		}
		if(mode24==false && h==12){h=0;}
		h = h.toFloat() + minutes.toFloat()/60;
		dc.setColor(color, Gfx.COLOR_TRANSPARENT);
		angle =  h/(mode24==false ? 6.0 : 12.0)*Math.PI;

		//r = (0.7*radius-circleWidth/4).toNumber();
		//dc.drawLine(centerX+Math.round(circleWidth*Math.sin(angle)/2), centerY-Math.round(circleWidth*Math.cos(angle)/2), Math.round(centerX+r*Math.sin(angle)), Math.round(centerY-r*Math.cos(angle)));
		//r = (0.7*radius).toNumber();
		//dc.fillCircle(centerX, centerY, v);dc.fillCircle(Math.round(centerX+r*Math.sin(angle)), Math.round(centerY-r*Math.cos(angle)), v);

		r = 0.7*radius;
		beta = angle + Math.PI/2;
		rX = r*Math.sin(angle);
		rY = r*Math.cos(angle);
		
		
		offX = v*Math.sin(beta);
		offY = v*Math.cos(beta);
		beta = beta - Math.PI;
		var offX2 = v*Math.sin(beta);
		var offY2 = v*Math.cos(beta);
		if(burnInProtection){ 
			dc.drawLine( 
				Math.round(centerX+offX), 		Math.round(centerY-offY), 
				Math.round(centerX+rX+offX), 	Math.round(centerY-rY-offY)); 
			dc.drawLine( 
				Math.round(centerX+rX+offX2), 	Math.round(centerY-rY-offY2),
				Math.round(centerX+offX2), 	Math.round(centerY-offY2));
			v=v-1;
			
			//dc.drawCircle(Math.round(centerX+rX), Math.round(centerY-rY), v);
			angle = 360*angle/(2*Math.PI)-90;
			dc.drawArc(Math.round(centerX+rX), Math.round(centerY-rY), v, Gfx.ARC_CLOCKWISE, -angle+90, -angle-90);
			
			//dc.drawCircle(centerX, centerY, v);
			dc.drawArc(Math.round(centerX), Math.round(centerY), v, Gfx.ARC_CLOCKWISE, -angle-90, -angle+90);
		} else {
			dc.fillPolygon( [
				[Math.round(centerX+offX), 		Math.round(centerY-offY)], 
				[Math.round(centerX+rX+offX), 	Math.round(centerY-rY-offY)], 
				[Math.round(centerX+rX+offX2), 	Math.round(centerY-rY-offY2)], 
				[Math.round(centerX+offX2), 	Math.round(centerY-offY2)]
			]);
			v=v-1;
			dc.fillCircle(Math.round(centerX+rX), Math.round(centerY-rY), v);
			dc.fillCircle(centerX, centerY, v);
		}
	}
	*/
	
	function drawTime (dc, writeMinute){
		// draw hour
		var h=clockTime.hour;
		var set = Sys.getDeviceSettings();
		if(set.is24Hour == false){
			if(h>11){ h-=12;}
			if(0==h){ h=12;}
		}
		// TODO if(set.notificationCount){dc.drawBitmap(centerX, notifY, iconNotification);}
		var minutes = clockTime.min; 
		// minutes=m; m++; // testing rendering
		//////Sys.println(minutes+ " mins mem " +Sys.getSystemStats().freeMemory);
		var angle =  minutes/60.0*2*Math.PI;
		var cos = Math.cos(angle);
		var sin = Math.sin(angle);
		var offset=0;
		var gap=0;
		dc.setColor(timeColor, Gfx.COLOR_TRANSPARENT);
		// TODO AOD overlapping 4>5 outlines etc // h=(h+7)%24; var d= new [24];for(var q=0;q<d.size();q++){d[q]=[0,0];}d[5]=[4,2];
		
		if(burnInProtection){ 
			//var stroke = (minutes==0 || minutes == 59 ) ? 3 : 1;
			var stroke=1;
			for(var i=0;i<4;i++){
				dc.drawText((i&1<<1-1)*stroke + centerX, (i&3>>1<<1-1)*stroke + centerY, fontHours, h.format("%0.1d"), Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER); 
			}
			dc.setColor(backgroundColor, Gfx.COLOR_TRANSPARENT);
			//if(stroke==2){
			//	for(var i=0;i<4;i++){
			//		dc.drawText(i&1<<1-1 + centerX,(i&3>>1<<1-1) + centerY-(dc.getFontHeight(fontHours)>>1), fontHours, h.format("%0.1d"), Gfx.TEXT_JUSTIFY_CENTER); 
			//	} 
			//}

		}  else { 
			dc.setColor(timeColor, Gfx.COLOR_TRANSPARENT);
			if (writeMinute) {
				dc.drawText(Math.round(centerX + (radius * sin)), Math.round(centerY - (radius * cos)) , fontSmall, minutes, Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
			}
		}
		dc.drawText(centerX, centerY, fontHours, h.format("%0.1d"), Gfx.TEXT_JUSTIFY_CENTER | Gfx.TEXT_JUSTIFY_VCENTER);
		if(minutes>0){
			if(burnInProtection){
				dc.setColor(color, backgroundColor);
				dc.setPenWidth(2);
				dc.drawArc(centerX, centerY, radius+4, Gfx.ARC_CLOCKWISE, 90, 92-minutes*6);

				dc.setColor(color, Gfx.COLOR_TRANSPARENT);
				dc.setPenWidth(10);
				dc.drawArc(centerX, centerY, radius, Gfx.ARC_CLOCKWISE, 95-minutes*6, 90-minutes*6);
			} else {
				dc.setColor(color, backgroundColor);
				dc.setPenWidth(circleWidth);

				if (writeMinute) {
					// correct kerning not to have wild gaps between arc and minutes number
					//	padding values in px:
					//	1: 		4 
					//	2-6: 	6 
					//	7-9: 	8 
					//	10-11: 	11 
					//	12-22: 	9 
					//	23-51: 	11 
					//	52-59: 	12
					//	59: start offsetted by 4
					if(minutes>=10){
						if(minutes>=52){
							offset=12;	// 52-59
							if(minutes==59){
								gap=4;	
							} 
						} else {
							if(minutes>=12 && minutes<=22){ // 12-22
								offset=9;
							} else {
								offset=11;	// 10-11+23-51
							}
						}
					} else {
						if(minutes>=7){
							offset=8;	// 7-9
						} else {
							if(minutes==1){
								offset=4;	// 1
							} else {
								offset=6;	// 2-6
							}
						}
					}
				}

				//dc.drawArc(centerX, centerY, radius, Gfx.ARC_CLOCKWISE, 90-gap, 90-minutes*6 + offset);
				//Sys.println([90-gap, 90-minutes*6 + offset]);
				dc.drawArc(centerX, centerY, radius, Gfx.ARC_CLOCKWISE, 90-gap, 90-minutes*6 + offset);
				//dc.drawArc(centerX, centerY, radius, Gfx.ARC_CLOCKWISE, 90, 270);

				if (circleWidth < 5) {
					dc.setColor(color, Gfx.COLOR_TRANSPARENT);
					dc.setPenWidth(circleWidth<<1);
					dc.drawArc(centerX, centerY, radius - circleWidth, Gfx.ARC_CLOCKWISE, 95-minutes*6, 90-minutes*6);
				}
			}
		}
	}

	function drawBatteryLevel (dc){
		var bat = Sys.getSystemStats().battery;
		if(bat<=batThreshold){
			var xPos = centerX-10;
			var yPos = batteryY;

			// print the remaining %
			//var str = bat.format("%d") + "%";
			dc.setColor(backgroundColor, backgroundColor);
			dc.setPenWidth(1);
			dc.fillRectangle(xPos,yPos,20, 10);
			dc.setColor(bat<=15 ? Gfx.COLOR_RED : activityColor, backgroundColor);

			// draw the battery
			dc.drawRectangle(xPos, yPos, 19, 10);
			dc.fillRectangle(xPos + 19, yPos + 3, 1, 4);

			var lvl = floor((15.0 * (bat / 99.0)));
			if (1.0 <= lvl) { dc.fillRectangle(xPos + 2, yPos + 2, lvl, 6); }
			else {
				dc.setColor(Gfx.COLOR_ORANGE, backgroundColor);
				dc.fillRectangle(xPos + 1, yPos + 1, 1, 8);
			}
		}
	}

	(:data)
	function trimPastHoursInWeatherHourly(){
		var h = Sys.getClockTime().hour; // first hour of the forecast
		if (weatherHourly instanceof Array && weatherHourly.size()>5){
			if(weatherHourly[0]!=h){ // delayed response or time passed
				var gap = 5+h-weatherHourly[0];
				if(weatherHourly[0]>h){	// the delay is over midnight 
					gap = gap + 24;
				}
				weatherHourly = [h].addAll(weatherHourly.slice(1,5)).addAll(weatherHourly.slice(gap,null));
				// DEBUG System.println(["trim", h, gap, weatherHourly]); 
			} else {
				return h;
			}
		} else {
			// DEBUG System.println(["not array", weatherHourly]); 
			weatherHourly = [];
			h = -1;
		}	
		app.setProperty("weatherHourly", weatherHourly);
		return h;
	}

	var dbg = null;
					
	function formatNumber(num, precision) {
		if (num == 0) {
			return "0";
		}

		var str = num.format("%1." + precision + "f");
		var strlen = str.length();
		var strch = str.toCharArray();

		var trailingZeros = 0;
		for (trailingZeros = 0; trailingZeros < strlen - 1; trailingZeros++) {
			var ch = strch[strlen - trailingZeros - 1];
			if (ch != '0' && ch != '.') {
				break;
			}
		}

		return str.substring(0, strlen - trailingZeros);
	}

	(:data)
	function drawWeather(dc){  //Sys.println("drawWeather: " + Sys.getSystemStats().freeMemory+ " " + weatherHourly); 
		var h = trimPastHoursInWeatherHourly();
		//Sys.println("weather from hour: "+h + " offset: "+offset);
		var limit; var step; var hours;
		if(d24){ 
			limit = 29; step = 15; hours = 24;
		} else {
			limit = 17; step = 30; hours = 12;
		}
			/// DEBUG if(dbg != clockTime.min ) {System.println(["limits", clockTime.min, h, limit, step, hours, weatherHourly.size(), meteoColors.size()]);} 
		
		if(h>=0){

			// DEBUG if(dbg != clockTime.min ) {dbg = clockTime.min;var debug = new [weatherHourly.size()]; var hh = h;for(var ii=0; ii<weatherHourly.size() && ii<limit; ii++, hh++){	var cc = weatherHourly[ii]; if(ii<5){debug[ii]=weatherHourly[ii];}						else {debug[ii]= (cc>=0 && cc < meteoColors.size()) ? meteoColors[cc] : null;}			}System.println(["arcs", debug]);}

			var prevColor = -1;
			//weatherHourly[10]=9;weatherHourly[12]=13;weatherHourly[13]=15;weatherHourly[15]=20;weatherHourly[16]=21; // testing colors

			// draw weather arcs
			dc.setPenWidth(5);
			for(var i=5; i<weatherHourly.size() && i<limit; i++, h++){
				var category; var offset;
				var color; var colorLow; var colorHigh;
				var correction; var cx; var cy;
				var startAngle; var endAngle;
				category = weatherHourly[i].toNumber();
				if (category == 0) { // clouds
					colorLow = 0x43484a;
					colorHigh = 0xd5dae2;
				} else if (category == 2) { // rain
					colorLow = 0x80a5d6;
					colorHigh = 0x4a80c7;
				} else if (category == 4) { // snow
					colorLow = 0xaba4db;
					colorHigh = 0x8c82ce;
				} else if (category == 6) { // sleet
					colorLow = 0x96a5d9;
					colorHigh = 0x6b81cb;
				} else {
					prevColor = -1;
					continue;
				}
				offset = Math.round((weatherHourly[i] - category)*4)/4.0;
				// if (category == 0) { category = 4; colorLow = 0x7799AA; colorHigh = 0xFFFFFF; }
				color = blendColors(colorLow, colorHigh, offset);
				h = h%hours;
				if(hours==12){
					correction = h>=2 && h<8 ? -1 : 0; // correcting the center is not in the center because the display resolution is even
				} else {
					correction = h>=4 && h<16 ? -1 : 0; // correcting the center is not in the center because the display resolution is even
				}
				cx = centerX + correction;
				cy = centerY + correction;
				startAngle = 450-h*step;
				endAngle = 450-(h+1)*step;
				dc.setColor(color, Gfx.COLOR_TRANSPARENT);
				//dc.drawArc(center, center, centerY-1, Gfx.ARC_CLOCKWISE, 15, 5);return;
				//Sys.println([h, 450-h*step, 450-(h+1)*step]);
				dc.drawArc(cx, cy, centerY-1, Gfx.ARC_CLOCKWISE, startAngle, endAngle);
				if (prevColor != -1) {
					startAngle += 3;

					var prevTransColor = prevColor;
					for (var t = 1; t <= 6; t += 1) {
						var transColor = blendColors(prevColor, color, t/7.0);
						dc.setColor(transColor, prevTransColor);
						dc.drawArc(cx, cy, centerY-1, Gfx.ARC_CLOCKWISE, startAngle, startAngle-1);
						prevTransColor = transColor;
						startAngle--;
					}
				}
				prevColor = color;
			}
			// write temperature
			if(weatherHourly.size()>=5){ 
				var x = centerX+centerX>>1+4;
				var y = centerY-0.5*(dc.getFontHeight(fontCondensed));
				var gap = 0; 
				if(dialSize==0){
					y -= centerY>>1;
					//x += gap;
				} else {
					//x += dc.getFontHeight(icons)>>1;
					y -= dc.getFontHeight(icons)>>1;
				}		
				var min = weatherHourly[2];
				var max = weatherHourly[3];
				var t = weatherHourly[1];
				//min=80;max=99;t=99;
				/*var range;
					if(max-min>1){	// now, min-max
						range = min.toString();
						if(min<0){
							if(max>0){
								range += "+";
							} else if(max == 0){
								range += "-";
							}
						} else {
							range += "-";
						}
						range += max.toString()+"°";
						x -= dc.getTextWidthInPixels(range, fontCondensed)>>1;
						dc.setColor(dimmedColor, Gfx.COLOR_TRANSPARENT);
						dc.drawText(x, y+line, fontCondensed, range, Gfx.TEXT_JUSTIFY_LEFT);
					} 
					dc.setColor(activityColor, Gfx.COLOR_TRANSPARENT);
					dc.drawText(x, y, fontCondensed, t+"°", Gfx.TEXT_JUSTIFY_LEFT);	
					*/
				//var line = Gfx.getFontHeight(fontCondensed).toNumber()-6;
				var line;
				//t=90;min=90;max=99;
				if(max-min>2 && dialSize==0){	// now-range	
					var c = activityColor;
					//TODO if NOW-Max OR Min-NOW
						var from; var to;
						if(t-min>max-t){
							from = min;
							to = t;
							c = dimmedColor;
						} else {
							from = t;
							to = max;
						}
						if(to>=0){
							if(from==t){
								if(to<100){	// tripple digits won't fit the screen
									to = (from>=0 || to == 0 ? "-" : "+") + to.toString();
								} else {
									to = "!";
								}
								from = from.toString()+ "°";
							} else {
								if(to<100){	// tripple digits won't fit the screen
									from = from.toString() + ( from>=0 || to == 0 ? "-" : "+");
								} else {
									from ="";
								}
								to = to.toString() + "°";
							}
						} else {
							if(from==t){
								from = from.toString()+"°";
								to = to.toString();
							} else {
								to = to.toString()+"°";
								from=from.toString();
							}
						}
						gap=((dc.getTextWidthInPixels(from, fontCondensed))-dc.getTextWidthInPixels(from+to, fontCondensed)>>1);




					var wd = dc.getTextWidthInPixels(from, fontCondensed)+dc.getTextWidthInPixels(to, fontCondensed)-dc.getTextWidthInPixels("°", fontCondensed)+2-10;
					var lineX = x+gap-1 - dc.getTextWidthInPixels(from, fontCondensed)+5;
					line = Gfx.getFontHeight(fontCondensed).toNumber();
					dc.setPenWidth(1);
					dc.setColor(dimmedColor, backgroundColor);
					dc.drawLine(lineX, y+line, lineX+wd, y+line);
					var bound = (t-min>max-t) ? lineX : lineX+wd;
					dc.drawLine(bound, y+line+1, bound, y+line+2);
					var pct = (t-min).toFloat()/(max-min);
					if (pct > 1) {
						pct = 1;
					}
					if (pct < 0) {
						pct = 0;
					}
					dc.setPenWidth(3);
					dc.setColor(activityColor, backgroundColor);
					dc.drawLine(lineX + pct*wd , y+line+1, lineX + pct*wd, y+line+2);

						//x -= dc.getTextWidthInPixels(range, fontCondensed)>>1;
						dc.setColor(c, Gfx.COLOR_TRANSPARENT);
						dc.drawText(x+gap-1, y, fontCondensed, from, Gfx.TEXT_JUSTIFY_RIGHT);
						c = c == activityColor ? dimmedColor : activityColor;
						dc.setColor(c, Gfx.COLOR_TRANSPARENT);
						dc.drawText(x+gap+1, y, fontCondensed, to, Gfx.TEXT_JUSTIFY_LEFT);	
					// else draw Min-Max in dimmedColor

				} else {
					dc.setColor(activityColor, Gfx.COLOR_TRANSPARENT);
					dc.drawText(x, y, fontCondensed, t+"°", Gfx.TEXT_JUSTIFY_CENTER);	
				}
				//dc.drawText(x, y, fontCondensed, Math.round(weatherHourly[1]).toString()+"°", Gfx.TEXT_JUSTIFY_CENTER);	
				// precipitation
				var mm = weatherHourly[4];
				if(mm != null && mm>0.01){
					mm = formatNumber(mm, 2);
					x = centerX-centerX>>1;
					//y -= (Gfx.getFontHeight(fontCondensed)*.2).toNumber();
					// quoteWidth
					// numWidth
					// totalWidth = quoteWidth + numWidth
					line = (dc.getTextWidthInPixels(mm + "\"", fontCondensed))>>1;
					dc.setColor(dimmedColor, Gfx.COLOR_TRANSPARENT);
					dc.drawText(x+line, y, fontCondensed, "\"", Gfx.TEXT_JUSTIFY_RIGHT);	
					dc.setColor(activityColor, Gfx.COLOR_TRANSPARENT);
					dc.drawText(x-line, y, fontCondensed, mm, Gfx.TEXT_JUSTIFY_LEFT);	
				}
				//dc.setPenWidth(circleWidth);dc.drawArc(centerX, centerY, radius, Gfx.ARC_CLOCKWISE, 90, 90-350); // test overlapping
			}
		}
	}
	(:nodata) function drawWeather(dc){ return false;}
	
	/*function abs(a){
		return a>=0 ? a : -a;
	}*/

	function toAngle(t){
		return (t + t.toNumber()%24-t.toNumber());
	}

	function drawIconAtTime(dc, t, icon){
		 var a = toAngle(t) * Math.PI/ (d24 ? 12.0 : 6.0 ) ; // radians (*= 60 * 2*PI/(24*60))  
		 drawIcon(dc, centerX + sunR*Math.sin(a), centerY - sunR*Math.cos(a), icon);
	}

	function drawLineAtTime(dc, t, length, offset) {
		var a = toAngle(t) * Math.PI/ (d24 ? 12.0 : 6.0 ) ; // radians (*= 60 * 2*PI/(24*60))  
		var r = centerY - offset;
		var ir = r - length;
		var c = Math.cos(a);
		var s = Math.sin(a);
		dc.drawLine(centerX+(r*s), centerY-(r*c),centerX+(ir*s), centerY-(ir*c));
	}

	function drawSunBitmaps (dc, cal) {
		if(day != cal.day || utcOffset != clockTime.timeZoneOffset ){ // TODO should be recalculated rather when passing sunrise/sunset
			computeSun();
		}
//sunrise = 5.0;sunset = 22.0;
		if(sunrise!= null) {
			var length = 6;
			dc.setPenWidth(4);
			if(d24){
				dc.setColor(0xFFAA00, Gfx.COLOR_TRANSPARENT);
				drawLineAtTime(dc, sunrise, length, 2);	// sun
				dc.setColor(0xDDDDDD, Gfx.COLOR_TRANSPARENT);
				drawLineAtTime(dc, sunset, length, 2);	// moon
				//Sys.println([sunrise, sunset]);
			} else {
				var time = clockTime.hour + clockTime.min/60.0;
				if(time>sunrise && time<=sunset ){
					dc.setColor(0xDDDDDD, Gfx.COLOR_TRANSPARENT);
					drawLineAtTime(dc, sunset, length, 2);	// moon						
				} else {
					dc.setColor(0xFFAA00, Gfx.COLOR_TRANSPARENT);
					drawLineAtTime(dc, sunrise, length, 2);	// sun
				}
				//Sys.println([time, sunrise, sunset]);
			}

			//Sys.println(sunset.toNumber()+":"+(sunset.toFloat()*60-sunset.toNumber()*60).format("%1.0d")); /*dc.setColor(0x555555, 0); dc.drawText(centerX + (r * Math.sin(a))+moon.getWidth()+2, centerY - (r * Math.cos(a))-moon.getWidth()>>1, fontCondensed, sunset.toNumber()+":"+(sunset.toFloat()*60-sunset.toNumber()*60).format("%1.0d"), Gfx.TEXT_JUSTIFY_VCENTER|Gfx.TEXT_JUSTIFY_LEFT);*//*a = (clockTime.hour*60+clockTime.min).toFloat()/1440*360; System.println(a + " " + (centerX + (r*Math.sin(a))) + " " +(centerY - (r*Math.cos(a)))); dc.drawArc(centerX, centerY, 100, Gfx.ARC_CLOCKWISE, 90-a+2, 90-a);*/
		}
	}

	function computeSun() {	//var t = Calendar.info(Time.now(), Calendar.FORMAT_SHORT);//+Sys.println(t.hour +":"+ t.min + " computeSun: " + App.getApp().getProperty("location") + " accuracy: "+ Activity.getActivityInfo().accuracy);
		var loc = app.locate(true);

		if(loc == null){
			sunrise = null;
			return;
		}	
		// use absolute to get west as positive
		var lonW = loc[1].toFloat();
		var latN = loc[0].toFloat();


		// compute current date as day number from beg of year
		utcOffset = clockTime.timeZoneOffset;

		var timeInfo = Calendar.info(Time.now().add(new Time.Duration(utcOffset)), Calendar.FORMAT_SHORT);

		day = timeInfo.day;
		var now = dayOfYear(timeInfo.day, timeInfo.month, timeInfo.year);
		/////Sys.println("dayOfYear: " + now.format("%d"));
		sunrise = computeSunriset(now, lonW, latN, true);
		sunset = computeSunriset(now, lonW, latN, false);

		/*// max
		var max;
		if (latN >= 0){
			max = dayOfYear(21, 6, timeInfo.year);
			/////Sys.println("We are in NORTH hemisphere");
		} else{
			max = dayOfYear(21,12,timeInfo.year);			
			/////Sys.println("We are in SOUTH hemisphere");
		}
		sunrise[SUNRISET_MAX] = computeSunriset(max, lonW, latN, true);
		sunset[SUNRISET_MAX] = computeSunriset(max, lonW, latN, false);
		*/

		//adjust to timezone + dst when active
		var offset=new Time.Duration(utcOffset).value()/3600;
		sunrise += offset;
		sunset += offset;

		if(sunrise<0){
			sunrise += 24;
		} else if(sunrise>24){
			sunrise -= 24;
		}

		if(sunset<0){
			sunset += 24;
		} else if(sunset>24){
			sunset -= 24;
		}

		/*for (var i = 0; i < SUNRISET_NBR; i++){
			sunrise[i] += offset;
			sunset[i] += offset;
		}


		for (var i = 0; i < SUNRISET_NBR-1 && SUNRISET_NBR>1; i++){
			if (sunrise[i]<sunrise[i+1]){
				sunrise[i+1]=sunrise[i];
			}
			if (sunset[i]>sunset[i+1]){
				sunset[i+1]=sunset[i];
			}
		}*/

		/*var sunriseInfoStr = new [SUNRISET_NBR]; var sunsetInfoStr = new [SUNRISET_NBR]; for (var i = 0; i < SUNRISET_NBR; i++){sunriseInfoStr[i] = Lang.format("$1$:$2$", [sunrise[i].toNumber() % 24, ((sunrise[i] - sunrise[i].toNumber()) * 60).format("%.2d")]); sunsetInfoStr[i] = Lang.format("$1$:$2$", [sunset[i].toNumber() % 24, ((sunset[i] - sunset[i].toNumber()) * 60).format("%.2d")]); //var str = i+":"+ "sunrise:" + sunriseInfoStr[i] + " | sunset:" + sunsetInfoStr[i]; /////Sys.println(str);}*/
		return;
	}
}