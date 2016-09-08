// v7
// added VideoExport for Jumex
// prepared in making LETTER & SPIRIT for Chaumont
// reads from a file called Data/Script.txt
// then 'types' letter by letter with timed intervals
// and adds the ability to output directly to a Quicktime mov
// loads one range of MTDBT2F4D at a time
// runs with many more more fonts active at once by increasing memory size
// this version works with ranges from one set of 5000 MTDBT2F4Ds
// also bounces thisFont back and forth between range limits
// and enables recording of cues, and playback from Cues.txt
// added png & pdf output for KADIST logos
// to run as KADIST, use MTDBT2F4Dspecimen mode
// added live editing of Cues.txt with editCues
// need to document use of keys

// import processing.video.*;
import processing.pdf.*;    // comment if not exporting PDF for performance

// objects

// MovieMaker mm;    // Declare MovieMaker object
PrintWriter cuesWriter;   // text file with counter values as timing list
PFont font[];     // array of references to fonts
PFont display;   // for 4d specimen
VideoExport videoExport;

// modes 

boolean playback = true;  // playback mode, line by line from Script.txt using spacebar
boolean playbackAuto = false;  // playback mode, automatic timing between lines, no spacebar
boolean playbackCues = true;  // playback mode, from Script.txt using Cues.txt for timing
boolean recordCues = false; // using Printwriter, record counter values as cue points
boolean editCues = false; // using Printwriter, read in Cues.txt and live edit ('[' and ']') when paused, then write out on exit(); triggered by typing "e"
boolean playbackFonts = false;  // playback mode, using Fonts.txt for font change cue points
boolean generateMTDBT2F4Dspecimen = false; // generate MTDBT2F4D type specimen mov
boolean useVideoExport = true; // use Video Export library realtime ffmpeg output

// options 

boolean debug = false;
boolean displayCues = false; // show counter values onscreen during playbackCues
boolean outputQT = true; // using video library, write out to Quicktime mov
boolean outputRender = false; // output in non-real time (faster ... delaySpeed=0)
boolean output24fps = false; // adjust timing cues to render for film at 24fps as PDF (Chaumont)
boolean outputPDF = false; // using PDF library, write a sequence of pdf files
boolean outputPNG = false; // write a sequence of png files
boolean showFrames = false; // show jumex monitor frames

// settings 

// String MTDBT2F4Dspecimen = "Cwm-fjord-bank glyphs vext quiz."; // Cwm-fjord-bank glyphs vext quiz. KADIST
String MTDBT2F4Dspecimen = "Meta-the-difference-between-the-two-font-4-d"; // Cwm-fjord-bank glyphs vext quiz. KADIST
String displayHollowsTrigger = "Meta-the-difference-between-the-two-font-4-d"; // " [Meta-the-difference-between-the-two-font-4-D] magic phrase that turns on hollows display
// String displayHollowsTrigger = "----"; // " [Meta-the-difference-between-the-two-font-4-D] magic phrase that turns on hollows display
String fontDataFolder = "mtdbt2f-4d --steps 70 --exit 700 --weight 5 200 --slant -.2 .2 --super .5 .8 --pen 0 .333 3 0 720"; // folder name that contains MTDBT2F4D range
String QTFilename = "Letter-and-Spirit.mov"; // name for Quicktime output file
String pdfFilename = "Letter-and-Spirit"; // name for PDF file sequence
String pngFilename = "Letter-and-Spirit"; // name for PNG file sequence

// flags

boolean createMTDBT2F4Dbusy = true; // flag used when generating MTDBT2F4Ds
boolean playbackCuesPaused = false; // flag used playbackCues running
boolean displayHollows = true; // default = true, but flipped off after typed = displayHollowsTrigger
boolean showTimecode = false; // [false] for showing 24 fps time code on frame
boolean editCuesSave = false; // [false] to guarantee writing of cues[] file on exitClean

// arrays

String script[];  // loaded line by line from resources/Script.txt
String cues[];  // loaded line by line from resources/Cues.txt
String fonts[];  // loaded line by line from resources/Fonts.txt
String fontnames[];  // original source names used for naming pdf, png

