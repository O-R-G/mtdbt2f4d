/**
 * Video Export
 * Simple video file exporter.
 * http://funprogramming.org/VideoExport-for-Processing
 *
 * Copyright (c) 2015 Abe Pazos http://hamoid.com
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General
 * Public License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA 02111-1307 USA
 *
 * @author Abe Pazos http://hamoid.com
 * @modified 09/08/2015
 * @version 0.0.7 (7)
 */

/**
 * Modified by O-R-G -- 2016/2/12
 * 
 * added sound input from specified input file
 * removed sound input for mtdbt2f4d version
 */

import java.io.File;
import java.io.OutputStream;
import java.util.prefs.Preferences;

import processing.core.PApplet;
import processing.core.PGraphics;

/**
 *
 * @example basic
 *
 */

public class VideoExport {

  protected ProcessBuilder processBuilder;
  protected Process process;
  protected boolean initialized = false;

  protected final byte[] pixelsByte;

  protected boolean loadPixelsEnabled = true;
  protected final String outputFilePath;
  protected final String inputFilePath;

  protected PGraphics pg;
  protected final PApplet parent;

  protected final String ffmpegMetadataComment = "Exported using VideoExport for Processing - https://github.com/hamoid/VideoExport-for-Processing";
  protected int ffmpegCrfQuality;
  protected float ffmpegFrameRate;
  protected boolean ffmpegFound = false;
  protected File ffmpegOutputMsg;
  protected OutputStream ffmpeg;

  protected final Preferences settings;
  protected final String SETTINGS_FFMPEG_PATH = "settings_ffmpeg_path";
  protected final String FFMPEG_PATH_UNSET = "ffmpeg_path_unset";

  public final String VERSION = "0.0.7";

  /**
   	 * Constructor, usually called in the setup() method in your sketch to
   	 * initialize and start the library.
   	 *
   	 * @example basic
   	 * @param parent
   	 *            Parent PApplet, normally "this" when called from setup()
   	 * @param outputFileName
   	 *            The name of the video file to produce, for instance
   	 *            "beauty.mp4"
   	 */
  public VideoExport(PApplet parent, String outputFileName, String inputFileName) {
    this(parent, outputFileName, inputFileName, parent.g);
  }

  /**
   	 *
   	 * Constructor that allows to set a PGraphics to export as video (advanced)
   	 *
   	 * @example usingPGraphics
   	 * @param parent
   	 *            Parent PApplet, normally "this" when called from setup()
   	 * @param outputFileName
   	 *            The name of the video file to produce, for instance
   	 *            "beauty.mp4"
   	 * @param pg
   	 *            PGraphics object to export as video
   	 */
  public VideoExport(PApplet parent, String outputFileName, String inputFileName, PGraphics pg) {
    parent.registerMethod("dispose", this);

    this.parent = parent;
    this.pg = pg;

    settings = Preferences.userRoot().node(this.getClass().getName());

    outputFilePath = parent.sketchPath(outputFileName);
    ffmpegFrameRate = 30f;
    ffmpegCrfQuality = 15;

    inputFilePath = parent.sketchPath(inputFileName);    // sound file or stream

    if (pg == null) {
      pixelsByte = null;
      err("Did you initialize your PGraphics?");
    } else if (pg.width == 0) {
      pixelsByte = null;
      err("The display width is 0. Please call size() before instantiating VideoExport.");
    } else {
      pixelsByte = new byte[pg.width * pg.height * 3];
    }
  }

  /**
   	 * Set the PGraphics element. Advanced use only. Optional.
   	 *
   	 * @param pg
   	 *            A PGraphics object. Probably only called when working with an
   	 *            array of PGraphics objects.
   	 *
   	 */
  public void setGraphics(PGraphics pg) {
    this.pg = pg;
  }

  /**
   	 * Set the quality of the produced video file. Optional.
   	 *
   	 * @param crf
   	 *            A value between 0 (high compression) and 100 (high quality,
   	 *            lossless). Default is 70.
   	 */
  public void setQuality(int crf) {
    if (ffmpeg != null) {
      System.err.println("Can't setQuality() after saveFrame()!");
      return;
    }
    if (crf > 100) {
      crf = 100;
    } else if (crf < 0) {
      crf = 0;
    }
    ffmpegCrfQuality = (100 - crf) / 2;
  }

  /**
   	 * Set the frame rate of the produced video file. Optional.
   	 *
   	 * @param frameRate
   	 *            The frame rate at which the resulting video file should be
   	 *            played. The default is 30, which is the recommended for online
   	 *            video.
   	 */
  public void setFrameRate(float frameRate) {
    if (ffmpeg != null) {
      System.err.println("Can't setFrameRate() after saveFrame()!");
      return;
    }
    ffmpegFrameRate = frameRate;
  }

  /**
   	 * Tells VideoExport not to call loadPixels(). Use it only if you
   	 * already call loadPixels() in your program. Useful to avoid calling it
   	 * twice, which might hurt the performance a bit. Optional.
   	 */
  public void dontCallLoadPixels() {
    loadPixelsEnabled = false;
  }

