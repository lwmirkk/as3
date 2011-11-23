package com.zehfernando.utils.console {

	import com.zehfernando.utils.AppUtils;
	import com.zehfernando.utils.DebugUtils;

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.getTimer;
	/**
	 * @author zeh
	 */
	public class Console {

		// Constants
		public static const PARAM_PACKAGE_NAME:String = "[[package]]";
		public static const PARAM_CLASS_NAME:String = "[[class]]";
		public static const PARAM_FUNCTION_NAME:String = "[[function]]";
		public static const PARAM_OUTPUT:String = "[[output]]";
		public static const PARAM_CURRENT_FRAME:String = "[[current-frame]]";
		public static const PARAM_CURRENT_FRAME_FORMAT:String = "00000";
		public static const PARAM_TIME_NAME:String = "[[time-name]]";
		public static const PARAM_TIME_VALUE:String = "[[time-value]]";
		public static const PARAM_GROUP_NAME:String = "[[group]]";

		public static const LOG_STATE_OFF:String = "off";
		public static const LOG_STATE_ON:String = "on";

		public static const ECHO_FORMAT_FULL:String = "[" + PARAM_CURRENT_FRAME + "] " + PARAM_PACKAGE_NAME + "." + PARAM_CLASS_NAME + "." + PARAM_FUNCTION_NAME + "() :: " + PARAM_OUTPUT;
		public static const ECHO_FORMAT_SHORT:String = "[" + PARAM_CURRENT_FRAME + "] " + PARAM_CLASS_NAME + "." + PARAM_FUNCTION_NAME + "() :: " + PARAM_OUTPUT;

		public static const TIME_FORMAT:String = PARAM_TIME_NAME + ": " + PARAM_TIME_VALUE + "ms";

		public static const GROUP_START_FORMAT:String = PARAM_GROUP_NAME + " \\\\\\ -------";
		public static const GROUP_END_FORMAT:String = PARAM_GROUP_NAME + " //// -------";

		public static var prefixDebug:String = "[D] ";
		public static var prefixInfo:String = "[i] ";
		public static var prefixWarning:String = "/!\\ ";
		public static var prefixError:String = "(X) ";
		public static var prefixLog:String = "--- ";
		public static var groupPrefix:String = "  ";

		public static var echoFormat:String = ECHO_FORMAT_SHORT;
		public static var timeFormat:String = TIME_FORMAT;
		public static var groupStartFormat:String = GROUP_START_FORMAT;
		public static var groupEndFormat:String = GROUP_END_FORMAT;

		protected static const JS_FUNCTION_LOG:String = "console.log";
		protected static const JS_FUNCTION_DEBUG:String = "console.debug";
		protected static const JS_FUNCTION_INFO:String = "console.info";
		protected static const JS_FUNCTION_WARNING:String = "console.warn";
		protected static const JS_FUNCTION_ERROR:String = "console.error";

		// Internal enums
		protected static const LOG_TYPE_LOG:String = "log";
		protected static const LOG_TYPE_DEBUG:String = "debug";
		protected static const LOG_TYPE_INFO:String = "info";
		protected static const LOG_TYPE_WARNING:String = "warning";
		protected static const LOG_TYPE_ERROR:String = "error";

		// Static properties
		protected static var _useTrace:Boolean;
		protected static var _useScreen:Boolean;
		protected static var _useJS:Boolean;

		protected static var textField:TextField;

		protected static var logStates:Array;

		protected static var timeTable:Object;						// Named array of ints
		protected static var groups:Vector.<String>;

		protected static var currentFrame:int;
		protected static var frameCounter:Sprite;

		// http://getfirebug.com/logging

		// ================================================================================================================
		// STATIC CONSTRUCTOR ---------------------------------------------------------------------------------------------

		{
			_useTrace = true;
			_useScreen = false;
			_useJS = false;

			logStates = [];

			currentFrame = 0;

			timeTable = {};
			groups = new Vector.<String>();

			frameCounter = new Sprite();
			frameCounter.addEventListener(Event.ENTER_FRAME, onEnterFrameCounter);
		}


		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		protected static function createTextField(): void {
			textField = new TextField();
			textField.mouseEnabled = false;
			textField.embedFonts = false;
			textField.wordWrap = true;

			var fmt:TextFormat = new TextFormat("_sans", 10, 0x000000);
			textField.defaultTextFormat = fmt;
			textField.setTextFormat(fmt);

			AppUtils.getStage().addChild(textField);
			AppUtils.getStage().addEventListener(Event.RESIZE, onScreenResizeResizeTextField);

			onScreenResizeResizeTextField(null);
		}

		protected static function removeTextField(): void {
			textField = new TextField();

			AppUtils.getStage().removeChild(textField);
			AppUtils.getStage().removeEventListener(Event.RESIZE, onScreenResizeResizeTextField);

			textField = null;
		}

		protected static function echo(__output:String, __type:String = null, __callStackOffset:int = 0): void {
			// Raw writes something to the required outputs

			var className:String = getClassNameFromCallStack(DebugUtils.getCurrentCallStack()[3 + __callStackOffset]);

			if (logStates[className] == LOG_STATE_OFF) return;

			var currCall:Vector.<String> = DebugUtils.getCurrentCallStack()[3 + __callStackOffset]; // Package, class, function
			var currFrame:String = (PARAM_CURRENT_FRAME_FORMAT + currentFrame.toString(10)).substr(-PARAM_CURRENT_FRAME_FORMAT.length, PARAM_CURRENT_FRAME_FORMAT.length);

			var output:String = echoFormat;
			output = output.split(PARAM_CURRENT_FRAME).join(currFrame);
			output = output.split(PARAM_PACKAGE_NAME).join(currCall[0]);
			output = output.split(PARAM_CLASS_NAME).join(currCall[1]);
			output = output.split(PARAM_FUNCTION_NAME).join(currCall[2]);
			output = output.split(PARAM_OUTPUT).join(__output);

			output = getGroupsPrefix() + output;

			var jsFunction:String;

			// Adds group spacing

			switch (__type) {
				case LOG_TYPE_DEBUG:
					jsFunction = JS_FUNCTION_DEBUG;
					output = prefixDebug + output;
					break;
				case LOG_TYPE_INFO:
					jsFunction = JS_FUNCTION_INFO;
					output = prefixInfo + output;
					break;
				case LOG_TYPE_WARNING:
					jsFunction = JS_FUNCTION_WARNING;
					output = prefixWarning + output;
					break;
				case LOG_TYPE_ERROR:
					jsFunction = JS_FUNCTION_ERROR;
					output = prefixError + output;
					break;
				case LOG_TYPE_LOG:
				case null:
					jsFunction = JS_FUNCTION_LOG;
					output = prefixLog + output;
					break;
			}

			if (_useTrace) {
				trace (output);
			}

			if (_useScreen) {
				textField.text = textField.text + output + "\n"; // do not use append()
				textField.scrollV = textField.maxScrollV;
			}

			if (_useJS) {
				if (ExternalInterface.available) {
					try {
						ExternalInterface.call("function(__message) { if(typeof(console) != 'undefined' && console != null) { " + jsFunction + "(__message); } }", output);
					} catch (e:Error) {
						trace ("Console.echo error: Tried calling console.log(), but ExternalInterface is not available! Error: " + e);
					}
				} else {
					trace ("Console.echo error: Tried calling console.log(), but ExternalInterface is not available!");
				}
			}
		}

		protected static function getGroupsPrefix(): String {
			var str:String = "";
			var l:int = groups.length;
			while (l > 0) {
				str += groupPrefix;
				l--;
			}
			return str;
		}

		protected static function getClassNameFromCallStack(__callStack:Vector.<String>): String {
			//return __callStack[0] + "::" + __callStack[1] + "::" + __callStack[2];
			var packageName:String = __callStack[0];
			var className:String = __callStack[1];
			if (className.indexOf("$") > 0) className = className.split("$")[0];
			return  packageName + "::" + className;
		}

		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

		protected static function onEnterFrameCounter(e:Event): void {
			currentFrame++;
		}


		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		// console.debug, console.info [i], console.warn [!], console.error [!!!]

		public static function log(__args:Array): void {
			// Logs something
			echo(__args.join(" "), LOG_TYPE_LOG);
		}

		public static function info(__args:Array): void {
			// Logs something as an info
			echo(__args.join(" "), LOG_TYPE_INFO);
		}

		public static function debug(__args:Array): void {
			// Logs something as debug
			echo(__args.join(" "), LOG_TYPE_DEBUG);
		}

		public static function warn(__args:Array): void {
			// Logs something as warning
			echo(__args.join(" "), LOG_TYPE_WARNING);
		}

		public static function error(__args:Array): void {
			// Logs something as an error
			echo(__args.join(" "), LOG_TYPE_ERROR);
		}

		public static function time(__name:String): void {
			timeTable[__name] = getTimer();
		}

		public static function timeEnd(__name:String, __message:String = ""): void {
			if (timeTable.hasOwnProperty(__name)) {
				var timePassed:int = getTimer() - timeTable[__name];
				var output:String = timeFormat;
				output = output.split(PARAM_TIME_NAME).join(Boolean(__message) ? __message : __name);
				output = output.split(PARAM_TIME_VALUE).join(timePassed);
				echo(output);
				delete timeTable[__name];
			}
		}

		public static function group(__groupName:String = ""): void {
			var output:String = groupStartFormat;
			output = output.split(PARAM_GROUP_NAME).join(__groupName);

			echo(output);

			groups.push(__groupName);
		}

		public static function groupEnd(): void {
			if (groups.length > 0) {
				var groupName:String = groups.pop();

				var output:String = groupEndFormat;
				output = output.split(PARAM_GROUP_NAME).join(groupName);

				echo(output);
			}
		}

		public static function logOn(): void {
			// Turns off log for one class
			var className:String = getClassNameFromCallStack(DebugUtils.getCurrentCallStack()[2]);
			logStates[className] = LOG_STATE_ON;
			echo("Log is now set to ON", LOG_TYPE_INFO);
		}

		public static function logOff(): void {
			// Turns off log for one class
			var className:String = getClassNameFromCallStack(DebugUtils.getCurrentCallStack()[2]);
			echo("Log is now set to OFF", LOG_TYPE_INFO);
			logStates[className] = LOG_STATE_OFF;
		}

		public static function logStackTrace(): void {
			var stack:Vector.<Vector.<String>> = DebugUtils.getCurrentCallStack();
			echo("STACK TRACE :");
			for (var i:int = 1; i < stack.length; i++) {
				echo("   --> " + stack[i].join(" ###### "), LOG_TYPE_LOG);
			}
		}


		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

		protected static function onScreenResizeResizeTextField(e:Event): void {
			textField.x = AppUtils.getStage().stageWidth * 0.5;
			textField.width = AppUtils.getStage().stageWidth * 0.5;
			textField.height = AppUtils.getStage().stageHeight;
		}

		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public static function get useTrace(): Boolean {
			return _useTrace;
		}
		public static function set useTrace(__value:Boolean): void {
			_useTrace = __value;
		}

		public static function get useJS(): Boolean {
			return _useJS;
		}
		public static function set useJS(__value:Boolean): void {
			_useJS = __value;
		}

		public static function get useScreen(): Boolean {
			return _useScreen;
		}
		public static function set useScreen(__value:Boolean): void {
			if (_useScreen != __value) {
				_useScreen = __value;
				if (_useScreen) createTextField();
				if (!_useScreen) removeTextField();
			}
		}
	}
}