// strings

String version = "cgi_v1"; // identifies subdirectory name for current resources folder
String typedDisplay = ""; // fix discrepancy in starting string values space or null
String typed = "*"; // default starting string
String editCueValue = null; // used to pass back edited cues value to set to cues[] in main loop
String thisFileout = null; // used for outputting fontnames[] in outputPNG / PDF

// ints

int counter = 0; // main counter -- increments in draw() loop when % delaySpeed == 0
int scriptLineCounter = 0;  // pointer to position in script[]
int cuesLineCounter = 0; // pointer to position in cues[]
int fontsLineCounter = 0; // pointer to position in fonts[]
int fontSize = 99;  // [44][54][66}[80][84][99][99*4] points
int fontLength = 0;  // length of font[] (computed when filled)
int thisFont = 0; // pointer to font[] of currently selected
int fontRangeStart = 0; // pointer to font[], range min
// int fontRangeEnd = 1100; // pointer to font[], range max
int fontRangeEnd = 510; // pointer to font[], range max
int fontLoadLimit = 1100; // maximum fonts to try in createMTDBT2F4D()
int fontRangeDirection = 1; // only two values, 1 or -1
int delaySpeed = 20;  // [20] milliseconds between draw() loops, for editing, adjust to match 30 fps avg using displayCues
int playbackAutoSpeed = 100;  // [100] number of loops (counter)
int outputPDFhoffset = 255;  // PDF automatically forgets the align center
int thisMillis = 0;  // for draw() loop timing debug
int thisBackground = 0;
int thisFill = 255;
int baselineAdjust = 20;	// [20] 40 jumex


void setup() {

  createMTDBT2F4D();

  // 1920 x 1080 normal full size uses fontSize 99
  // 1920 x 150 reduced for QT output
  // 854 x 621 35mm film size uses type size 54
  // 1024 x 768 XGA uses fontSize 60
  // 1440 x 1080 1080p resolution uses fontSize 84
  // 1280 x 720 is 720p resolution uses fontSize 66
  // 854 x 480 is 480p resolution uses fontSize 44
  // 5760 x 1080 for Jumex, fontsize 99*4

  int thisW = 1920;  // global width
  int thisH = 1080;  // global height

  /*
  if (outputQT) {
   mm = new MovieMaker(this, thisW, thisH, "out/mov/" + QTFilename, 30, MovieMaker.ANIMATION, MovieMaker.HIGH);
   if ( mm != null ) {
   println("Quicktime output to " + QTFilename);
   }
   }
   */

  // declare size after mm object 

  size(thisW, thisH);  // generic
  frame.setBackground(new java.awt.Color(0, 0, 0));

  frameRate(30); // this seems to matter

  background(thisBackground);
  fill(thisFill);
  textSize(fontSize);
  textAlign(CENTER);

  // hollows font

  String fontStub = "resources/" + version + "/Monaco.ttf"; // from sketch /data
  display = createFont(fontStub, 10, false);

  // load external files and make adjustments

  if (playback) {
    script = loadStrings("resources/" + version + "/Script.txt");
    typed = script[0];
    if (generateMTDBT2F4Dspecimen) { 
      typed = MTDBT2F4Dspecimen;
    }
    scriptLineCounter ++;
  }

  if (playbackCues) {
    // reads from Cues.txt file in data/resources/
    cues = loadStrings("resources/" + version + "/Cues.txt");
  }

  if (playbackFonts) {
    // reads from Fonts.txt file in data/resources/
    fonts = loadStrings("resources/" + version + "/Fonts.txt");
  }

  if (output24fps) {
    // adjust each cue value from 30 fps to 24 fps
    for ( int i = 0; i < cues.length; i++) {
      int thisCue = int(cues[i]);
      thisCue = (thisCue * 4) / 5;
      cues[i] = str(thisCue);
    }
  }

  if (recordCues) {
    // records to new text file stored in out/
    cuesWriter = createWriter("data/resources/" + version + "/Cues.txt");
  }

  if (editCues) {
    //  backup existing cues file
    cuesWriter = createWriter("data/resources/" + version + "/Cues-backup.txt");      
    writeCues(cuesWriter, true);

    // create new printWriter handle, set 
    editCuesSave = true;
    editCues = false;  // wait for editing to be turned on
  }  

  if (outputRender) {
    delaySpeed = 0;
  }  

  if (generateMTDBT2F4Dspecimen) { 
    playback = true;
    playbackAuto = false;
    recordCues = false;
    playbackCues = false;
    playbackFonts = false;
  }

  updateRangeMTDBT2F4D(0);

  // videoExport

  if (useVideoExport) {
    videoExport = new VideoExport(this, "out/mp4/out.mov", "data/audio/in.wav");
    videoExport.setFrameRate(30.0);
  }

  // debug to console

  if (debug) {
    println(font);
    println(fontLength);
    println(script.length + " lines");
    for (int i=0; i < script.length; i++) {
      println(script[i]);
    }
  }
}



