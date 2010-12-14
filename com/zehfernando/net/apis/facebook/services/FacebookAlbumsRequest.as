package com.zehfernando.net.apis.facebook.services {
	import com.adobe.serialization.json.JSON;
	import com.zehfernando.net.apis.BasicServiceRequest;
	import com.zehfernando.net.apis.facebook.FacebookConstants;
	import com.zehfernando.net.apis.facebook.data.FacebookAlbum;
	import com.zehfernando.net.apis.facebook.events.FacebookServiceEvent;

	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;

	/**
	 * @author zeh
	 */
	public class FacebookAlbumsRequest extends BasicServiceRequest {
		
		// http://developers.facebook.com/docs/reference/api/photo
		// http://developers.facebook.com/docs/reference/api/album
		// https://graph.facebook.com/rmstitanicinc/albums

		// Properties
		protected var _authorId:String;
		
		// Parameters
		protected var _limit:int;
		
		// Results
		protected var _albums:Vector.<FacebookAlbum>;
		
		// ================================================================================================================
		// CONSTRUCTOR ----------------------------------------------------------------------------------------------------

		public function FacebookAlbumsRequest() {
			super();

			// Basic service configuration
			requestURL = FacebookConstants.DOMAIN + FacebookConstants.SERVICE_ALBUMS;
			requestMethod = URLRequestMethod.GET;

			// Parameters
			// http://developers.facebook.com/docs/reference/api/page

			_authorId = "";
			
		}

		// ================================================================================================================
		// INTERNAL INTERFACE ---------------------------------------------------------------------------------------------

		override protected function getURLVariables():URLVariables {
			var vars:URLVariables = super.getURLVariables();

			if (_limit > 0)					vars["limit"] = _limit;

			return vars;
		}

		// ================================================================================================================
		// EVENT INTERFACE ------------------------------------------------------------------------------------------------

		override protected function onSecurityError(e:SecurityErrorEvent): void {
			super.onSecurityError(e);
			dispatchEvent(new FacebookServiceEvent(FacebookServiceEvent.ERROR));
		}
		
		override protected function onIOError(e:IOErrorEvent): void {
			super.onIOError(e);
			dispatchEvent(new FacebookServiceEvent(FacebookServiceEvent.ERROR));
		}

		override protected function onComplete(e:Event): void {
			var response:Object = JSON.decode(loader.data);
			
			_albums = FacebookAlbum.fromJSONObjectArray(response["data"]);
			
			super.onComplete(e);
			dispatchEvent(new FacebookServiceEvent(FacebookServiceEvent.COMPLETE));
		}

		
		override public function execute():void {
			requestURL = requestURL.replace(FacebookConstants.PARAMETER_AUTHOR_ID, _authorId);
			super.execute();
		}

		// ================================================================================================================
		// ACCESSOR INTERFACE ---------------------------------------------------------------------------------------------

		// Parameters

		public function get authorId():String {
			return _authorId;
		}
		public function set authorId(__value:String):void {
			_authorId = __value;
		}
		
		// Hard parameters
		
		public function get limit(): int {
			return _limit;
		}
		public function set limit(__value:int): void {
			if (_limit != __value) {
				_limit = __value;
			}
		}
		
		// Results
		
		public function get albums(): Vector.<FacebookAlbum> {
			return _albums.concat();
		}
	}
}