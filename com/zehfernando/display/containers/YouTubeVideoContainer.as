package com.zehfernando.display.containers {
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	import flash.system.Security;

	/**
	 * @author zeh
	 */
	public class YouTubeVideoContainer extends DynamicDisplayAssetContainer implements IVideoContainer {

		// Events
		// Common
		public static const EVENT_PLAY:String = "onVideoPlayed";
		public static const EVENT_PAUSE:String = "onVideoPaused";
		public static const EVENT_FINISH:String = "onVideoFinish";
		public static const EVENT_LOADING_START:String = "onStartedLoading";
		public static const EVENT_LOADING_PROGRESS:String = "onProgressLoading";
		public static const EVENT_LOADING_ERROR:String = "onProgressLoading";
		public static const EVENT_LOADING_COMPLETE:String = "onCompletedLoading";

		// Specific
		public static const EVENT_CUED:String = "onVideoCued";
		
		// Loads a video with Youtube's Chromeless AS3 video player
		// http://code.google.com/apis/youtube/flash_api_reference.html
		
		// Constants
		protected static var APIPLAYER_URL:String = "http://www.youtube.com/apiplayer?version=3";

		protected static var APIPLAYER_EVENT_READY:String = "onReady";
		protected static var APIPLAYER_EVENT_STATE_CHANGE:String = "onStateChange";
		protected static var APIPLAYER_EVENT_QUALITY_CHANGE:String = "onPlaybackQualityChange";
		protected static var APIPLAYER_EVENT_ERROR:String = "onError";
		
		protected static var APIPLAYER_MAX_TRIES:Number = 2; // Maximum number of times to try loading the swf
		
		// Quality - // http://code.google.com/apis/youtube/flash_api_reference.html#setPlaybackQuality
		public static const QUALITY_DEFAULT:String = "default";		// Youtube selects
		public static const QUALITY_SMALL:String = "small";			// < 640x360
		public static const QUALITY_MEDIUM:String = "medium";		// minimum player size 640x360
		public static const QUALITY_LARGE:String = "large";			// minimum player size 854x480
		public static const QUALITY_HD720:String = "hd720";			// minimum player size 1280x720

		// Properties
		protected var youtubePlayerInitialized:Boolean;
		protected var youtubePlayerReady:Boolean;
		
		protected var youtubePlayerLoadingTries:Number;
		
		protected var waitingToLoad:Boolean;
		
		protected var _isCued:Boolean;
		protected var _id:String;
		protected var _hasVideo:Boolean;
		
		protected var _autoPlay:Boolean;
		protected var _volume:Number;						// Volume for this video

		protected var firedVideoLoadEvent:Boolean;
		protected var checkingSize:Boolean;
		
		protected var _videoQuality:String;
		protected var _isPlaying:Boolean;
		
		// Instances
		protected var youtubePlayer:Loader;


		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function YouTubeVideoContainer(__width:Number = 100, __height:Number = 100, __color:Number = 0x000000) {
			super(__width, __height, __color);
		}

		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		override protected function setDefaultData(): void {
			super.setDefaultData();

			_autoPlay = true;
			_videoQuality = QUALITY_DEFAULT;
			_hasVideo = false;
			_volume = 1;
			checkingSize = false;
			youtubePlayerLoadingTries = 0;
		}

		protected function startCheckingSize(): void {
			if (!checkingSize) {
				addEventListener(Event.ENTER_FRAME, onEnterFrameCheckSize, false, 0, true);
				checkingSize = true;
			}
		}

		protected function stopCheckingSize(): void {
			if (checkingSize) {
				removeEventListener(Event.ENTER_FRAME, onEnterFrameCheckSize);
				checkingSize = false;
			}
		}

		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		override public function dispose(): void {
			
			if (youtubePlayerInitialized) {
				youtubePlayer.contentLoaderInfo.removeEventListener(Event.INIT, onPlayerInit);
				youtubePlayer.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onPlayerIOError);
				youtubePlayerInitialized = false;
				if (youtubePlayerReady) {
					youtubePlayerReady = false;
					youtubePlayer.content["stopVideo"]();
					youtubePlayer.content["destroy"]();
				}
				youtubePlayer.unload();
				youtubePlayer = null;
			}
			
			stopCheckingSize();
			
			firedVideoLoadEvent = false;
			
			_isCued = false;
			youtubePlayerLoadingTries = 0;
			
			super.dispose();
		}
		
		protected function loadContent(): void {
			waitingToLoad = false;
			_isLoading = false;
			_isLoaded = false;
			_isCued = false;
			_hasVideo = true;
			_isPlaying = false;
			
			firedVideoLoadEvent = false;
			
			if (_autoPlay) {
				_isLoading = true;
				_isPlaying = true;
				youtubePlayer.content["loadVideoById"](_contentURL, 0, _videoQuality);
				//youtubePlayer.content["seekTo"](0); // apparently this is necessary before pausing, otherwise it breaks the video
			} else {
				_isCued = true;
				youtubePlayer.content["cueVideoById"](_contentURL, 0, _videoQuality);
			}
			
			applyVolume();
		}

		protected function applyVolume(): void {
			if (youtubePlayerInitialized && _hasVideo) {
				youtubePlayer.content["setVolume"](Math.round(_volume * 100));
			}
		}
		
		protected function initializeYoutubePlayer(): void {
			
			// Load the chromeless video player

			//http://www.youtube.com/apiplayer?version=3
			
			if (!youtubePlayerInitialized) {
				
				youtubePlayerLoadingTries++;
				
				Security.allowDomain("s.ytimg.com");
				Security.allowDomain("www.youtube.com");
				Security.allowInsecureDomain("s.ytimg.com");
				Security.allowInsecureDomain("www.youtube.com");
				
				//Security.allowInsecureDomain("*"); // ugh
				//Security.allowDomain("*");

				youtubePlayer = new Loader();
				setAsset(youtubePlayer);
				
				youtubePlayer.contentLoaderInfo.addEventListener(Event.INIT, onPlayerInit);
				youtubePlayer.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onPlayerIOError);

//				var context:LoaderContext = new LoaderContext();
//				context.checkPolicyFile = true;
//				youtubePlayer.load(new URLRequest(APIPLAYER_URL), context);
				youtubePlayer.load(new URLRequest(APIPLAYER_URL));

				youtubePlayerInitialized = true;
				
				setAsset(youtubePlayer);
				
				dispatchEvent(new Event(EVENT_LOADING_START));
			}
		}
		
		protected function setSizeBasedOnQuality(): void {
//			youtubePlayer.content["setSize"](320, 240);
//			_contentWidth = 320;
//			_contentHeight = 240;

			switch (videoQuality) {
				case QUALITY_DEFAULT:
					_contentWidth = 320;
					_contentHeight = 240;
					break;
				case QUALITY_SMALL:
					_contentWidth = 320;
					_contentHeight = 240;
					break;
				case QUALITY_MEDIUM:
					_contentWidth = 640;
					_contentHeight = 480;//360;
					break;
				case QUALITY_LARGE:
					_contentWidth = 854;
					_contentHeight = 640;//480;
					break;
				case QUALITY_HD720:
					_contentWidth = 1280;
					_contentHeight = 960;//720;
					break;
			}
			
			youtubePlayer.content["setSize"](_contentWidth, _contentHeight);
		}

		/*
		public function loadThumb(__id:String): void {
			mustPlayVideoWhenLoading = false;
			super.load(__id);
		}
		*/


		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

		protected function onPlayerInit(e:Event): void {
			youtubePlayer.contentLoaderInfo.removeEventListener(Event.INIT, onPlayerInit);
			youtubePlayer.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onPlayerIOError);

			youtubePlayer.content.addEventListener(APIPLAYER_EVENT_READY, onPlayerReady);
		    youtubePlayer.content.addEventListener(APIPLAYER_EVENT_ERROR, onPlayerError);
		    youtubePlayer.content.addEventListener(APIPLAYER_EVENT_STATE_CHANGE, onPlayerStateChange);
		    youtubePlayer.content.addEventListener(APIPLAYER_EVENT_QUALITY_CHANGE, onVideoPlaybackQualityChange);
		}
		
		protected function onPlayerIOError(e:IOErrorEvent): void {
			trace ("YoutubeVideoContainer :: IOError!! :: -----------------------------------------------------------------------------");
			youtubePlayer.unload();
			youtubePlayerInitialized = false;
			
			youtubePlayer.contentLoaderInfo.removeEventListener(Event.INIT, onPlayerInit);
			youtubePlayer.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onPlayerIOError);
			
			if (youtubePlayerLoadingTries < APIPLAYER_MAX_TRIES) {
				// Try again
				initializeYoutubePlayer();
			} else {
				trace ("YoutubeVideoContainer :: IOError!! :: FATAL! No more retries!");
			}
		}

		protected function onPlayerReady(e:Event): void {
			//trace ("YoutubeVideoContainer :: onPlayerReady");
			setSizeBasedOnQuality();
			youtubePlayerReady = true;
			redraw();
		}
		
		protected function onPlayerStateChange(e:Event): void {
			//trace ("YoutubeVideoContainer :: onPlayerStateChange :: " + e["data"]);
			var stateType:int = parseInt(e["data"]);
			switch (stateType) {
				case -1:
					// Unstarted/ready
					if (waitingToLoad) loadContent();
					break;
				case 0:
					// Ended
					dispatchEvent(new Event(EVENT_FINISH));
					break;
				case 1:
					// Playing
					dispatchEvent(new Event(EVENT_PLAY));
					break;
				case 2:
					// Paused
					dispatchEvent(new Event(EVENT_PAUSE));
					break;
				case 3:
					// Buffering
					break;
				case 5:
					// Video cued and ready to play
					_isCued = true;
					dispatchEvent(new Event(EVENT_CUED));
					break;
				default:
					// Other
					trace ("YoutubeVideoContainer :: onPlayerStateChange :: Unknown state type [" + stateType + "]");
					break;
			}
		}

		protected function onVideoPlaybackQualityChange(e:Event): void {
			//trace ("YoutubeVideoContainer :: onVideoPlaybackQualityChange");
		}

		protected function onPlayerError(e:Event): void {
			trace ("YoutubeVideoContainer :: onPlayerError :: " + e);
			dispatchEvent(new Event(EVENT_LOADING_ERROR));
		}
		
		protected function onEnterFrameCheckSize(e:Event): void {
			_bytesTotal = youtubePlayerReady ? youtubePlayer.content["getVideoBytesTotal"]() : 0;
			_bytesLoaded = youtubePlayerReady ? youtubePlayer.content["getVideoBytesLoaded"]() : 0;
			
			dispatchEvent(new Event(EVENT_LOADING_PROGRESS));
			
			if (_bytesTotal > 0 && _bytesTotal == _bytesLoaded && !firedVideoLoadEvent) {
				_isLoaded = true;
				
				stopCheckingSize();

				firedVideoLoadEvent = true;
				dispatchEvent(new Event(EVENT_LOADING_COMPLETE));
			}
		}

		// ================================================================================================================
		// PUBLIC INTERFACE -----------------------------------------------------------------------------------------------

		public function playVideo(): void {
			//if (youtubePlayerInitialized) youtubePlayer.content["playVideo"]();
			_isPlaying = true;
			if (youtubePlayerReady && _hasVideo) youtubePlayer.content["playVideo"]();
		}

		public function seekTo(__val:Number): void {
			//if (youtubePlayerInitialized) youtubePlayer.content["seekTo"](__val);
			if (youtubePlayerReady && _hasVideo) youtubePlayer.content["seekTo"](__val);
		}


		public function pauseVideo(): void {
			//trace ("YoutubeVideoContainer :: pauseVideo :: " + _contentURL + ", initialized = " + youtubePlayerInitialized);
			//trace ("YoutubeVideoContainer :: pauseVideo :: initialized = " + youtubePlayerInitialized + ", youtubePlayer = " + youtubePlayer);
			// Ugh, this is returning an error for no reason at all.
			//		YoutubeVideoContainer :: pauseVideo :: initialized = true, youtubePlayer = [object Loader]
			//		Exception fault: TypeError: Error #1009: Cannot access a property or method of a null object reference.
			// So here goes an ugly try..catch.
			_isPlaying = false;
			try {
				//if (youtubePlayerInitialized) youtubePlayer.content["pauseVideo"]();
				if (youtubePlayerReady) youtubePlayer.content["pauseVideo"]();
			} catch (e:Error) {
				trace ("YoutubeVideoContainer :: error ["+e+"] was thrown.");
			}
		}

		override public function load(__id:String): void {
			super.load(__id);

			_id = __id;

			initializeYoutubePlayer();
			
			startCheckingSize();

			// Load content
			if (youtubePlayerReady) {
				loadContent();
			} else {
				waitingToLoad = true;
			}
		}

		override public function unload(): void {
			if (youtubePlayerInitialized) youtubePlayer.content["stopVideo"]();
			super.unload();
		}

		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		public function get autoPlay(): Boolean {
			return _autoPlay;
		}
		public function set autoPlay(__value:Boolean): void {
			_autoPlay = __value;
		}
		
		public function get videoQuality(): String {
			return _videoQuality;
		}
		public function set videoQuality(__value:String): void {
			if (_videoQuality != __value) {
				_videoQuality = __value;
				// TODO: start loading again when quality changes?
			}
		}

		public function get isCued(): Boolean {
			return _isCued;
		}

		public function get youtubeId(): String {
			return _contentURL;
		}
		
		public function get time(): Number {
			return youtubePlayerReady && _hasVideo ? youtubePlayer.content["getCurrentTime"]() : 0;
		}

		public function set time(__value:Number):void {
			if (youtubePlayerReady && _hasVideo) youtubePlayer.content["seekTo"](__value);
		}

		public function get duration(): Number {
			return youtubePlayerReady && _hasVideo ? youtubePlayer.content["getDuration"]() : 0;
		}
		
		public function get id():String {
			return _id;
		}
		
		public function stopVideo():void {
		}
		
		public function playPauseVideo():void {
		}
		
		public function get position(): Number {
			if (!_hasVideo) return 0;
			return time / duration;
		}
		public function set position(__value:Number): void {
			if (!_hasVideo) return;
			time = __value * duration;
		}

		public function get isPlaying():Boolean {
			return _isPlaying;
		}

		public function get volume():Number {
			return _volume;
		}
		public function set volume(__value:Number):void {
			_volume = __value;
			applyVolume();
		}

		// IMPLEMENT THESE!!!
		
		public function get framerate():Number {
			return 0;
		}

		public function get loop():Boolean {
			return false;
		}

		public function set loop(__value:Boolean):void {
		}
		
		
	}
}