void draw() { 

  if (createMTDBT2F4Dbusy == false) {

    // output PDF frames

    if (outputPDF) {
      if ( generateMTDBT2F4Dspecimen ) {
        thisFileout = fontnames[thisFont] + ".pdf";
      } else {
        thisFileout =  pdfFilename + "-####.pdf";
      }
      beginRecord(PDF, "out/pdf/" + thisFileout);  
      fill(thisFill);
      textAlign(CENTER);
    }

    background(thisBackground);
    textFont(font[thisFont]);     

    if (showFrames) {
      noFill();
      stroke(255);
      rect(0, 0, width/3, height);
      rect(width/3, 0, width*2/3, height);
      rect(width*2/3, 0, width, height);
      noStroke();
      // fill(thisFill);
    }

    // adjust mtdbt2f4d

    if ( ( thisFont + fontRangeDirection >= fontRangeStart ) && ( thisFont + fontRangeDirection <= fontRangeEnd ) ) {
      thisFont += fontRangeDirection;
    } else {
      fontRangeDirection *= -1; 
      thisFont += fontRangeDirection;
    }

    // main display

    if ( ( counter < typed.length() ) && ( !generateMTDBT2F4Dspecimen ) ) {   
      typedDisplay += typed.charAt(counter);
      text(typedDisplay, width/2, height/2 + baselineAdjust);
      counter++;
    } else {
      typedDisplay = typed;
      text(typedDisplay, width/2, height/2 + baselineAdjust);
      counter++;
    }

    // 4d type specimen

    if (generateMTDBT2F4Dspecimen) { 
      if ( counter > thisFont ) { 
        exitClean();
      } 
      textFont(display);
      if ( ( !outputPDF ) && ( !outputPNG ) ) {
        textAlign(LEFT);
        String thisTime = month() + "/" + day() + "/" + year() + " " + hour() + ":" + minute() + ":" + second() + "." + millis();
        String thisHollows = fontDataFolder + "\n" + thisTime + "\n" + font[thisFont] + "\nmtdbt2f4d-" + thisFont;
        text(thisHollows, 10, 20);  // number in font[]
        textAlign(CENTER);
      }
    } 

    // displayHollows

    if (displayHollows) {
      if ( typed.equals(displayHollowsTrigger) == true ) {
        if (showTimecode) {
          // output as SMPTE timecode
          textFont(display);
          textAlign(LEFT);
          int thisSecond = (int) counter / 24;
          int thisFrame = counter % 24;
          String thisSMPTE = "00 : 16 : " + thisSecond + " : " + thisFrame;
          String thisHollows = thisSMPTE;
          text(thisHollows, 20, 400);
          textAlign(CENTER);
        } else {
          // output as Terminal Hollows
          textFont(display);
          textAlign(LEFT);
          String thisTime = month() + "/" + day() + "/" + year() + " " + hour() + ":" + minute() + ":" + second() + "." + millis();
          String thisHollows = fontDataFolder + "\n" + thisTime + "\n" + font[thisFont] + "\nmtdbt2f4d-" + thisFont;
          text(thisHollows, 48, 20);  // number in font[]
          textAlign(CENTER);
        }
      }
    }

    // playback automatic

    if (playbackAuto) {
      if ((counter % playbackAutoSpeed) == 0) {
        typedDisplay ="";
        typed = script[scriptLineCounter];
        scriptLineCounter ++; 
        counter = 0;
        if ( ( scriptLineCounter > script.length ) || ( scriptLineCounter > cues.length )) {
          exitClean();
        }
      }
    }

    // playback cues

    if (playbackCues) {
      if ( ( scriptLineCounter < script.length ) || ( scriptLineCounter < cues.length )) {
        /*
        if (editCueValue != null) {
         // update the array value in this main loop, not in case statement
         cues[cuesLineCounter] = editCueValue;
         editCueValue = null;
         }
         */
        int thisCue = int(cues[cuesLineCounter]);

        if ( counter >= thisCue ) {
          typedDisplay ="";
          /*
          println("script.length = " + script.length);
          println("scriptLineCounter = " + scriptLineCounter);
          */
          if (scriptLineCounter < script.length) {
            typed = script[scriptLineCounter];
          } else {
            println("** exitClean **");
            exitClean();
          }

          if (playbackFonts) {
            updateRangeMTDBT2F4D(scriptLineCounter);
          }
          scriptLineCounter ++; 
          cuesLineCounter ++;
          counter = 0;
          if ( ( scriptLineCounter > script.length ) || ( scriptLineCounter > cues.length )) {
            exitClean();
          }
        }
      } else {
        exitClean();
      }
    }

    // display Cues

    if (displayCues) {
      String thisDisplay = (cuesLineCounter + 1) + " / " + cues[cuesLineCounter] + " : " + counter;

      thisMillis = millis() - thisMillis;  // milliseconds since this was last called
      thisDisplay += "\n" + delaySpeed + " > " + thisMillis + " fps";
      thisMillis = millis();

      thisDisplay += "\n" + thisFont + ".ttf";

      if (playbackCuesPaused) {
        thisDisplay = (cuesLineCounter + 1) + " / " + cues[cuesLineCounter] + " + paused +";
        if (editCues) {
          thisDisplay += " % editing %";
        }
      }

      textFont(display);
      textAlign(LEFT);
      if (editCues) {
        fill(0, 255, 0);
      }
      text(thisDisplay, 10, 20);  
      if (editCues) {
        fill(255);
      }
      textAlign(CENTER);
    } 

    // output QT frame

    /*
    if (outputQT) {
     mm.addFrame();  // Add window's pixels to movie
     if ( playback ) {  // catch if end of Script, stop recording
     if ( ( scriptLineCounter > script.length ) || ( scriptLineCounter > cues.length )) {
     exitClean();
     }
     }
     }
     */

    if (outputQT) {
      if (useVideoExport) {
        videoExport.saveFrame();
      } else {
        // alternate export method not implemented
      }
    }

    // stop PDF output

    if (outputPDF) {
      endRecord();
    }

    // export PNG sequence

    if (outputPNG) {
      if ( generateMTDBT2F4Dspecimen ) {
        thisFileout = fontnames[thisFont] + ".png";
      } else {
        thisFileout =  pngFilename + "-####.png";
      }
      saveFrame("out/png/" + thisFileout);
    }

    delay(delaySpeed);
  }
}



