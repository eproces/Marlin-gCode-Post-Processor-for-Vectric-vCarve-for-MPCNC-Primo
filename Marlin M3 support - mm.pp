+===========================================================================
|
| gCode - Vectric machine output post-processor for vCarve and Aspire
|
+===========================================================================
|
| History
|
| Who       When       What
| ========  ========== =====================================================
| EdwardW   01/13/2020 Initial authoring
|                      Added status messages (M117)
|                      Enabled Arc movements (G2/G3)
|                      Added ending presentation
| EdwardW   02/28/2020
|                      Added G54 (CNC) coordinate support
| EdwardW   10/26/2021
|                      Added router control (M3/M5)
| EdwardW   12/14/2021
|                      Added helical-arc support
|                      Changed to unix line endings
|                      Improved comments
|                      Increased plunge speed when above material
|                      Now uses machine default rapid move speed
|                      Disabled PLUNGE_RATE section to avoid slowdowns
|                      Comments now report carved Z depth, not material Z
| EdwardW   1/22/2022
|                      Minor tweaks and comment updates
| Ash       3/5/24
|                      Customize for my MPCNC Primo
|                      Router control is now via fan relay (M106/M107)
|                      Integrated "test5" postprocessor from V1E forums:
| MikeK     13/12/2015 Written
| JohnP     02/03/2017 Added multi-tool with pause
| RyanZ     16/01/2018 Feedrate adjustments
+===========================================================================

POST_NAME = "Marlin MPCNC (mm) (*.gcode)"

FILE_EXTENSION = "gcode"

UNITS = "mm"

+---------------------------------------------------------------------------
|    Configurable items based on your CNC
+---------------------------------------------------------------------------
+ Use 1-100 (%) for spindle speeds instead of true speeds of 10000-27500 (rpm)
+ SPINDLE_SPEED_RANGE = 1 100 10000 27500

+ Replace all () with <> to avoid gCode interpretation errors
SUBSTITUTE = "([91])[93]"

+ Plunge moves to Plunge (Z2) height are rapid moves
+ RAPID_PLUNGE_TO_STARTZ = "YES"

+---------------------------------------------------------------------------
|    Line terminating characters
+---------------------------------------------------------------------------
+ Use windows-based line endings \r\n
LINE_ENDING = "[13][10]"

+ Use unix-based line endings \n
+ LINE_ENDING = "[10]"

+---------------------------------------------------------------------------
|    Block numbering
+---------------------------------------------------------------------------
LINE_NUMBER_START     = 0
LINE_NUMBER_INCREMENT = 10
LINE_NUMBER_MAXIMUM = 999999

+===========================================================================
|
|    Formatting for variables
|
+===========================================================================

VAR LINE_NUMBER = [N|A|N|1.0]
VAR SPINDLE_SPEED = [S|A|S|1.0]
VAR FEED_RATE = [F|A|F|1.1]
VAR CUT_RATE = [FC|A|F|1.1]
VAR PLUNGE_RATE = [FP|A|F|1.1]
VAR X_POSITION = [X|C| X|1.3]
VAR Y_POSITION = [Y|C| Y|1.3]
VAR Z_POSITION = [Z|C| Z|1.3]
VAR ARC_CENTRE_I_INC_POSITION = [I|A| I|1.3]
VAR ARC_CENTRE_J_INC_POSITION = [J|A| J|1.3]
VAR X_HOME_POSITION = [XH|A| X|1.3]
VAR Y_HOME_POSITION = [YH|A| Y|1.3]
VAR Z_HOME_POSITION = [ZH|A| Z|1.3]
VAR X_LENGTH = [XLENGTH|A||1.0]
VAR Y_LENGTH = [YLENGTH|A||1.0]
VAR Z_LENGTH = [ZLENGTH|A||1.0]
VAR Z_MIN = [ZMIN|A||1.0]
VAR SAFE_Z_HEIGHT = [SAFEZ|A||1.3]
VAR DWELL_TIME = [DWELL|A|S|1.2]