  /**
   	 * Adds one frame to the video file. The frame will be the content of the
   	 * display, or the content of a PGraphics if you specified one in the
   	 * constructor.
   	 */
  public void saveFrame() {
    if (!initialized) {
      initialize();
      initialized = true;
    }
    if (!ffmpegFound) {
      return;
    }
    if (loadPixelsEnabled) {
      pg.loadPixels();
    }
    int byteNum = 0;
    for (final int px : pg.pixels) {
      pixelsByte[byteNum++] = (byte) (px >> 16);
      pixelsByte[byteNum++] = (byte) (px >> 8);
      pixelsByte[byteNum++] = (byte) (px);
    }
    try {
      ffmpeg.write(pixelsByte);
    } 
    catch (Exception e) {
      e.printStackTrace();
      err();
    }
  }

  /**
   	 * Makes the library forget about where the ffmpeg binary was located.
   	 * Useful if you moved ffmpeg to a different location. After calling this
   	 * function the library will ask you again for the location of ffmpeg.
   	 * Optional.
   	 */
  public void forgetFfmpegPath() {
    settings.put(SETTINGS_FFMPEG_PATH, FFMPEG_PATH_UNSET);
  }

  /**
   	 * Called automatically by Processing to clean up before shut down
   	 */
  public void dispose() {
    if (ffmpeg != null) {
      try {
        ffmpeg.flush();
        ffmpeg.close();
      } 
      catch (Exception e) {
        e.printStackTrace();
      }
    }
    if (process != null) {
      process.destroy();
    }
  }

  /**
   	 * Return the version of the library.
   	 *
   	 * @return String
   	 */
  public String version() {
    return VERSION;
  }

  protected void initialize() {
    String ffmpeg_path = settings.get(SETTINGS_FFMPEG_PATH, 
    FFMPEG_PATH_UNSET);
    if (ffmpeg_path.equals(FFMPEG_PATH_UNSET)) {
      String[] guess_path = { 
        "/usr/local/bin/ffmpeg", 
        "/usr/bin/ffmpeg"
      };
      for (String guess : guess_path) {
        if ((new File(guess)).isFile()) {
          ffmpeg_path = guess;
          settings.put(SETTINGS_FFMPEG_PATH, ffmpeg_path);
          break;
        }
      }
    }
    if (ffmpeg_path.equals(FFMPEG_PATH_UNSET)) {
      parent.selectInput(
      "Please select the ffmpeg or ffmpeg.exe executable", 
      "onFfmpegSelected", new File("/"), this);
    } else {
      startFfmpeg(ffmpeg_path);
    }
  }

  /**
   	 * Called internally by the file selector when the user chooses
   	 * the location of ffmpeg on the disk.
   	 *
   	 * @param selection
   	 */
  public void onFfmpegSelected(File selection) {
    if (selection == null) {
      System.err.println("Ffmpeg not found.");
    } else {
      String ffmpeg_path = selection.getAbsolutePath();
      settings.put(SETTINGS_FFMPEG_PATH, ffmpeg_path);
      startFfmpeg(ffmpeg_path);
    }
  }

  // ffmpeg -i input -c:v libx264 -crf 20 -maxrate 400k -bufsize 1835k
  // output.mp4
  // -profile:v baseline -level 3.0
  // https://trac.ffmpeg.org/wiki/Encode/H.264#Compatibility
  private void startFfmpeg(String executable) {
    // -y = overwrite, otherwise it fails the second time you run
    // -an = no audio
    // "-b:v", "3000k" = video bit rate
    // "-i", "-" = pipe:0

    /* 
     // audio
     
     processBuilder = new ProcessBuilder(executable, "-y", "-f", "rawvideo", 
     "-vcodec", "rawvideo", "-s", pg.width + "x" + pg.height, 
     "-pix_fmt", "rgb24", "-r", "" + ffmpegFrameRate, "-i", "-", 
     "-i", parent.sketchPath(inputFilePath), "-acodec", "libfdk_aac", 
     "-vcodec", "h264", "-pix_fmt", "yuv420p", "-crf", 
     "" + ffmpegCrfQuality, "-metadata", 
     "comment=" + ffmpegMetadataComment, outputFilePath);
     */
	
    // no audio 

    processBuilder = new ProcessBuilder(executable, "-y", "-f", "rawvideo", 
    "-vcodec", "rawvideo", "-s", pg.width + "x" + pg.height, 
    "-pix_fmt", "rgb24", "-r", "" + ffmpegFrameRate, "-i", "-", 
    "-an", 
    "-vcodec", "h264", "-pix_fmt", "yuv420p", "-crf", 
    "" + ffmpegCrfQuality, "-metadata", 
    "comment=" + ffmpegMetadataComment, outputFilePath);

    processBuilder.redirectErrorStream(true);
    ffmpegOutputMsg = new File(outputFilePath + ".txt");
    processBuilder.redirectOutput(ffmpegOutputMsg);
    processBuilder.redirectInput(ProcessBuilder.Redirect.PIPE);
    try {
      process = processBuilder.start();
    } 
    catch (Exception e) {
      e.printStackTrace();
      err();
    }

    ffmpeg = process.getOutputStream();

    ffmpegFound = true;
  }

  protected void err(String msg) {
    System.err.println("VideoExport error: " + msg);
    System.exit(1);
  }

  protected void err() {
    // err("Ffmpeg failed. Study " + ffmpegOutputMsg + " for more details.");
    err(processBuilder + " Ffmpeg failed. Study " + ffmpegOutputMsg + " for more details.");
  }
}