void keyPressed() {

  // append this key to the typed string 
  // or if RETURN then clear screen and start again
  // if DELETE then delete
  // check that we have not run out of room on-screen 
  // and if so, erase and begin again

  if (playback == true) {

    switch(key) {
    case ' ':  // go forward one line
      typedDisplay = "";
      if (scriptLineCounter < script.length) {
        typed = script[scriptLineCounter];
      }
      if (playbackFonts) {
        updateRangeMTDBT2F4D(scriptLineCounter);
      }
      scriptLineCounter ++; 
      cuesLineCounter ++; 
      if ( recordCues ) {
        cuesWriter.println(counter);
        if ( scriptLineCounter > script.length ) { 
          exitClean();
        }
      } else {
        if ( ( scriptLineCounter > script.length ) || ( scriptLineCounter > cues.length )) {
          exitClean();
        }
      }
      counter = 0;
      break;
    case '/':  // go back one line
      typedDisplay = "";
      scriptLineCounter --; 
      cuesLineCounter --; 
      if (scriptLineCounter < 0 ) {
        scriptLineCounter = 0;
      }
      if (cuesLineCounter < 0 ) {
        cuesLineCounter = 0;
      }
      typed = script[scriptLineCounter-1];
      if (playbackFonts) {
        updateRangeMTDBT2F4D(scriptLineCounter-1);
      }
      counter = 0;
      break;
    case '_':  // go back to home
      typedDisplay = "";
      scriptLineCounter = 0; 
      typed = script[scriptLineCounter];
      if (playbackFonts) {
        updateRangeMTDBT2F4D(scriptLineCounter);
      }
      counter = 0;
      break;
    case '+':  // faster
      delaySpeed -= 1;  
      if (delaySpeed < 0) {
        delaySpeed = 0;
      }  
      println("delaySpeed = " + delaySpeed);
      break;
    case '=':  // slower
      delaySpeed += 1;    
      println("delaySpeed = " + delaySpeed);
      break;
    case '-':  // pause
      if (playbackCues) {
        playbackCues = false;
        playbackCuesPaused = true;
        displayCues = true;
      } else {
        playbackCues = true;
        playbackCuesPaused = false;
        typed = "";              
        if (editCues) {
          // write out changes to Cues.txt and reset
          writeCues(cuesWriter, true);
          editCues = false;
        }
        script = loadStrings("resources/" + version + "/Script.txt"); // refresh script from file
        cues = loadStrings("resources/" + version + "/Cues.txt"); // refresh cues from file
        if (playbackFonts) {
          fonts = loadStrings("resources/" + version + "/Fonts.txt"); // refresh script from file
          updateRangeMTDBT2F4D(scriptLineCounter);
        }
        counter = int(cues[cuesLineCounter]) - 1; // resume
      }
      break;
    case 'd':  // displayCues
      if (displayCues == true ) {
        displayCues = false;
      } else {
        displayCues = true;
      }
      break;
    case 'e':  // editCues
      if (playbackCuesPaused) {
        editCues = true;
        cuesWriter = createWriter("data/resources/" + version + "/Cues.txt");
      } 
      break;
    case '[':  // editCues minus
      if (editCues) {
        if ( (cuesLineCounter >= 0) && (cuesLineCounter < cues.length) ) {
          int thisEditedCue = int(cues[cuesLineCounter]);
          thisEditedCue -= 1;
          cues[cuesLineCounter] = str(thisEditedCue);
        }
      } 
      break;
    case ']':  // editCues plus
      if (editCues) {
        if ( (cuesLineCounter >= 0) && (cuesLineCounter < cues.length) ) {
          int thisEditedCue = int(cues[cuesLineCounter]);
          thisEditedCue += 1;
          cues[cuesLineCounter] = str(thisEditedCue);
        }
      } 
      break;
    case 'f':  // set new fontRange (random, minimum 50)
      fontRangeStart = (int) random(0, fontLength - 51);
      fontRangeEnd = (int) random(fontRangeStart + 50, fontLength - 1);
      thisFont = fontRangeStart;
      break;      
    case ESC:  // stop recording 
      exitClean();
    default:
    }
  } else {
    switch(key) {
    case RETURN: 
      typed = "";
      break;
    case ENTER: 
      typed = "";
      break;
    case BACKSPACE: 
      if (typed.length() > 0) {
        typed = typed.substring(0, typed.length()-1);
      }
      break;
    case DELETE: 
      if (typed.length() > 0) {
        typed = typed.substring(0, typed.length()-1);
      }
      break;
    case '+':  // faster
      delaySpeed -= 1;
      if (delaySpeed < 0) {
        delaySpeed = 0;
      }
      println("delaySpeed = " + delaySpeed);
      break;
    case '=':  // slower
      delaySpeed += 1;    
      println("delaySpeed = " + delaySpeed);
      break; 
    default:
      if (createMTDBT2F4Dbusy) {
        typed = "";
      } 
      typed += key;
    }
  }

  if (debug) {
    println(typed);
  }
}