+===========================================================================
|
|    Block definitions for toolpath output
|
+===========================================================================

+---------------------------------------------------------------------------
|  Start of file output
+---------------------------------------------------------------------------
begin HEADER

"; [TP_FILENAME]"
"; Material size: [YLENGTH] x [XLENGTH] x [ZMIN]mm"
"; Tools: [TOOLS_USED]"
"; Paths: [TOOLPATHS_OUTPUT]"
"; Safe Z: [SAFEZ]mm"
"; Generated on [DATE] [TIME] by [PRODUCT]"
"G90"
"G21"
"M84 S0"
"M117 [YLENGTH]x[XLENGTH]x[ZMIN]mm  Bit #[T]"
"M117 Load [TOOLNAME]"
"M0 Load [TOOLNAME]"
"G00 X0.000 Y0.000 Z0.000"
"G1 Z[SAFEZ] F500"
"G1 [XH] [YH] [F]"
"M106"
";==========================================================================="
";"
";      Path: [TOOLPATH_NAME]"
";      Tool: #[T] : [TOOLNAME]"
";"
";==========================================================================="
"M117 [TOOLPATH_NAME] - Bit #[T]"

+---------------------------------------------------------------------------
|  Rapid (no load) move
+---------------------------------------------------------------------------
begin RAPID_MOVE

"G0 [X] [Y] [Z] [F]"

+---------------------------------------------------------------------------
|  Carving move
+---------------------------------------------------------------------------
begin FEED_MOVE

"G1 [X][Y][Z] [FC]"

+---------------------------------------------------------------------------
|  Plunging move - Only enable if necessary. Can cause huge slowdowns
+---------------------------------------------------------------------------
begin PLUNGE_MOVE

"G1 [X][Y][Z] [FP]"

+---------------------------------------------------------------------------
|  Clockwise arc move
+---------------------------------------------------------------------------
+begin CW_ARC_MOVE

+"G2 [X][Y][I][J] [FC]"

+---------------------------------------------------------------------------
|  Counterclockwise arc move
+---------------------------------------------------------------------------
+begin CCW_ARC_MOVE

+"G3 [X][Y][I][J] [FC]"

+---------------------------------------------------
+  Clockwise helical-arc move
+---------------------------------------------------
+begin CW_HELICAL_ARC_MOVE

+"G2 [X][Y][Z][I][J] [FC]"

+---------------------------------------------------
+  Counterclockwise helical-arc move
+---------------------------------------------------
+begin CCW_HELICAL_ARC_MOVE

+"G3 [X][Y][Z][I][J] [FC]"

+---------------------------------------------------
+  Commands output for tool changes
+---------------------------------------------------

begin TOOLCHANGE

"; Tool change:"
"; Tool [T]: [TOOLNAME]"
"M117 CHANGING TOOL"
"M107 ; STOP SPINDLE"
"M25"
"G1 Z[SAFEZ] F500"
"G0 X10 Y10 F500"
"G1 Z0"
"M84 S900 ; KEEP STEPPERS ON FOR 15MIN"
"M18 Z ; RELEASE Z"
"M300 P300 S440 ; BEEP"
"M0 Load [TOOLNAME]"

+---------------------------------------------------------------------------
|  Begin new toolpath
+---------------------------------------------------------------------------
begin NEW_SEGMENT

";==========================================================================="
";"
";      Path: [TOOLPATH_NAME]"
";"
";==========================================================================="
"M117 [TOOLPATH_NAME] - Bit #[T]"

"M106 ; START SPINDLE"

+---------------------------------------------
+  Dwell (momentary pause)
+---------------------------------------------
begin DWELL_MOVE

"G4 [DWELL]"

+---------------------------------------------------------------------------
|  End of file output
+---------------------------------------------------------------------------
begin FOOTER

"G1 [SAFEZ] F500 ;goto safe z"
"M107"
"G4 S1"
"M117 Returning home"
"G0 [XH][YH]"
"M117 Routing complete."