void createMTDBT2F4D()
{

  // createFont() works either from data folder or from installed fonts
  // renders with installed fonts if in regular JAVA2D mode
  // the fonts installed in sketch data folder make it possible to export standalone app
  // but the performance seems to suffer a little. also requires appending extension .ttf
  // biggest issue is that redundantly named fonts create referencing problems

  if ( fontRangeEnd - fontRangeStart  > fontLoadLimit ) {
    fontLoadLimit = fontRangeEnd - fontRangeStart;
  }

  font = new PFont[fontLoadLimit];
  fontnames = new String[fontLoadLimit];
  fontLength = 0; // reset

  for ( int i = 0; i < fontLoadLimit; i++ ) {  
    String fontStub = fontDataFolder + "/mtdbt2f4d-" + i + ".ttf"; // from sketch /data

    if ( createFont(fontStub, fontSize, true) != null ) {
      font[fontLength] = createFont(fontStub, fontSize, true);
      fontnames[fontLength] = "mtdbt2f4d-" + i;
      println("/mtdbt2f4d-" + i + ".ttf" + " ** OK **");
      fontLength++;
    }
  }

  // in range? catch errors

  if ( fontRangeEnd - fontRangeStart > fontLength ) {
    fontRangeEnd = fontLength - 1;
  }

  println("** init complete -- " + fontLength + " / " + font.length + " **");
  createMTDBT2F4Dbusy = false;
}



void updateRangeMTDBT2F4D(int thisFontsLineCounter)
{

  // uses Fonts.txt file from data/resources as a cue list for keeping track of which fontRanges when in Script.txt
  // this function called to update fontRangeStart and fontRangeEnd 

  int fontRangeStartPrevious = fontRangeStart;
  int fontRangeEndPrevious = fontRangeEnd;

  if (playbackFonts) {

    int[] thisFontRange = int(split(fonts[thisFontsLineCounter], '-'));
    fontRangeStart = thisFontRange[0];  
    fontRangeEnd = thisFontRange[1];
  }

  // in range?

  if ( ( fontRangeStart < 0 ) || ( fontRangeStart > fontLength - 1 ) ) {
    fontRangeStart = 0;
  } 
  if ( ( fontRangeEnd < 0 ) || ( fontRangeEnd > fontLength - 1 ) ) {
    fontRangeEnd = fontLength - 1;
  }

  /*
  // "nudge" thisFont into new range
   
   if ( thisFont < fontRangeStart ) {
   thisFont = fontRangeStart + 1;
   }
   if ( thisFont > fontRangeEnd ) {  
   thisFont = fontRangeEnd - 1;
   }
   */

  // "bump" thisFont into new range
  if ( ( fontRangeStart != fontRangeStartPrevious ) || (  fontRangeEnd != fontRangeEndPrevious )  ) {
    thisFont = fontRangeStart;
  }
}



void writeCues(PrintWriter thisCuesWriter, boolean closeFile) {

  // using printWriter file handle passed output cues[] and close
  for ( int i = 0; i < cues.length; i++) {
    thisCuesWriter.println(cues[i]);
  }
  if (closeFile) {
    thisCuesWriter.flush(); 
    thisCuesWriter.close();
  }
}



void exitClean()
{

  // if reach end of Scripts.txt, Cues.txt, Fonts.txt then  
  // close QT and / or Cues.txt and exit program

  /*
  if (outputQT) {
   mm.finish();
   }
   */
  if (recordCues) {
    cuesWriter.println(counter);
    cuesWriter.flush(); 
    cuesWriter.close();
  }
  if (editCuesSave) {
    writeCues(cuesWriter, true);
  }
  exit();
}

